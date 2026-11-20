-- WoW Forever trade companies: Waylaid Crates and Craftsman's Writs.
-- From community guides of the beta/launch builds (foreverchanges.pro, endgametools.com,
-- November 2026); item IDs checked against item names. Values may change with patches.
-- Artisan crates: their fills are from one beta guide and their Merchant's Favor is not
-- known yet. Crates and sealed writs are tradeable and can be bought on the auction house.
local _, ns = ...
ns.TRADE = {
  companies = {
    Alliance = { name = "Azeroth Commerce Authority", hub = "Three Corners, Redridge Mountains (10.2, 72.3)",
                 crates = "Marcy Baker (9.5, 71)" },
    Horde = { name = "Durotar Supply and Logistics", hub = "west of the Crossroads, the Barrens (49.7, 29.5)",
              crates = "Dokimi (50, 29.2)" },
  },
  writRep = { J = 75, E = 125, A = 200 }, -- reputation per writ tier, once per day per writ
  -- tradeable envelopes holding a random writ of that tier (item IDs checked on Wowhead)
  sealedWrits = { J = 262888, E = 262889, A = 262890 },
  -- { crate item ID or 0, name, level, Merchant's Favor or false, { { itemID, quantity }, ... } fill options }
  crates = {
    { 248682, "Apprentice Herbs", 10, 5, { { 2447, 20 }, { 765, 20 }, { 2449, 10 }, { 785, 10 }, { 2450, 10 } } },
    { 248683, "Apprentice Ore", 10, 5, { { 2770, 20 }, { 2771, 20 } } },
    { 248684, "Apprentice Textiles", 10, 5, { { 2589, 40 }, { 2318, 20 } } },
    { 248685, "Apprentice Curiosities", 10, 5, { { 10940, 20 }, { 10939, 4 }, { 10978, 6 }, { 11084, 2 } } },
    { 248686, "Journeyman Herbs", 10, 10, { { 3820, 10 }, { 2453, 10 }, { 3355, 10 }, { 3369, 10 }, { 3356, 10 } } },
    { 248687, "Journeyman Ore", 10, 10, { { 2775, 10 }, { 2772, 20 } } },
    { 248688, "Journeyman Textiles", 10, 10, { { 2592, 20 }, { 4306, 40 }, { 2319, 20 } } },
    { 248689, "Journeyman Curiosities", 10, 10, { { 11083, 20 }, { 11082, 4 }, { 11138, 6 }, { 11139, 2 } } },
    { 248690, "Earthly Expert Herbs", 20, 15, { { 3357, 20 }, { 3818, 10 }, { 3821, 10 }, { 3358, 10 } } },
    { 248691, "Flowering Expert Herbs", 20, 15, { { 3819, 10 }, { 4625, 10 }, { 8831, 20 }, { 8836, 10 } } },
    { 248692, "Expert Ore", 20, 15, { { 2776, 10 }, { 3858, 20 } } },
    { 248693, "Expert Textiles", 20, 15, { { 4338, 40 }, { 4234, 20 } } },
    { 248694, "Expert Curiosities", 20, 15, { { 11137, 20 }, { 11135, 4 }, { 11177, 6 }, { 11178, 2 } } },
    { 248702, "Apprentice Fabrics", 10, 10, { { 4231, 2 }, { 2996, 20 } } },
    { 248703, "Apprentice Ingots", 10, 10, { { 2840, 20 }, { 3576, 20 }, { 2841, 10 } } },
    { 248704, "Apprentice Parts", 10, 10, { { 4359, 16 }, { 4361, 16 }, { 4363, 4 } } },
    { 248705, "Journeyman Fabrics", 10, 20, { { 2997, 6 }, { 4305, 10 }, { 4233, 2 } } },
    { 248706, "Journeyman Ingots", 10, 20, { { 2842, 10 }, { 3575, 20 } } },
    { 248707, "Journeyman Parts", 10, 20, { { 4371, 8 }, { 4375, 7 }, { 4382, 4 }, { 10558, 45 } } },
    { 248708, "Expert Fabrics", 20, 30, { { 4339, 8 }, { 4236, 2 } } },
    { 248709, "Expert Ingots", 20, 30, { { 3860, 20 }, { 3859, 15 }, { 3577, 10 } } },
    { 248710, "Expert Parts", 20, 30, { { 4387, 8 }, { 10559, 5 }, { 10560, 12 }, { 10561, 5 } } },
    { 248695, "Earthly Artisan Herbs", 35, false, { { 13464, 10 }, { 8838, 20 }, { 8839, 10 }, { 8845, 10 }, { 8846, 10 } } },
    { 248696, "Flowering Artisan Herbs", 35, false, { { 13463, 20 }, { 13465, 20 }, { 13466, 20 }, { 13467, 20 } } },
    { 248697, "Artisan Ore", 35, false, { { 7911, 10 }, { 10620, 20 }, { 11370, 20 } } },
    { 248698, "Artisan Textiles", 35, false, { { 14047, 40 }, { 4304, 20 }, { 8170, 20 } } },
    { 248699, "Artisan Curiosities", 35, false, { { 11176, 20 }, { 11175, 4 }, { 14343, 6 }, { 14344, 2 } } },
    { 248711, "Artisan Fabrics", 35, false, { { 14048, 8 }, { 8172, 2 } } },
    { 248712, "Artisan Ingots", 35, false, { { 11371, 2 }, { 6037, 10 }, { 12359, 20 } } },
    { 248713, "Artisan Parts", 35, false, { { 15994, 5 }, { 18631, 5 }, { 16000, 2 } } },
  },
  -- Where each writ is handed in, from Wowhead's writ guide (guide=35185, 15 Nov 2026), with
  -- customers it lacks filled in from conquestcapped.com (same date). Where the two disagree
  -- (Mana Potion, Goblin Rocket Fuel) Wowhead's is used. Coordinates only where a guide gave them.
  -- Writ item IDs checked against the game's item names. Unknown customers fill in as guides do.
  -- Continent of each turn-in zone, for grouping trips.
  zoneContinent = {
    ["Alterac Mountains"] = "EK", ["Arathi Highlands"] = "EK", ["Badlands"] = "EK", ["Blasted Lands"] = "EK",
    ["Burning Steppes"] = "EK", ["Deadwind Pass"] = "EK", ["Duskwood"] = "EK", ["Eastern Plaguelands"] = "EK",
    ["Hillsbrad Foothills"] = "EK", ["Riverglades"] = "EK", ["Searing Gorge"] = "EK", ["Stranglethorn Vale"] = "EK",
    ["Swamp of Sorrows"] = "EK", ["The Hinterlands"] = "EK", ["Western Plaguelands"] = "EK", ["Wetlands"] = "EK",
    ["Ashenvale"] = "K", ["Azshara"] = "K", ["Desolace"] = "K", ["Dustwallow Marsh"] = "K", ["Felwood"] = "K",
    ["Feralas"] = "K", ["Moonglade"] = "K", ["Silithus"] = "K", ["Stonetalon Mountains"] = "K", ["Tanaris"] = "K",
    ["Thousand Needles"] = "K", ["Un'Goro Crater"] = "K", ["Winterspring"] = "K",
  },
  -- { profession, tier J/E/A, itemID, required skill, quantity, turn-in zone ("" = not known),
  --   customer ("" = not known), writ item ID, true = from one guide's summary only (unconfirmed) }
  writs = {
    { "Alchemy", "J", 3383, 120, 1, "Arathi Highlands", "Muggol Breezebeard (48.8, 55.8)", 264012 }, -- Elixir of Wisdom
    { "Alchemy", "J", 5996, 120, 1, "Wetlands", "Kixxle (50.2, 37.8)", 264019 }, -- Draught of Water Breathing
    { "Alchemy", "J", 3385, 145, 1, "Ashenvale", "Ash'alari (60.2, 72.6)", 264013 }, -- Lesser Mana Potion
    { "Alchemy", "J", 3388, 150, 1, "Stranglethorn Vale", "Short John Mithril (29.6, 47.4)", 264017 }, -- Lesser Troll's Blood Elixir
    { "Alchemy", "J", 6048, 160, 1, "Duskwood", "Kzixx (81.8, 19.8)", 264014 }, -- Shadow Protection Potion
    { "Alchemy", "J", 3390, 165, 1, "Stonetalon Mountains", "Ziz Fizziks (59.0, 62.4)", 264016 }, -- Elixir of Lesser Agility
    { "Alchemy", "J", 3391, 175, 1, "Alterac Mountains", "Sos'mol (38.4, 61.2)", 264011 }, -- Elixir of Ogre Strength
    { "Alchemy", "J", 5634, 175, 1, "Hillsbrad Foothills", "Webbed Mudsnout Gnoll (62.2, 69.2)", 264015 }, -- Free Action Potion
    { "Alchemy", "J", 8951, 215, 1, "Thousand Needles", "Rizzle Brassbolts", 264018 }, -- Elixir of Defense
    { "Alchemy", "E", 3827, 180, 1, "Ashenvale", "Ash'alari (60.2, 72.6)", 264062 }, -- Mana Potion
    { "Alchemy", "E", 3823, 185, 1, "Desolace", "Centaur Pariah", 264057 }, -- Lesser Invisibility Potion
    { "Alchemy", "E", 3824, 190, 1, "Swamp of Sorrows", "Mukomonji", 264064 }, -- Shadow Oil
    { "Alchemy", "E", 5633, 195, 1, "Moonglade", "Dendrite Starblaze", 264061 }, -- Great Rage Potion
    { "Alchemy", "E", 6050, 205, 1, "Badlands", "Lotwil Veriatus", 264056 }, -- Frost Protection Potion
    { "Alchemy", "E", 8949, 205, 1, "The Hinterlands", "Juo", 264066 }, -- Elixir of Agility
    { "Alchemy", "E", 6052, 210, 1, "Felwood", "Greta Mosshoof", 264059 }, -- Nature Protection Potion
    { "Alchemy", "E", 6049, 210, 1, "Searing Gorge", "Durganon", 264063 }, -- Fire Protection Potion
    { "Alchemy", "E", 10592, 220, 1, "Feralas", "Scout Raroul", 264060 }, -- Catseye Draught
    { "Alchemy", "E", 9061, 225, 1, "Azshara", "Duke Hydraxis", 264065 }, -- Goblin Rocket Fuel
    { "Alchemy", "E", 9144, 225, 1, "Un'Goro Crater", "Spark Nilminer", 264067 }, -- Wildvine Potion
    { "Alchemy", "E", 4623, 230, 1, "Dustwallow Marsh", "Mudcrush Durtfeet", 264058 }, -- Lesser Stoneshield Potion
    { "Alchemy", "A", 12190, 245, 1, "Blasted Lands", "Kum'isha the Collector", 264117 }, -- Dreamless Sleep Potion
    { "Alchemy", "A", 9088, 255, 1, "Eastern Plaguelands", "Adon", 264120 }, -- Gift of Arthas
    { "Alchemy", "A", 246948, 260, 1, "Winterspring", "Bor'dorc", 264124 }, -- Distilled Firewater
    { "Alchemy", "A", 9224, 265, 1, "Azshara", "Archmage Xylem", 264116, true }, -- Potion of Demon Slaying
    { "Alchemy", "A", 9233, 265, 1, "Deadwind Pass", "Hastings", 264119 }, -- Draught of Detect Demon
    { "Alchemy", "A", 3387, 275, 1, "", "", 264122 }, -- Limited Invulnerability Potion
    { "Alchemy", "A", 13457, 305, 1, "", "", 264118 }, -- Greater Fire Protection Potion
    { "Alchemy", "A", 18253, 310, 1, "", "", 264123 }, -- Major Rejuvenation Potion
    { "Alchemy", "A", 13513, 315, 1, "", "", 264121 }, -- Flask of Chromatic Resistance
    { "Blacksmithing", "J", 15869, 75, 1, "Duskwood", "Battered Trunk", 264023 }, -- Silver Skeleton Key
    { "Blacksmithing", "J", 3848, 110, 1, "Thousand Needles", "\"Plucky\" Johnson (79.6, 75.6)", 264027 }, -- Big Bronze Knife
    { "Blacksmithing", "J", 5540, 115, 1, "Alterac Mountains", "Alan Sneeks (30.6, 61.0)", 264020 }, -- Pearl-handled Dagger
    { "Blacksmithing", "J", 2865, 120, 1, "Stonetalon Mountains", "Ziz Fizziks (59.0, 62.4)", 264025 }, -- Rough Bronze Leggings
    { "Blacksmithing", "J", 11128, 130, 1, "Arathi Highlands", "Muggol Breezebeard (48.8, 55.8)", 264021 }, -- Golden Rod
    { "Blacksmithing", "J", 3491, 135, 1, "Hillsbrad Foothills", "Gorgrash (80.0, 48.2)", 264024 }, -- Heavy Bronze Mace
    { "Blacksmithing", "J", 5541, 145, 1, "Ashenvale", "Cowardly Peon (78.4, 68.8)", 264022 }, -- Iridescent Hammer
    { "Blacksmithing", "J", 3484, 150, 1, "Wetlands", "Kixxle (50.2, 37.8)", 264028 }, -- Green Iron Boots
    { "Blacksmithing", "J", 3485, 155, 1, "Stranglethorn Vale", "\"Sea Wolf\" MacKinley", 264026 }, -- Green Iron Gauntlets
    { "Blacksmithing", "E", 7964, 175, 1, "Searing Gorge", "Master Smith Burninate", 264075 }, -- Solid Sharpening Stone
    { "Blacksmithing", "E", 3853, 180, 1, "Moonglade", "Meliri", 264073 }, -- Moonsteel Broadsword
    { "Blacksmithing", "E", 11144, 180, 1, "Tanaris", "Spigot Operator Luglunket", 264077 }, -- Truesilver Rod
    { "Blacksmithing", "E", 6041, 190, 1, "Dustwallow Marsh", "Ugbert", 264070 }, -- Steel Weapon Chain
    { "Blacksmithing", "E", 3837, 190, 1, "Riverglades", "Spek", 264074 }, -- Golden Scale Coif
    { "Blacksmithing", "E", 9060, 200, 1, "Desolace", "Bibbly F'utzbuckle", 264069 }, -- Inlaid Mithril Cylinder
    { "Blacksmithing", "E", 9366, 200, 1, "", "", 264078 }, -- Golden Scale Gauntlets
    { "Blacksmithing", "E", 7922, 210, 1, "Badlands", "Furious Shadowforge Digger", 264068 }, -- Steel Plate Helm
    { "Blacksmithing", "E", 7941, 210, 1, "Un'Goro Crater", "Torwa Pathfinder", 264079 }, -- Heavy Mithril Axe
    { "Blacksmithing", "E", 7928, 220, 1, "Felwood", "Taronn Redfeather", 264071 }, -- Ornate Mithril Shoulders
    { "Blacksmithing", "E", 7942, 220, 1, "Feralas", "Scout Raroul", 264072 }, -- Blue Glittering Axe
    { "Blacksmithing", "E", 7943, 225, 1, "", "", 264076 }, -- Wicked Mithril Blade
    { "Blacksmithing", "A", 7929, 225, 1, "", "", 264127 }, -- Orcish War Leggings
    { "Blacksmithing", "A", 7969, 230, 1, "Deadwind Pass", "", 264128 }, -- Mithril Spurs
    { "Blacksmithing", "A", 15872, 250, 1, "", "", 264132 }, -- Arcanite Skeleton Key
    { "Blacksmithing", "A", 12416, 255, 1, "Blasted Lands", "Kum'isha the Collector", 264126 }, -- Radiant Belt
    { "Blacksmithing", "A", 7947, 255, 1, "", "", 264133 }, -- Ebon Shiv
    { "Blacksmithing", "A", 12775, 280, 1, "", "", 264131 }, -- Huge Thorium Battleaxe
    { "Blacksmithing", "A", 12417, 290, 1, "", "", 264125 }, -- Radiant Circlet
    { "Blacksmithing", "A", 12422, 295, 1, "", "", 264129 }, -- Imperial Plate Chest
    { "Blacksmithing", "A", 20549, 320, 1, "", "", 264130 }, -- Darkrune Gauntlets
    { "Engineering", "J", 6712, 115, 1, "Hillsbrad Foothills", "Gorgrash (80.0, 48.2)", 264033 }, -- Practice Lock
    { "Engineering", "J", 8069, 125, 200, "Wetlands", "Kixxle (50.2, 37.8)", 264037 }, -- Crafted Solid Shot
    { "Engineering", "J", 4380, 140, 1, "Thousand Needles", "Razzeric", 264036 }, -- Big Bronze Bomb
    { "Engineering", "J", 4373, 145, 1, "Stonetalon Mountains", "Ziz Fizziks (59.0, 62.4)", 264034 }, -- Shadow Goggles
    { "Engineering", "J", 7506, 150, 1, "Stranglethorn Vale", "Scooty (27.6, 77.4)", 264035 }, -- Gnomish Universal Remote
    { "Engineering", "J", 5507, 160, 1, "Alterac Mountains", "Alan Sneeks (30.6, 61.0)", 264029 }, -- Ornate Spyglass
    { "Engineering", "J", 4381, 165, 1, "Duskwood", "Kzixx (81.8, 19.8)", 264032 }, -- Minor Recombobulator
    { "Engineering", "J", 4383, 170, 1, "Ashenvale", "Grembly", 264031 }, -- Moonsight Rifle
    { "Engineering", "J", 4384, 175, 1, "Arathi Highlands", "Alyce (34.0, 23.2)", 264030 }, -- Explosive Sheep
    { "Engineering", "E", 10498, 175, 1, "Tanaris", "Jhordy Lapforge", 264089 }, -- Gyromatic Micro-Adjustor
    { "Engineering", "E", 4392, 185, 1, "Desolace", "Bibbly F'utzbuckle", 264081 }, -- Advanced Target Dummy
    { "Engineering", "E", 4852, 185, 1, "Riverglades", "Spek", 264086 }, -- Flash Bomb
    { "Engineering", "E", 10560, 200, 1, "Moonglade", "Narianna", 264085 }, -- Unstable Trigger
    { "Engineering", "E", 11590, 200, 1, "The Hinterlands", "Rhapsody Shindigger", 264090 }, -- Mechanical Repair Kit
    { "Engineering", "E", 4393, 205, 1, "Dustwallow Marsh", "The Ravenous", 264082 }, -- Craftsman's Monocle
    { "Engineering", "E", 4395, 215, 1, "Felwood", "Jessir Moonbow", 264083 }, -- Goblin Land Mine
    { "Engineering", "E", 10514, 215, 1, "Swamp of Sorrows", "Bullets Bigblast", 264088 }, -- Mithril Frag Bomb
    { "Engineering", "E", 4396, 220, 1, "Badlands", "", 264080, true }, -- Mechanical Dragonling
    { "Engineering", "E", 10500, 225, 1, "Searing Gorge", "Durganon", 264087 }, -- Fire Goggles
    { "Engineering", "E", 10501, 240, 1, "Feralas", "Scout Raroul", 264084 }, -- Catseye Ultra Goggles
    { "Engineering", "E", 16005, 305, 1, "", "", 264091 }, -- Dark Iron Bomb
    { "Engineering", "A", 10548, 260, 1, "", "", 264141 }, -- Sniper Scope
    { "Engineering", "A", 10504, 265, 1, "", "", 264135 }, -- Green Lens
    { "Engineering", "A", 18631, 270, 1, "Silithus", "Khur Hornstriker", 264140, true }, -- Truesilver Transformer
    { "Engineering", "A", 18645, 275, 1, "", "", 264137 }, -- Gnomish Alarm-O-Bot
    { "Engineering", "A", 15996, 285, 1, "", "", 264136 }, -- Lifelike Mechanical Toad
    { "Engineering", "A", 18587, 285, 1, "", "", 264138 }, -- Goblin Jumper Cables XL
    { "Engineering", "A", 16023, 295, 1, "", "", 264134 }, -- Masterwork Target Dummy
    { "Engineering", "A", 18232, 320, 1, "", "", 264139 }, -- Field Repair Bot 74A
    { "Engineering", "A", 21277, 320, 1, "", "", 264142 }, -- Tranquil Mechanical Yeti
    { "Leatherworking", "J", 2317, 100, 1, "Duskwood", "Kzixx (81.8, 19.8)", 264041 }, -- Dark Leather Tunic
    { "Leatherworking", "J", 5958, 105, 1, "Arathi Highlands", "Alyce (34.0, 23.2)", 264039 }, -- Fine Leather Pants
    { "Leatherworking", "J", 7284, 120, 1, "Wetlands", "Kixxle (50.2, 37.8)", 264046 }, -- Red Whelp Gloves
    { "Leatherworking", "J", 18662, 125, 1, "Alterac Mountains", "Sos'mol (38.4, 61.2)", 264038 }, -- Heavy Leather Ball
    { "Leatherworking", "J", 7349, 135, 1, "Ashenvale", "Murache", 264040 }, -- Herbalist's Gloves
    { "Leatherworking", "J", 7358, 140, 1, "Hillsbrad Foothills", "Kris Legace", 264042 }, -- Pilferer's Gloves
    { "Leatherworking", "J", 4252, 140, 1, "Stranglethorn Vale", "Narkk", 264044 }, -- Dark Leather Shoulders
    { "Leatherworking", "J", 7371, 145, 1, "Stonetalon Mountains", "Ziz Fizziks (59.0, 62.4)", 264043 }, -- Heavy Quiver
    { "Leatherworking", "J", 4254, 150, 1, "Thousand Needles", "Goblin Pit Boss", 264045 }, -- Barbaric Gloves
    { "Leatherworking", "E", 5965, 180, 1, "Desolace", "Azore Aldamort", 264093 }, -- Guardian Cloak
    { "Leatherworking", "E", 7378, 180, 1, "Dustwallow Marsh", "The Ravenous", 264094 }, -- Dusky Bracers
    { "Leatherworking", "E", 8174, 195, 1, "Badlands", "Garek", 264092 }, -- Comfortable Leather Hat
    { "Leatherworking", "E", 7391, 195, 1, "Riverglades", "Spek", 264098 }, -- Swift Boots
    { "Leatherworking", "E", 8192, 205, 1, "Searing Gorge", "Evonice Sootsmoker", 264099 }, -- Nightscape Shoulders
    { "Leatherworking", "E", 8189, 205, 1, "The Hinterlands", "Juo", 264102 }, -- Turtle Scale Breastplate
    { "Leatherworking", "E", 8200, 210, 1, "Tanaris", "Yeh'kinya", 264101 }, -- Big Voodoo Robe
    { "Leatherworking", "E", 8210, 215, 1, "Feralas", "", 264096 }, -- Wild Leather Shoulders
    { "Leatherworking", "E", 8201, 215, 1, "Swamp of Sorrows", "Mukomonji", 264100 }, -- Big Voodoo Mask
    { "Leatherworking", "E", 8214, 220, 1, "Felwood", "Ivy Leafrunner", 264095 }, -- Wild Leather Helmet
    { "Leatherworking", "E", 8217, 220, 1, "Moonglade", "Narianna", 264097 }, -- Quickdraw Quiver
    { "Leatherworking", "E", 8218, 220, 1, "Un'Goro Crater", "Nergal", 264103 }, -- Thick Leather Ammo Pouch
    { "Leatherworking", "A", 15084, 260, 1, "", "", 264147 }, -- Wicked Leather Bracers
    { "Leatherworking", "A", 15092, 270, 1, "Western Plaguelands", "Fallen Adventurer", 264150, true }, -- Runic Leather Bracers
    { "Leatherworking", "A", 15071, 270, 1, "", "", 264151 }, -- Frostsaber Boots
    { "Leatherworking", "A", 15053, 280, 1, "", "", 264145 }, -- Volcanic Breastplate
    { "Leatherworking", "A", 15087, 285, 1, "", "", 264143 }, -- Wicked Leather Pants
    { "Leatherworking", "A", 18258, 285, 1, "", "", 264144 }, -- Gordok Ogre Suit
    { "Leatherworking", "A", 15094, 285, 1, "Deadwind Pass", "Hastings", 264146 }, -- Runic Leather Headband
    { "Leatherworking", "A", 15075, 285, 1, "", "", 264148 }, -- Chimeric Vest
    { "Leatherworking", "A", 15080, 290, 1, "", "", 264149 }, -- Heavy Scorpid Helm
    { "Tailoring", "J", 4313, 80, 1, "Stonetalon Mountains", "Ziz Fizziks (59.0, 62.4)", 264052 }, -- Red Woolen Boots
    { "Tailoring", "J", 10048, 95, 1, "Stranglethorn Vale", "Hekshi", 264053 }, -- Colorful Kilt
    { "Tailoring", "J", 6263, 100, 1, "Arathi Highlands", "Alyce (34.0, 23.2)", 264048 }, -- Blue Overalls
    { "Tailoring", "J", 6264, 115, 1, "Thousand Needles", "Magus Tirth", 264054 }, -- Greater Adept's Robe
    { "Tailoring", "J", 4317, 125, 1, "Alterac Mountains", "Bath'rah the Windwatcher", 264051 }, -- Phoenix Pants
    { "Tailoring", "J", 5766, 130, 1, "Alterac Mountains", "Alan Sneeks (30.6, 61.0)", 264047 }, -- Lesser Wizard's Robe
    { "Tailoring", "J", 7048, 130, 1, "Ashenvale", "Cowardly Peon (78.4, 68.8)", 264049 }, -- Azure Silk Hood
    { "Tailoring", "J", 4321, 135, 1, "Wetlands", "Kixxle (50.2, 37.8)", 264055 }, -- Spider Silk Slippers
    { "Tailoring", "J", 4245, 145, 1, "Duskwood", "Kzixx (81.8, 19.8)", 264050 }, -- Small Silk Pack
    { "Tailoring", "E", 7061, 180, 1, "Un'Goro Crater", "Petra Grossen", 264115 }, -- Earthen Silk Belt
    { "Tailoring", "E", 7063, 185, 1, "Dustwallow Marsh", "Tabetha", 264106 }, -- Crimson Silk Robe
    { "Tailoring", "E", 4329, 185, 1, "Moonglade", "Mylentha Riverbend", 264109 }, -- Star Belt
    { "Tailoring", "E", 9998, 185, 1, "Riverglades", "Spek", 264110 }, -- Black Mageweave Vest
    { "Tailoring", "E", 10008, 185, 1, "Tanaris", "Vizzklick", 264113 }, -- White Bandit Mask
    { "Tailoring", "E", 10052, 190, 1, "Swamp of Sorrows", "Bullets Bigblast", 264112 }, -- Orange Martial Shirt
    { "Tailoring", "E", 10004, 195, 1, "Felwood", "Eridan Bluewind", 264107 }, -- Shadoweave Robe
    { "Tailoring", "E", 10009, 195, 1, "Searing Gorge", "Lookout Captain Lolo Longstriker", 264111 }, -- Red Mageweave Pants
    { "Tailoring", "E", 10050, 205, 1, "Badlands", "Rigglefuzz", 264104 }, -- Mageweave Bag
    { "Tailoring", "E", 10023, 205, 1, "Desolace", "Willow", 264105 }, -- Shadoweave Gloves
    { "Tailoring", "E", 22246, 205, 1, "Felwood", "", 264108 }, -- Enchanted Mageweave Pouch
    { "Tailoring", "E", 10042, 205, 1, "The Hinterlands", "Atal'ai Exile", 264114 }, -- Cindercloth Robe
    { "Tailoring", "A", 10036, 155, 1, "Deadwind Pass", "Hastings", 264155 }, -- Tuxedo Jacket
    { "Tailoring", "A", 10025, 215, 1, "Silithus", "Hermit Ortell", 264158, true }, -- Shadoweave Mask
    { "Tailoring", "A", 14046, 230, 1, "Blasted Lands", "Kum'isha the Collector", 264153 }, -- Runecloth Bag
    { "Tailoring", "A", 21340, 230, 1, "Winterspring", "", 264160 }, -- Soul Pouch
    { "Tailoring", "A", 14141, 240, 1, "", "", 264159 }, -- Ghostweave Vest
    { "Tailoring", "A", 22251, 245, 1, "", "", 264157 }, -- Cenarion Herb Bag
    { "Tailoring", "A", 13864, 250, 1, "Burning Steppes", "Gorzeeki Wildeyes", 264154, true }, -- Runecloth Boots
    { "Tailoring", "A", 14108, 255, 1, "", "", 264156 }, -- Felcloth Boots
    { "Tailoring", "A", 14130, 275, 1, "", "", 264152 }, -- Wizardweave Turban
  },
}
