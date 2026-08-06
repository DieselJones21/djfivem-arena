Config = {}

--[[
    General
]]
Config.Debug = false
Config.Locale = 'en'
Config.Command = 'arena'           -- /arena enters the spawn lobby (or opens UI if already inside)
Config.MenuKey = 'G'               -- open lobby UI while inside the spawn lobby
Config.RequireItem = false         -- set to item name (e.g. 'arena_ticket') or false
Config.MaxActiveMatches = 12
Config.LobbyIdleTimeout = 120      -- seconds before empty lobby is closed
Config.InviteTimeout = 30          -- seconds for private match invites
Config.DefaultRoundTime = 600      -- seconds
Config.CountdownSeconds = 5
Config.RespawnDelay = 3            -- seconds after death before respawn
Config.LeaveCooldown = 5           -- seconds before player can rejoin after leaving

--[[
    Framework bridge: 'auto' | 'esx' | 'qb' | 'qbx' | 'standalone'
]]
Config.Framework = 'auto'

--[[
    World entry ped — talking to this ped teleports you INTO the spawn lobby map.
    It does NOT open the UI.
]]
Config.EntryPed = {
    enabled = true,
    coords = vec3(-265.0, -963.0, 31.2),
    heading = 200.0,
    drawDistance = 25.0,
    interactDistance = 2.0,
    marker = {
        type = 1,
        scale = vec3(1.2, 1.2, 0.6),
        color = { r = 220, g = 80, b = 40, a = 140 },
        bob = false,
        faceCamera = false,
    },
    blip = {
        enabled = true,
        sprite = 437,
        color = 1,
        scale = 0.85,
        label = 'PVP Arena',
    },
    ped = {
        enabled = true,
        model = `s_m_y_marine_01`,
        scenario = 'WORLD_HUMAN_CLIPBOARD',
    },
}

--[[
    Spawn lobby hub map
    Players are teleported here from the entry ped.
    Inside this map they press G to open the matchmaking UI.
    After a match ends they return here (not to the world).
    Change these coords to your lobby MLO / interior.
]]
Config.SpawnLobby = {
    -- Main spawn when entering the hub (pick randomly from list)
    spawns = {
        vec4(405.0, -997.0, -99.0, 90.0),
        vec4(402.0, -1000.0, -99.0, 0.0),
        vec4(408.0, -1000.0, -99.0, 180.0),
        vec4(405.0, -1003.0, -99.0, 270.0),
    },
    center = vec3(405.0, -997.0, -99.0),
    radius = 40.0,                 -- soft bounds while in hub (optional)
    enforceBounds = true,
    -- Where to send them when they EXIT the hub back to the city
    exitCoords = vec4(-265.0, -963.0, 31.2, 200.0),
    -- Show on-screen hint while in hub
    hint = true,
    -- Optional exit ped inside the hub
    exitPed = {
        enabled = true,
        coords = vec3(400.0, -997.0, -99.0),
        heading = 270.0,
        model = `s_m_y_marine_01`,
        scenario = 'WORLD_HUMAN_GUARD_STAND',
        interactDistance = 2.0,
    },
}

--[[
    Legacy alias — match leave returns to spawn lobby, not the city.
]]
Config.ReturnLocation = {
    coords = Config.SpawnLobby.spawns[1],
}

--[[
    ox_inventory integration
]]
Config.OxInventory = {
    enabled = true,
    stashPrefix = 'arena_',
    stashSlots = 50,
    stashWeight = 200000,
    clearBeforeLoadout = true,
    restoreOnLeave = true,
    extras = {
        -- { item = 'armour', count = 1 },
    },
}

--[[
    wasabi_ambulance integration
]]
Config.WasabiAmbulance = {
    enabled = true,
    resourceName = 'wasabi_ambulance',
    reviveEvent = 'wasabi_ambulance:revive',
    deathStateExport = 'isPlayerDead',
    blockDeathScreen = true,
    forceReviveOnRespawn = true,
    disableJobInteractions = true,
}

--[[
    Match rules
]]
Config.Rules = {
    friendlyFire = false,
    allowVehicles = false,
    clearWanted = true,
    godModeOutsideCombat = false,
    healOnKill = false,
    healOnKillAmount = 25,
    armorOnKill = false,
    armorOnKillAmount = 15,
    infiniteAmmo = true,
    refillAmmoOnRespawn = true,
    disableIdleCam = true,
    blockedControls = {},
    enforceBounds = true,
    boundsWarning = true,
}

Config.HUD = {
    showKills = true,
    showDeaths = true,
    showTimer = true,
    showTeamScores = true,
    killfeed = true,
    killfeedDuration = 4000,
}

Config.Rewards = {
    enabled = false,
    win = { money = 500, items = {} },
    loss = { money = 100, items = {} },
    kill = { money = 25, items = {} },
    account = 'money',
}

Config.Logging = {
    enabled = false,
    webhook = '',
    logMatchStart = true,
    logMatchEnd = true,
}

Config.Permissions = {
    adminAce = 'arena.admin',
    forceStartAce = 'arena.forcestart',
    createPrivateAce = false,
}
