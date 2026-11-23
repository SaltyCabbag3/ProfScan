local _, ns = ...

--[[
  Talking to the auction house

  Everything goes through one request at a time ("req"). A request is a job
  table: { kind = "batch" | "commodity", owner = "scan" | "watch", ... ,
  onResult = function(job, data), onFail = function(job) }. The driver below
  sends it when the auction house throttle allows, resends it if the server
  drops it, fails, or does not answer in time, and gives up after MAX_TRIES.
  When no request is pending it asks the running scan for its next job, and
  when there is no scan, watch mode (Watch.lua).

  Two lists can be scanned: the full scan list (ns.items) and the focused scan
  list you fill yourself (ns.focusItems). Either can be scanned quick, deep or smart.

  Quick scan: C_AuctionHouse.SearchForItemKeys takes a whole list of items and
  answers with one row per item (lowest price + total quantity listed). One
  request covers ~50 items.

  Deep scan: after the quick scan, one SendSearchQuery per commodity, reading
  the cheapest listings to build a price ladder ("price:quantity" levels).
  Almost all of a deep scan's time is these one-per-item requests (the server
  paces them); reading fewer listings per item would save nothing.

  Smart scan: a quick scan, then a deep search only for the commodities whose
  price levels are worth reading again (ns:SmartDeepReason):
    - none known yet, or the known ones are older than settings.smartMaxAge
      (5 hours: price levels over 6 hours older than the latest price are not
      used for costs, see Pricing.lua);
    - since the scan that read the known levels, the quick scan's lowest price
      moved more than settings.smartPriceChange (5%) and by at least
      settings.smartPriceFloor (50 copper), or the quantity listed doubled or
      halved (settings.smartQtyChange 1) and changed by over settings.smartQtyFloor (50).
      Measured on 1-2 hour old Horde scans: quantities move a lot (median 15%,
      a quarter over 35%) and cheap items jump by single coppers, so smaller
      limits re-read most items; these read about a quarter of them;
    - on a goblin auction house, only items cheaper there than on the faction one.
  Deep searches go in order of how many recipes use the item, so a scan stopped
  early has the most used reagents done.

  Disenchant scan: browses the auction house for uncommon, rare and epic
  weapons and armor (one SendBrowseQuery per quality, all pages), keeping the
  lowest price, quantity and item level of each item in ns.db.deScan, then
  deep-scans the enchanting materials. No item list needed, so it also finds
  gear the game files don't describe.
]]

local REQUEST_TIMEOUT = 10 -- seconds to wait for an answer before resending
local MAX_TRIES = 3        -- sends per request before giving up on it
local KEY_INFO_WAIT = 5    -- seconds to wait for uncached item info before searching anyway
local MAX_OWNERS = 3       -- seller names kept per price level

local PRICE_SORT = {
  { sortOrder = Enum.AuctionHouseSortOrder and Enum.AuctionHouseSortOrder.Price or 0, reverseSort = false },
}

local req         -- the request being sent or waited on
local scan        -- state of the running scan, nil when idle
ns.ahOpen = false

local driver = CreateFrame("Frame")
driver:Hide()

local function Key(id)
  return C_AuctionHouse.MakeItemKey(id)
end

-- Item key info is the auction house's own item cache. Searches for items that
-- are not in it yet are often ignored, so we ask early and wait for it.
local function KeyInfo(id)
  return C_AuctionHouse.GetItemKeyInfo(Key(id))
end
ns.KeyInfo = KeyInfo

local function JobReady(job)
  if job.kind == "browse" then return true end
  if job.kind == "commodity" then return KeyInfo(job.id) ~= nil end
  for _, id in ipairs(job.ids) do
    if not KeyInfo(id) then return false end
  end
  return true
end

local GEAR_CLASSES = { { classID = 2 }, { classID = 4 } } -- weapons, armor

local function SendJob(job)
  if job.kind == "browse" then
    C_AuctionHouse.SendBrowseQuery({ searchString = "", sorts = PRICE_SORT, minLevel = 0, maxLevel = 0,
                                     filters = { job.filter }, itemClassFilters = GEAR_CLASSES })
  elseif job.kind == "batch" then
    local keys = {}
    for i, id in ipairs(job.ids) do keys[i] = Key(id) end
    C_AuctionHouse.SearchForItemKeys(keys, PRICE_SORT)
  else
    C_AuctionHouse.SendSearchQuery(Key(job.id), PRICE_SORT, false)
  end
end

-- Forgets the pending request if it belongs to `owner`, e.g. when a scan is stopped.
function ns:DropRequest(owner)
  if req and req.owner == owner then req = nil end
end

--[[
  Reads the loaded commodity listings (cheapest first) into an order book:
    book.levels  = { { price =, qty =, tl = seconds left (lowest at that price), owners = {...} }, ... }
    book.byPrice = [price] = level
    book.min     = lowest price listed (0 if none)
    book.total   = total quantity listed, including listings not loaded
    book.cap     = 0 if the whole book is here; otherwise only prices below
                   cap are complete, and nothing at or above it is included
]]
function ns.ReadBook(itemID, maxLevels)
  local levels, byPrice, cap, first = {}, {}, nil, nil
  for i = 1, C_AuctionHouse.GetNumCommoditySearchResults(itemID) or 0 do
    local row = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, i)
    if row then
      first = first or row.unitPrice
      local level = byPrice[row.unitPrice]
      if not level then
        if #levels >= maxLevels then
          cap = row.unitPrice
          break
        end
        level = { price = row.unitPrice, qty = 0, owners = {} }
        levels[#levels + 1], byPrice[row.unitPrice] = level, level
      end
      level.qty = level.qty + row.quantity
      local tl = row.timeLeftSeconds
      if tl and (not level.tl or tl < level.tl) then level.tl = tl end
      for _, owner in ipairs(row.owners or {}) do
        owner = owner:gsub("[,:/+]", "")
        if #level.owners < MAX_OWNERS and not tContains(level.owners, owner) then
          level.owners[#level.owners + 1] = owner
        end
      end
    end
  end
  if not cap and #levels > 0 and not C_AuctionHouse.HasFullCommoditySearchResults(itemID) then
    -- the last price level may continue in rows that were not sent; leave it out
    local last = table.remove(levels)
    byPrice[last.price] = nil
    cap = last.price
  end
  return {
    levels = levels, byPrice = byPrice, cap = cap or 0, min = first or 0,
    total = C_AuctionHouse.GetCommoditySearchResultsQuantity(itemID) or 0,
  }
end

-- Scanning ---------------------------------------------------------------------

local function BatchResult(job, results)
  for _, r in ipairs(results) do
    local id = r.itemKey.itemID
    local cur = scan.results[id] or { min = 0, qty = 0 }
    local price = r.minPrice or 0
    if price > 0 and (cur.min == 0 or price < cur.min) then cur.min = price end
    cur.qty = cur.qty + (r.totalQuantity or 0)
    scan.results[id] = cur
  end
  for id in pairs(job.set) do scan.covered[id] = true end
end

local function DeepResult(job, book)
  local parts = {}
  for i = 1, math.min(#book.levels, ns.db.settings.ladderDepth) do
    local level = book.levels[i]
    parts[i] = level.price .. ":" .. level.qty
  end
  scan.results[job.id] = { min = book.min, qty = book.total, ladder = table.concat(parts, "/") }
end

-- Disenchant scan: one quality's weapons and armor.
local function BrowseResult(job, results)
  for _, r in ipairs(results) do
    local key = r.itemKey
    local id = key and key.itemID
    if id and (r.minPrice or 0) > 0 then
      local cur = scan.gear[id]
      if not cur then
        cur = { m = r.minPrice, n = 0, q = job.quality }
        scan.gear[id] = cur
      elseif r.minPrice < cur.m then
        cur.m = r.minPrice
      end
      cur.n = cur.n + (r.totalQuantity or 0)
      if (key.itemLevel or 0) > 0 then cur.l = key.itemLevel end
    end
  end
  scan.browsed = scan.browsed + 1
end

local function ScanFail()
  scan.failed = scan.failed + 1
end

-- Why a smart scan reads an item's price levels again ("new" | "old" | "changed" | "cheaper"),
-- or nil and why not ("unlisted" | "notCheaper" | "unchanged"). quick = this scan's
-- { min =, qty = } for the item on auction house `key`.
function ns:SmartDeepReason(key, id, quick)
  if not quick or quick.qty <= 0 or quick.min <= 0 then return nil, "unlisted" end
  local s = self.db.settings
  local goblin = self.AHFaction(key) == "Neutral"
  if goblin then
    local main = self:LatestAHPrice(id, self:MainAHKey())
    if main and quick.min >= main then return nil, "notCheaper" end
  end
  local stored = self.ladders[key] and self.ladders[key][id]
  if not stored then return goblin and "cheaper" or "new" end
  if time() - stored.t > (s.smartMaxAge or 5 * 3600) then return "old" end
  -- this quick result against the scan that read those levels
  local raw, past = self.index[key] and self.index[key][id], nil
  for i = #(raw or {}), 1, -1 do
    if raw[i].t == stored.t then past = raw[i] break end
    if raw[i].t < stored.t then break end
  end
  if not past or past.min <= 0 then return "changed" end
  local dp = math.abs(quick.min - past.min)
  if dp > past.min * (s.smartPriceChange or 0.05) and dp >= (s.smartPriceFloor or 50) then return "changed" end
  -- quantity: grew or shrank by the factor 1 + smartQtyChange (2 = doubled or halved)
  local dq, factor = math.abs(quick.qty - past.qty), 1 + (s.smartQtyChange or 1)
  local ratio = quick.qty / math.max(past.qty, 1)
  if dq > (s.smartQtyFloor or 50) and (ratio >= factor or ratio <= 1 / factor) then return "changed" end
  return nil, "unchanged"
end

-- deep: true = also read price levels, "smart" = only where they may have changed (see
-- above). focused: true = the focused scan list instead of the full one; "disenchant" =
-- the Disenchant scan (gear by browsing, then the enchanting materials).
function ns:StartScan(deep, focused)
  local disenchant = focused == "disenchant"
  if disenchant then deep = true end
  if not self.ahOpen then return self.Print("Open the auction house first.") end
  if scan then return self.Print("A scan is already running. /pscan stop cancels it.") end
  if not (C_AuctionHouse and C_AuctionHouse.SearchForItemKeys) then
    return self.Print("This client has no C_AuctionHouse.SearchForItemKeys, so scanning is unavailable.")
  end

  local items = {}
  for i, id in ipairs(disenchant and self.DE_MATERIALS or focused and self.focusItems or self.items) do items[i] = id end
  if #items == 0 then
    return self.Print(focused and "The focused scan list is empty. Add items from a recipe, an item or the "
      .. "Professions tab (\"Focus recipes\"), or with /pscan fadd <item>." or "The scan list is empty.")
  end
  for _, id in ipairs(items) do KeyInfo(id) end -- start loading anything not cached yet

  local jobs, size = {}, self.db.settings.batchSize
  if disenchant then
    local F = Enum and Enum.AuctionHouseFilter
    if not (F and F.UncommonQuality and C_AuctionHouse.SendBrowseQuery) then
      return self.Print("This client can't browse the auction house by quality, so the Disenchant scan is unavailable.")
    end
    for quality, filter in pairs({ [2] = F.UncommonQuality, [3] = F.RareQuality, [4] = F.EpicQuality }) do
      jobs[#jobs + 1] = { kind = "browse", owner = "scan", quality = quality, filter = filter,
                          onResult = BrowseResult, onFail = ScanFail }
    end
  end
  for i = 1, #items, size do
    local ids, set = {}, {}
    for j = i, math.min(i + size - 1, #items) do
      ids[#ids + 1] = items[j]
      set[items[j]] = true
    end
    jobs[#jobs + 1] = { kind = "batch", owner = "scan", ids = ids, set = set, onResult = BatchResult, onFail = ScanFail }
  end
  if deep then
    -- most used reagents first, so a scan stopped early has them
    local order, uses = {}, {}
    for i, id in ipairs(items) do
      order[i] = id
      uses[id] = #(self.recipesUsing[id] or {})
    end
    table.sort(order, function(a, b)
      if uses[a] ~= uses[b] then return uses[a] > uses[b] end
      return a < b
    end)
    for _, id in ipairs(order) do
      jobs[#jobs + 1] = {
        kind = "commodity", owner = "scan", id = id, levels = self.db.settings.ladderDepth,
        onResult = DeepResult, onFail = ScanFail,
      }
    end
  end

  scan = {
    jobs = jobs, pos = 0, key = self.openKey or self.ahKey, stamp = time(), started = GetTime(), deep = deep,
    items = items, focused = focused, gear = {}, browsed = 0,
    results = {}, -- [itemID] = { min =, qty =, ladder = }
    covered = {}, -- [itemID] = true once a batch containing it came back
    failed = 0,
    smart = deep == "smart" and { deep = 0 } or nil, -- smart scan: how many of each reason / skip
  }
  self.Print(("%s: %d items..."):format(self:ScanName(deep, focused), #items))
  self:NotifyChanged()
end

function ns:StopScan(reason)
  if scan then self:FinishScan(reason) end
end

function ns:IsScanning()
  return scan ~= nil
end

function ns:ScanName(deep, focused)
  if focused == "disenchant" then return "Disenchant scan" end
  return (focused and "Focused scan" or "Full scan")
    .. (deep == "smart" and " (smart)" or deep and " (deep)" or " (quick)")
end

function ns:ScanStatus()
  if scan then return ("%s... %d/%d"):format(self:ScanName(scan.deep, scan.focused), scan.pos, #scan.jobs) end
end

local function NextScanJob()
  local s = scan
  while true do
    s.pos = s.pos + 1
    local job = s.jobs[s.pos]
    if not job then
      ns:FinishScan()
      return nil
    end
    if job.kind == "batch" or job.kind == "browse" then return job end
    -- Deep job: only commodities (stackable goods) have a single price ladder,
    -- and there is nothing to read for items the quick scan found unlisted.
    local info, quick = KeyInfo(job.id), s.results[job.id]
    if info and info.isCommodity and not (s.covered[job.id] and not (quick and quick.qty > 0)) then
      if not s.smart then return job end
      local reason, skip = ns:SmartDeepReason(s.key, job.id, quick)
      local count = reason or skip
      s.smart[count] = (s.smart[count] or 0) + 1
      if reason then
        s.smart.deep = s.smart.deep + 1
        return job
      end
    end
  end
end

function ns:FinishScan(reason)
  local s = scan
  scan = nil
  self:DropRequest("scan")
  local saved = 0
  for _, id in ipairs(s.items) do
    local r = s.results[id]
    if r or s.covered[id] then
      r = r or { min = 0, qty = 0 } -- searched but nothing listed
      self:ItemName(id)
      self:AddRecord(s.key, s.stamp, id, r.min, r.qty, r.ladder or "")
      saved = saved + 1
    end
  end
  if s.focused == "disenchant" and s.browsed > 0 then
    local n = 0
    for _ in pairs(s.gear) do n = n + 1 end
    self.db.deScan[s.key] = { t = s.stamp, items = s.gear, partial = s.browsed < 3 or nil }
    self.Print(("Disenchant scan: %d pieces of gear listed."):format(n))
  end
  self.Print(("%s %s: %d items saved in %.1fs%s."):format(
    self:ScanName(s.deep, s.focused), reason or "done", saved, GetTime() - s.started,
    s.failed > 0 and (", " .. s.failed .. " requests failed") or ""))
  if s.smart then
    local m = s.smart
    local parts = {}
    for _, k in ipairs({ { "new", "new" }, { "old", "old" }, { "changed", "changed" }, { "cheaper", "cheaper on goblin" },
                         { "unchanged", "unchanged" }, { "notCheaper", "not cheaper on goblin" } }) do
      if m[k[1]] then parts[#parts + 1] = ("%d %s"):format(m[k[1]], k[2]) end
    end
    self.Print(("Smart scan: %d price ladders read again (%s)."):format(m.deep,
      #parts > 0 and table.concat(parts, ", ") or "nothing to compare"))
  end
  self:NotifyChanged()
end

-- Driver -------------------------------------------------------------------------

driver:SetScript("OnUpdate", function()
  if not req then
    local job = (scan and NextScanJob()) or ns:NextWatchJob()
    if not job then return end
    job.tries, job.queuedAt, job.state = 0, GetTime(), "send"
    req = job
  end
  local now = GetTime()
  if req.state == "send" then
    if not C_AuctionHouse.IsThrottledMessageSystemReady() then return end
    if not JobReady(req) and now - req.queuedAt < KEY_INFO_WAIT then return end
    req.tries = req.tries + 1
    if req.tries > MAX_TRIES then
      local job = req
      req = nil
      if job.onFail then job:onFail() end
      return
    end
    SendJob(req)
    req.state, req.sentAt = "wait", now
  elseif now - req.sentAt > REQUEST_TIMEOUT then
    req.state = "send" -- no answer, send it again
  end
end)

local function Waiting(kind)
  return req and req.state == "wait" and req.kind == kind
end

local function Resend()
  if req and req.state == "wait" then req.state = "send" end
end

-- Results --------------------------------------------------------------------------

local GetItemInfoInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant

-- Whether a browse result row can be the answer to our request.
local function OurRow(job, r)
  local id = r.itemKey and r.itemKey.itemID
  if not id then return false end
  if job.kind == "batch" then return job.set[id] == true end
  local classID = select(6, GetItemInfoInstant(id))
  return classID == nil or classID == 2 or classID == 4 -- nil: unknown to this client, can't tell
end

function ns:AUCTION_HOUSE_BROWSE_RESULTS_UPDATED()
  if not (Waiting("batch") or Waiting("browse")) then return end
  local results = C_AuctionHouse.GetBrowseResults()
  for _, r in ipairs(results) do
    -- Rows for items we did not ask for mean this answer belongs to another
    -- search (the default UI's favorites list, a manual search). Keep waiting;
    -- the timeout resends ours if needed.
    if not OurRow(req, r) then return end
  end
  if not C_AuctionHouse.HasFullBrowseResults() then
    C_AuctionHouse.RequestMoreBrowseResults()
    req.sentAt = GetTime()
    return
  end
  local job = req
  req = nil
  job:onResult(results)
end
ns.AUCTION_HOUSE_BROWSE_RESULTS_ADDED = ns.AUCTION_HOUSE_BROWSE_RESULTS_UPDATED

function ns:COMMODITY_SEARCH_RESULTS_UPDATED(itemID)
  if not (Waiting("commodity") and req.id == itemID) then return end
  -- The server sometimes answers with an empty list for items that do have
  -- listings; treat that as a failed request and search again.
  if (C_AuctionHouse.GetNumCommoditySearchResults(itemID) or 0) == 0
      and (C_AuctionHouse.GetCommoditySearchResultsQuantity(itemID) or 0) > 0 then
    return Resend()
  end
  local job = req
  req = nil
  job:onResult(ns.ReadBook(itemID, job.levels))
end

-- Failures and auction house open/close ---------------------------------------

ns.AUCTION_HOUSE_BROWSE_FAILURE = Resend
ns.AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED = Resend

function ns:AUCTION_HOUSE_SHOW()
  self.ahOpen = true
  local faction = self:OpenAHFaction()
  if self.AHFaction(self.lastOpenKey) ~= faction then
    self.Print(("%s auction house: scans are stored as its prices. Wrong? /pscan ah alliance|horde|goblin"):format(
      self.AH_NAMES[faction]))
  end
  self.openKey = self:AHKey(faction)
  self.lastOpenKey = self.openKey
  self:UpdateAHView()
  for _, id in ipairs(self.items) do KeyInfo(id) end
  for _, id in ipairs(self.focusItems) do KeyInfo(id) end
  for _, id in ipairs(self.db.settings.focus) do KeyInfo(id) end
  driver:Show()
  self:ResumeWatchForAH()
  if self.OnAuctionHouseShow then self:OnAuctionHouseShow() end
  if self.db.settings.autoScan then
    -- give the default UI a moment to run its own opening search first
    C_Timer.After(3, function() if ns.ahOpen then ns:StartScan(false) end end)
  end
  self:NotifyChanged()
end

function ns:AUCTION_HOUSE_CLOSED()
  if not self.ahOpen then return end
  self.ahOpen = false
  self:StopScan("stopped (auction house closed)")
  self:PauseWatchForAH()
  req = nil
  driver:Hide()
  self.openKey = nil
  self:UpdateAHView()
  self:NotifyChanged()
end

for _, event in ipairs({
  "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED",
  "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED",
  "AUCTION_HOUSE_BROWSE_FAILURE", "AUCTION_HOUSE_THROTTLED_MESSAGE_DROPPED",
  "COMMODITY_SEARCH_RESULTS_UPDATED",
}) do
  ns:RegisterEvent(event)
end
