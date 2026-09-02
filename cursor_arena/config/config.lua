Config = {}

--[[
    cursor_arena — IC Arenas-style PvP with your maps, weapons, and ox/qbox stack.
]]

Config.Debug = false
Config.Locale = 'en'
Config.Framework = 'auto' -- 'auto' | 'qbx' | 'qb' | 'esx' | 'standalone'

--[[ Commands + keybinds (also appear in GTA Settings → Key Bindings) ]]
Config.Commands = {
    { name = 'arenas',        enable = true,  key = 'F6' },
    { name = 'leavearena',    enable = true,  key = '' },
    { name = 'killstreak',    enable = true,  key = '' },
    { name = 'arenasounds',   enable = true,  key = '' },
    { name = 'changeloadout', enable = true,  key = '' },
}

Config.RequireItem = false -- e.g. 'arena_ticket' or false
Config.RespawnTime = 3
Config.CountdownSeconds = 5
Config.StartingBucket = 100
Config.ShowdownStartDelay = 10
Config.MatchHistoryDays = 7
Config.LeaveCooldown = 4

Config.Announcements = {
    enabled = true,
    interval = 5 * 60000,
}

Config.Sounds = {
    enabled = true,
    volume = 0.18,
    bellAt = 0.9,
}

Config.SquadVoice = {
    enabled = true,
    channel = 1000, -- pma-voice; each lobby uses two channels from here up
}

Config.Elo = {
    k = 32,
    floor = 100,
    start = 1000,
}

Config.AfkKick = {
    enabled = false,
    minutes = 5,
    warnAt = 60,
}

Config.Nameplates = {
    enabled = true,
    range = 120.0,
}

Config.TeamPanel = {
    enabled = true,
    titles = true,
}

Config.HitMarkers = {
    enabled = true,
    damage = true,
}

Config.Boundaries = {
    show = false,
    warningTime = 5,
    immunityTime = 3,
}

Config.KillstreakStyle = 'medalslam' -- medalslam | badge | emblem | tactical
Config.KillstreakVolume = 0.18
Config.Killstreaks = {
    { kills = 2,  label = 'DOUBLE KILL' },
    { kills = 3,  label = 'TRIPLE KILL' },
    { kills = 4,  label = 'DOMINATING',     reward = 'armor', amount = 100 },
    { kills = 5,  label = 'RAMPAGE' },
    { kills = 6,  label = 'KILLING SPREE' },
    { kills = 7,  label = 'MONSTER KILL' },
    { kills = 8,  label = 'UNSTOPPABLE',    reward = 'speed', seconds = 20 },
    { kills = 9,  label = 'ULTRA KILL' },
    { kills = 10, label = 'GODLIKE',        reward = 'armor', amount = 100 },
}

Config.LeaderboardTitles = {
    default = {
        { rank = 1,  title = 'Champion' },
        { rank = 2,  title = 'Warlord' },
        { rank = 3,  title = 'Executioner' },
        { rank = 5,  title = 'Veteran' },
        { rank = 10, title = 'Contender' },
    },
    showdown = {
        { rank = 1,  title = 'Apex' },
        { rank = 2,  title = 'Duelist King' },
        { rank = 3,  title = 'Bloodied' },
        { rank = 5,  title = 'Challenger' },
        { rank = 10, title = 'Prospect' },
    },
}

--[[ ox_target / qb-target / prompt ]]
Config.Target = {
    enabled = true, -- auto-detect ox_target then qb-target; otherwise [E]
}

--[[ Arena NPCs — walk up to open the lobby browser ]]
Config.Peds = {
    {
        model = `s_m_y_marine_01`,
        coords = vec4(-265.0, -963.0, 31.2, 200.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        interactDistance = 2.2,
        blip = {
            enabled = true,
            sprite = 437,
            color = 1,
            scale = 0.85,
            label = 'PVP Arena',
        },
    },
}

--[[ ox_inventory ]]
Config.OxInventory = {
    enabled = true,
    clearBeforeLoadout = true,
    restoreOnLeave = true,
    extras = {
        -- { item = 'armour', count = 1 },
    },
}

--[[ Ambulance auto-detect. First running resource wins. ]]
Config.Ambulance = {
    enabled = true,
    forceRevive = true,
    blockDeathScreen = true,
    resources = {
        'wasabi_ambulance',
        'wasabi_ambulance_v2',
        'qbx_medical',
        'qbx_ambulancejob',
        'qb-ambulancejob',
        'esx_ambulancejob',
        'tk_ambulancejob',
        'p_ambulancejob',
        'ND_Ambulance',
        'ars_ambulancejob',
        'ak47_qb_ambulancejob',
    },
}

Config.Rules = {
    allowVehicles = false,
    clearWanted = true,
    infiniteAmmo = true,
    refillAmmoOnRespawn = true,
    disableIdleCam = true,
    godModeOutsideCombat = false,
}

Config.Rewards = {
    account = 'cash', -- qbox/qb cash|bank  ·  esx money|bank
}

Config.Permissions = {
    adminAce = 'arena.admin',
}

Config.WeaponCategories = {
    WEAPON_PISTOL = 'pistol',
    WEAPON_COMBATPISTOL = 'pistol',
    WEAPON_HEAVYPISTOL = 'pistol',
    WEAPON_APPISTOL = 'pistol',
    WEAPON_PISTOL50 = 'pistol',
    WEAPON_SNSPISTOL = 'pistol',
    WEAPON_SMG = 'smg',
    WEAPON_MICROSMG = 'smg',
    WEAPON_ASSAULTSMG = 'smg',
    WEAPON_COMBATPDW = 'smg',
    WEAPON_MACHINEPISTOL = 'smg',
    WEAPON_MINISMG = 'smg',
    WEAPON_ASSAULTRIFLE = 'rifle',
    WEAPON_CARBINERIFLE = 'rifle',
    WEAPON_SPECIALCARBINE = 'rifle',
    WEAPON_BULLPUPRIFLE = 'rifle',
    WEAPON_ADVANCEDRIFLE = 'rifle',
    WEAPON_COMPACTRIFLE = 'rifle',
    WEAPON_PUMPSHOTGUN = 'shotgun',
    WEAPON_SAWNOFFSHOTGUN = 'shotgun',
    WEAPON_ASSAULTSHOTGUN = 'shotgun',
    WEAPON_HEAVYSHOTGUN = 'shotgun',
    WEAPON_COMBATSHOTGUN = 'shotgun',
    WEAPON_SNIPERRIFLE = 'sniper',
    WEAPON_HEAVYSNIPER = 'sniper',
    WEAPON_MARKSMANRIFLE = 'sniper',
    WEAPON_MUSKET = 'sniper',
}
