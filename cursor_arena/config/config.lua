Config = {}

--[[
    cursor_arena — IC Arenas-style PvP with your maps, weapons, and ox/qbox stack.
]]

Config.Debug = false
Config.Locale = 'en'
Config.Framework = 'auto' -- 'auto' | 'qbx' | 'qb' | 'esx' | 'standalone'

--[[ Commands + keybinds (also appear in GTA Settings → Key Bindings) ]]
Config.Commands = {
    { name = 'arenas',        enable = true,  key = 'G' }, -- only works inside the spawn lobby
    { name = 'leavearena',    enable = true,  key = '' },
    { name = 'killstreak',    enable = true,  key = '' },
    { name = 'arenasounds',   enable = true,  key = '' },
    { name = 'changeloadout', enable = true,  key = '' },
}

Config.MenuKey = 'G'

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
    pvp = {
        { rank = 1,  title = 'Apex' },
        { rank = 2,  title = 'Duelist King' },
        { rank = 3,  title = 'Bloodied' },
        { rank = 5,  title = 'Challenger' },
        { rank = 10, title = 'Prospect' },
    },
}

--[[
    Interactions: prefers `interact` (darktrovx), then ox_target, then qb-target, then [E].
]]
Config.Target = {
    enabled = true,
    prefer = 'interact', -- 'interact' | 'ox_target' | 'auto'
}

--[[
    WORLD ENTRY PED — PASTE COORDS
    Talking to this ped teleports you into the spawn lobby. It does not open the UI.
]]
Config.EntryPed = {
    enabled = true,
    coords = vec4(-265.0, -963.0, 31.2, 200.0), -- PASTE x, y, z, heading
    model = `s_m_y_marine_01`,
    scenario = 'WORLD_HUMAN_CLIPBOARD',
    interactDistance = 2.0,
    interactLabel = 'Enter Arena',
    blip = {
        enabled = true,
        sprite = 437,
        color = 1,
        scale = 0.85,
        label = 'PVP Arena',
    },
}

--[[
    SPAWN LOBBY HUB — PASTE YOUR LOBBY MLO COORDS
    Players land here from the entry ped. Press G to open the arena UI.
]]
Config.SpawnLobby = {
    spawns = {
        vec4(405.0, -997.0, -99.0, 90.0), -- PASTE hub spawn
        vec4(402.0, -1000.0, -99.0, 0.0),
        vec4(408.0, -1000.0, -99.0, 180.0),
        vec4(405.0, -1003.0, -99.0, 270.0),
    },
    center = vec3(405.0, -997.0, -99.0), -- PASTE hub center
    radius = 40.0,
    enforceBounds = true,
    hint = true,
}

--[[
    EXIT PED — PASTE COORDS INSIDE THE HUB
    Sends the player back to where they entered from.
]]
Config.ExitPed = {
    enabled = true,
    coords = vec4(400.0, -997.0, -99.0, 270.0), -- PASTE
    model = `s_m_y_marine_01`,
    scenario = 'WORLD_HUMAN_GUARD_STAND',
    interactDistance = 2.0,
    interactLabel = 'Leave Arena',
}

--[[
    CLOTHING PED — PASTE COORDS INSIDE THE HUB
    Opens illenium-appearance clothing (not character creator).
]]
Config.ClothingPed = {
    enabled = true,
    coords = vec4(408.0, -997.0, -99.0, 180.0), -- PASTE
    model = `s_f_y_shop_mid`,
    scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
    interactDistance = 2.0,
    interactLabel = 'Change Clothes',
    resource = 'illenium-appearance',
}

--[[
    Inventory: do NOT confiscate. Block ox_inventory while in a match.
    Weapons are given natively into the player's hands with infinite ammo.
]]
Config.OxInventory = {
    enabled = true,
    confiscate = false,
    blockWhileInMatch = true,
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
