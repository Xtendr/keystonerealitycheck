-- SpecDatabase.lua — Static spec metadata for the Keystone Synergy Check engine
-- All 39 specs with scanner-friendly flat records for O(1) lookup

KSC_RAID_BUFFS = {
    int     = "Arcane Intellect (+5% Int)",
    ap      = "Battle Shout (+5% AP)",
    phys    = "Mystic Touch (+5% Phys Taken)",
    magic   = "Chaos Brand (+5% Magic Taken)",
    stam    = "Fortitude (+5% Stamina)",
    vers    = "Mark of the Wild (+3% Vers)",
    dr      = "Devotion Aura (+3% DR)",
    bronze  = "Blessing of the Bronze",
    skyfury = "Skyfury",
}

KSC_SpecDB = {

    -- ═══════════════════════════════════════════════════════════════════════
    -- DEATH KNIGHT (Plate) — Brez, Anti-Magic Zone
    -- ═══════════════════════════════════════════════════════════════════════
    [250] = {
        class = "Death Knight", spec = "Blood", role = "tank", armor = "Plate",
        lust = false, brez = true, shroud = false,
        raidBuff = nil,
        kickCD = 15, kickRange = "melee",
        dmgProfile = nil,
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = "Anti-Magic Zone",
    },
    [251] = {
        class = "Death Knight", spec = "Frost", role = "melee", armor = "Plate",
        lust = false, brez = true, shroud = false,
        raidBuff = nil,
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Cleave",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = "Anti-Magic Zone",
    },
    [252] = {
        class = "Death Knight", spec = "Unholy", role = "melee", armor = "Plate",
        lust = false, brez = true, shroud = false,
        raidBuff = nil,
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Sustained AoE",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = "Anti-Magic Zone",
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- DEMON HUNTER (Leather) — Chaos Brand, Darkness, Purge
    -- ═══════════════════════════════════════════════════════════════════════
    [577] = {
        class = "Demon Hunter", spec = "Havoc", role = "melee", armor = "Leather",
        lust = false, brez = false, shroud = false,
        raidBuff = "magic",
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Burst AoE",
        soothe = false, purge = true, massDispel = false,
        aoeStops = 1,
        groupDR = "Darkness",
    },
    [581] = {
        class = "Demon Hunter", spec = "Vengeance", role = "tank", armor = "Leather",
        lust = false, brez = false, shroud = false,
        raidBuff = "magic",
        kickCD = 15, kickRange = "melee",
        dmgProfile = nil,
        soothe = false, purge = true, massDispel = false,
        aoeStops = 2,
        groupDR = "Darkness",
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- DRUID (Leather) — Brez, Mark of the Wild, Soothe
    -- ═══════════════════════════════════════════════════════════════════════
    [102] = {
        class = "Druid", spec = "Balance", role = "ranged", armor = "Leather",
        lust = false, brez = true, shroud = false,
        raidBuff = "vers",
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Sustained AoE",
        soothe = true, purge = false, massDispel = false,
        aoeStops = 2,
        groupDR = nil,
    },
    [103] = {
        class = "Druid", spec = "Feral", role = "melee", armor = "Leather",
        lust = false, brez = true, shroud = false,
        raidBuff = "vers",
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Priority ST",
        soothe = true, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },
    [104] = {
        class = "Druid", spec = "Guardian", role = "tank", armor = "Leather",
        lust = false, brez = true, shroud = false,
        raidBuff = "vers",
        kickCD = 15, kickRange = "melee",
        dmgProfile = nil,
        soothe = true, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },
    [105] = {
        class = "Druid", spec = "Restoration", role = "healer", armor = "Leather",
        lust = false, brez = true, shroud = false,
        raidBuff = "vers",
        kickCD = 15, kickRange = "melee",
        dmgProfile = nil,
        soothe = true, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- EVOKER (Mail) — Lust, Blessing of the Bronze
    -- ═══════════════════════════════════════════════════════════════════════
    [1467] = {
        class = "Evoker", spec = "Devastation", role = "ranged", armor = "Mail",
        lust = true, brez = false, shroud = false,
        raidBuff = "bronze",
        kickCD = 25, kickRange = "ranged",
        dmgProfile = "Burst AoE",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = "Zephyr",
    },
    [1468] = {
        class = "Evoker", spec = "Preservation", role = "healer", armor = "Mail",
        lust = true, brez = false, shroud = false,
        raidBuff = "bronze",
        kickCD = 25, kickRange = "ranged",
        dmgProfile = nil,
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = "Zephyr",
    },
    [1473] = {
        class = "Evoker", spec = "Augmentation", role = "ranged", armor = "Mail",
        lust = true, brez = false, shroud = false,
        raidBuff = "bronze",
        kickCD = 25, kickRange = "ranged",
        dmgProfile = "Support",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = "Zephyr",
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- HUNTER (Mail) — Lust, Soothe, Purge
    -- ═══════════════════════════════════════════════════════════════════════
    [253] = {
        class = "Hunter", spec = "Beast Mastery", role = "ranged", armor = "Mail",
        lust = true, brez = false, shroud = false,
        raidBuff = nil,
        kickCD = 24, kickRange = "ranged",
        dmgProfile = "Sustained AoE",
        soothe = true, purge = true, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },
    [254] = {
        class = "Hunter", spec = "Marksmanship", role = "ranged", armor = "Mail",
        lust = true, brez = false, shroud = false,
        raidBuff = nil,
        kickCD = 24, kickRange = "ranged",
        dmgProfile = "Priority ST",
        soothe = true, purge = true, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },
    [255] = {
        class = "Hunter", spec = "Survival", role = "melee", armor = "Mail",
        lust = true, brez = false, shroud = false,
        raidBuff = nil,
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Funnel",
        soothe = true, purge = true, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- MAGE (Cloth) — Lust, Arcane Intellect, Spellsteal
    -- ═══════════════════════════════════════════════════════════════════════
    [62] = {
        class = "Mage", spec = "Arcane", role = "ranged", armor = "Cloth",
        lust = true, brez = false, shroud = false,
        raidBuff = "int",
        kickCD = 24, kickRange = "ranged",
        dmgProfile = "Priority ST",
        soothe = false, purge = true, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },
    [63] = {
        class = "Mage", spec = "Fire", role = "ranged", armor = "Cloth",
        lust = true, brez = false, shroud = false,
        raidBuff = "int",
        kickCD = 24, kickRange = "ranged",
        dmgProfile = "Burst AoE",
        soothe = false, purge = true, massDispel = false,
        aoeStops = 2,
        groupDR = nil,
    },
    [64] = {
        class = "Mage", spec = "Frost", role = "ranged", armor = "Cloth",
        lust = true, brez = false, shroud = false,
        raidBuff = "int",
        kickCD = 24, kickRange = "ranged",
        dmgProfile = "Priority ST",
        soothe = false, purge = true, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- MONK (Leather) — Mystic Touch
    -- ═══════════════════════════════════════════════════════════════════════
    [268] = {
        class = "Monk", spec = "Brewmaster", role = "tank", armor = "Leather",
        lust = false, brez = false, shroud = false,
        raidBuff = "phys",
        kickCD = 15, kickRange = "melee",
        dmgProfile = nil,
        soothe = false, purge = false, massDispel = false,
        aoeStops = 2,
        groupDR = nil,
    },
    [269] = {
        class = "Monk", spec = "Windwalker", role = "melee", armor = "Leather",
        lust = false, brez = false, shroud = false,
        raidBuff = "phys",
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Burst AoE",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 2,
        groupDR = nil,
    },
    [270] = {
        class = "Monk", spec = "Mistweaver", role = "healer", armor = "Leather",
        lust = false, brez = false, shroud = false,
        raidBuff = "phys",
        kickCD = 15, kickRange = "melee",
        dmgProfile = nil,
        soothe = false, purge = false, massDispel = false,
        aoeStops = 2,
        groupDR = nil,
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- PALADIN (Plate) — Devotion Aura
    -- ═══════════════════════════════════════════════════════════════════════
    [65] = {
        class = "Paladin", spec = "Holy", role = "healer", armor = "Plate",
        lust = false, brez = false, shroud = false,
        raidBuff = "dr",
        kickCD = 15, kickRange = "melee",
        dmgProfile = nil,
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = "Aura Mastery",
    },
    [66] = {
        class = "Paladin", spec = "Protection", role = "tank", armor = "Plate",
        lust = false, brez = false, shroud = false,
        raidBuff = "dr",
        kickCD = 15, kickRange = "melee",
        dmgProfile = nil,
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = "Aura Mastery",
    },
    [70] = {
        class = "Paladin", spec = "Retribution", role = "melee", armor = "Plate",
        lust = false, brez = false, shroud = false,
        raidBuff = "dr",
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Cleave",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = "Aura Mastery",
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- PRIEST (Cloth) — Fortitude, Mass Dispel
    -- ═══════════════════════════════════════════════════════════════════════
    [256] = {
        class = "Priest", spec = "Discipline", role = "healer", armor = "Cloth",
        lust = false, brez = false, shroud = false,
        raidBuff = "stam",
        kickCD = nil, kickRange = nil,
        dmgProfile = nil,
        soothe = false, purge = true, massDispel = true,
        aoeStops = 1,
        groupDR = "Power Word: Barrier",
    },
    [257] = {
        class = "Priest", spec = "Holy", role = "healer", armor = "Cloth",
        lust = false, brez = false, shroud = false,
        raidBuff = "stam",
        kickCD = nil, kickRange = nil,
        dmgProfile = nil,
        soothe = false, purge = true, massDispel = true,
        aoeStops = 1,
        groupDR = nil,
    },
    [258] = {
        class = "Priest", spec = "Shadow", role = "ranged", armor = "Cloth",
        lust = false, brez = false, shroud = false,
        raidBuff = "stam",
        kickCD = 45, kickRange = "ranged",
        dmgProfile = "Cleave",
        soothe = false, purge = true, massDispel = true,
        aoeStops = 1,
        groupDR = nil,
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- ROGUE (Leather) — Shroud
    -- ═══════════════════════════════════════════════════════════════════════
    [259] = {
        class = "Rogue", spec = "Assassination", role = "melee", armor = "Leather",
        lust = false, brez = false, shroud = true,
        raidBuff = nil,
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Priority ST",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 0,
        groupDR = nil,
    },
    [260] = {
        class = "Rogue", spec = "Outlaw", role = "melee", armor = "Leather",
        lust = false, brez = false, shroud = true,
        raidBuff = nil,
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Cleave",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 0,
        groupDR = nil,
    },
    [261] = {
        class = "Rogue", spec = "Subtlety", role = "melee", armor = "Leather",
        lust = false, brez = false, shroud = true,
        raidBuff = nil,
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Priority ST",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 0,
        groupDR = nil,
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- SHAMAN (Mail) — Lust, Skyfury, Purge
    -- ═══════════════════════════════════════════════════════════════════════
    [262] = {
        class = "Shaman", spec = "Elemental", role = "ranged", armor = "Mail",
        lust = true, brez = false, shroud = false,
        raidBuff = "skyfury",
        kickCD = 12, kickRange = "ranged",
        dmgProfile = "Cleave",
        soothe = false, purge = true, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },
    [263] = {
        class = "Shaman", spec = "Enhancement", role = "melee", armor = "Mail",
        lust = true, brez = false, shroud = false,
        raidBuff = "skyfury",
        kickCD = 12, kickRange = "ranged",
        dmgProfile = "Burst AoE",
        soothe = false, purge = true, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },
    [264] = {
        class = "Shaman", spec = "Restoration", role = "healer", armor = "Mail",
        lust = true, brez = false, shroud = false,
        raidBuff = "skyfury",
        kickCD = 12, kickRange = "ranged",
        dmgProfile = nil,
        soothe = false, purge = true, massDispel = false,
        aoeStops = 1,
        groupDR = "Spirit Link Totem",
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- WARLOCK (Cloth) — Brez, Healthstone, Gateway
    -- ═══════════════════════════════════════════════════════════════════════
    [265] = {
        class = "Warlock", spec = "Affliction", role = "ranged", armor = "Cloth",
        lust = false, brez = true, shroud = false,
        raidBuff = nil,
        kickCD = 24, kickRange = "ranged",
        dmgProfile = "Sustained AoE",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },
    [266] = {
        class = "Warlock", spec = "Demonology", role = "ranged", armor = "Cloth",
        lust = false, brez = true, shroud = false,
        raidBuff = nil,
        kickCD = 24, kickRange = "ranged",
        dmgProfile = "Burst AoE",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },
    [267] = {
        class = "Warlock", spec = "Destruction", role = "ranged", armor = "Cloth",
        lust = false, brez = true, shroud = false,
        raidBuff = nil,
        kickCD = 24, kickRange = "ranged",
        dmgProfile = "Priority ST",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 1,
        groupDR = nil,
    },

    -- ═══════════════════════════════════════════════════════════════════════
    -- WARRIOR (Plate) — Battle Shout, Rallying Cry
    -- ═══════════════════════════════════════════════════════════════════════
    [71] = {
        class = "Warrior", spec = "Arms", role = "melee", armor = "Plate",
        lust = false, brez = false, shroud = false,
        raidBuff = "ap",
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Cleave",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 2,
        groupDR = "Rallying Cry",
    },
    [72] = {
        class = "Warrior", spec = "Fury", role = "melee", armor = "Plate",
        lust = false, brez = false, shroud = false,
        raidBuff = "ap",
        kickCD = 15, kickRange = "melee",
        dmgProfile = "Burst AoE",
        soothe = false, purge = false, massDispel = false,
        aoeStops = 2,
        groupDR = "Rallying Cry",
    },
    [73] = {
        class = "Warrior", spec = "Protection", role = "tank", armor = "Plate",
        lust = false, brez = false, shroud = false,
        raidBuff = "ap",
        kickCD = 15, kickRange = "melee",
        dmgProfile = nil,
        soothe = false, purge = false, massDispel = false,
        aoeStops = 2,
        groupDR = "Rallying Cry",
    },
}
