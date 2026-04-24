-- Static spec metadata: role classification and M+ utility abilities
-- specID reference: https://wowpedia.fandom.com/wiki/SpecializationID

KRC_SpecUtility = {
    -- Death Knight
    [250] = { role = "tank",   class = "Death Knight",   spec = "Blood",          util = {"Anti-Magic Zone", "Death Grip", "Battle Res"} },
    [251] = { role = "melee",  class = "Death Knight",   spec = "Frost",          util = {"Anti-Magic Zone", "Death Grip", "Battle Res", "Blinding Sleet"} },
    [252] = { role = "melee",  class = "Death Knight",   spec = "Unholy",         util = {"Anti-Magic Zone", "Death Grip", "Battle Res", "Blinding Sleet"} },

    -- Demon Hunter
    [577] = { role = "melee",  class = "Demon Hunter",   spec = "Havoc",          util = {"Darkness (Group DR)", "Imprison", "Purge", "Chaos Brand (+5% Magic)"} },
    [581] = { role = "tank",   class = "Demon Hunter",   spec = "Vengeance",      util = {"Darkness (Group DR)", "Imprison", "Purge", "Chaos Brand (+5% Magic)"} },

    -- Druid
    [102] = { role = "ranged", class = "Druid",          spec = "Balance",        util = {"Battle Res", "Innervate", "Soothe", "Typhoon", "Decurse", "Stampeding Roar"} },
    [103] = { role = "melee",  class = "Druid",          spec = "Feral",          util = {"Battle Res", "Innervate", "Soothe", "Incapacitating Roar", "Decurse", "Stampeding Roar"} },
    [104] = { role = "tank",   class = "Druid",          spec = "Guardian",       util = {"Battle Res", "Innervate", "Soothe", "Incapacitating Roar", "Decurse", "Stampeding Roar"} },
    [105] = { role = "healer", class = "Druid",          spec = "Restoration",    util = {"Battle Res", "Innervate", "Soothe", "Typhoon", "Decurse", "Stampeding Roar"} },

    -- Evoker
    [1467] = { role = "ranged", class = "Evoker",        spec = "Devastation",    util = {"Rescue", "Blessing of the Bronze (CDR)", "Zephyr (AoE DR)", "Decurse"} },
    [1468] = { role = "healer", class = "Evoker",        spec = "Preservation",   util = {"Rescue", "Blessing of the Bronze (CDR)", "Zephyr (AoE DR)", "Decurse"} },
    [1473] = { role = "ranged", class = "Evoker",        spec = "Augmentation",   util = {"Rescue", "Blessing of the Bronze (CDR)", "Zephyr (AoE DR)", "Decurse", "Group Damage Buff"} },

    -- Hunter
    [253] = { role = "ranged", class = "Hunter",         spec = "Beast Mastery",  util = {"Primal Rage (Lust)", "Binding Shot", "Misdirection", "Tranq Shot"} },
    [254] = { role = "ranged", class = "Hunter",         spec = "Marksmanship",   util = {"Primal Rage (Lust)", "Binding Shot", "Misdirection", "Tranq Shot"} },
    [255] = { role = "melee",  class = "Hunter",         spec = "Survival",       util = {"Primal Rage (Lust)", "Binding Shot", "Misdirection", "Tranq Shot"} },

    -- Mage
    [62]  = { role = "ranged", class = "Mage",           spec = "Arcane",         util = {"Time Warp (Lust)", "Arcane Intellect (+5% Int)", "Spellsteal", "Polymorph", "Decurse"} },
    [63]  = { role = "ranged", class = "Mage",           spec = "Fire",           util = {"Time Warp (Lust)", "Arcane Intellect (+5% Int)", "Spellsteal", "Polymorph", "Decurse"} },
    [64]  = { role = "ranged", class = "Mage",           spec = "Frost",          util = {"Time Warp (Lust)", "Arcane Intellect (+5% Int)", "Spellsteal", "Polymorph", "Decurse"} },

    -- Monk
    [268] = { role = "tank",   class = "Monk",           spec = "Brewmaster",     util = {"Mystic Touch (+5% Phys)", "Ring of Peace", "Paralysis", "Tiger's Lust"} },
    [269] = { role = "melee",  class = "Monk",           spec = "Windwalker",     util = {"Mystic Touch (+5% Phys)", "Ring of Peace", "Paralysis", "Tiger's Lust"} },
    [270] = { role = "healer", class = "Monk",           spec = "Mistweaver",     util = {"Mystic Touch (+5% Phys)", "Ring of Peace", "Paralysis", "Tiger's Lust"} },

    -- Paladin
    [65]  = { role = "healer", class = "Paladin",        spec = "Holy",           util = {"Blessing of Freedom", "Lay on Hands", "Devotion Aura", "Cleanse", "Turn Evil"} },
    [66]  = { role = "tank",   class = "Paladin",        spec = "Protection",     util = {"Blessing of Freedom", "Lay on Hands", "Devotion Aura", "Cleanse", "Turn Evil"} },
    [70]  = { role = "melee",  class = "Paladin",        spec = "Retribution",    util = {"Blessing of Freedom", "Lay on Hands", "Devotion Aura", "Cleanse", "Turn Evil"} },

    -- Priest
    [256] = { role = "healer", class = "Priest",         spec = "Discipline",     util = {"Power Infusion", "Mass Dispel", "Mind Control", "Psychic Scream", "Purge (Dispel Magic)"} },
    [257] = { role = "healer", class = "Priest",         spec = "Holy",           util = {"Power Infusion", "Mass Dispel", "Mind Control", "Psychic Scream", "Purge (Dispel Magic)"} },
    [258] = { role = "ranged", class = "Priest",         spec = "Shadow",         util = {"Power Infusion", "Mass Dispel", "Mind Control", "Psychic Scream", "Purge (Dispel Magic)"} },

    -- Rogue
    [259] = { role = "melee",  class = "Rogue",          spec = "Assassination",  util = {"Shroud of Concealment", "Blind", "Kidney Shot", "Sap", "Numbing Poison"} },
    [260] = { role = "melee",  class = "Rogue",          spec = "Outlaw",         util = {"Shroud of Concealment", "Blind", "Kidney Shot", "Sap", "Numbing Poison"} },
    [261] = { role = "melee",  class = "Rogue",          spec = "Subtlety",       util = {"Shroud of Concealment", "Blind", "Kidney Shot", "Sap", "Numbing Poison"} },

    -- Shaman
    [262] = { role = "ranged", class = "Shaman",         spec = "Elemental",      util = {"Heroism (Lust)", "Wind Shear (Ranged Kick)", "Purge", "Hex", "Tremor Totem", "Poison Cleanse"} },
    [263] = { role = "melee",  class = "Shaman",         spec = "Enhancement",    util = {"Heroism (Lust)", "Wind Shear (Ranged Kick)", "Purge", "Hex", "Tremor Totem", "Poison Cleanse"} },
    [264] = { role = "healer", class = "Shaman",         spec = "Restoration",    util = {"Heroism (Lust)", "Wind Shear (Ranged Kick)", "Purge", "Hex", "Tremor Totem", "Poison Cleanse"} },

    -- Warlock
    [265] = { role = "ranged", class = "Warlock",        spec = "Affliction",     util = {"Healthstone", "Gateway", "Battle Res (Soulstone)", "Banish", "Curse Dispel"} },
    [266] = { role = "ranged", class = "Warlock",        spec = "Demonology",     util = {"Healthstone", "Gateway", "Battle Res (Soulstone)", "Banish", "Curse Dispel"} },
    [267] = { role = "ranged", class = "Warlock",        spec = "Destruction",    util = {"Healthstone", "Gateway", "Battle Res (Soulstone)", "Banish", "Curse Dispel"} },

    -- Warrior
    [71]  = { role = "melee",  class = "Warrior",        spec = "Arms",           util = {"Battle Shout (+5% AP)", "Rallying Cry (Group HP)", "Intimidating Shout", "Spell Reflect"} },
    [72]  = { role = "melee",  class = "Warrior",        spec = "Fury",           util = {"Battle Shout (+5% AP)", "Rallying Cry (Group HP)", "Intimidating Shout", "Spell Reflect"} },
    [73]  = { role = "tank",   class = "Warrior",        spec = "Protection",     util = {"Battle Shout (+5% AP)", "Rallying Cry (Group HP)", "Intimidating Shout", "Spell Reflect"} },
}

-- Role display names for tooltip text
KRC_RoleLabels = {
    melee  = "Melee DPS",
    ranged = "Ranged DPS",
    healer = "Healer",
    tank   = "Tank",
}
