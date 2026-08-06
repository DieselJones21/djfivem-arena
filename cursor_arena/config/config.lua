Config = {}

--[[
    General
]]
Config.Debug = false
Config.Locale = 'en'
Config.Command = 'arena'           -- /arena opens the lobby UI
Config.OpenKey = 'F7'              -- optional keybind (set false to disable)
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
    Marker / blip to open the arena lobby in-world
]]
Config.Lobby = {
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
    Return location when leaving a match (or dying outside wasabi revive path)
]]
Config.ReturnLocation = {
    coords = vec4(-265.0, -963.0, 31.2, 200.0),
}

--[[
    ox_inventory integration
    - stashPlayerInventory: moves player inventory into a temporary stash while in arena
    - giveLoadout: grants configured weapons/ammo for the match
    - restoreOnLeave: returns original inventory when leaving
]]
Config.OxInventory = {
    enabled = true,
    stashPrefix = 'arena_',
    stashSlots = 50,
    stashWeight = 200000,
    clearBeforeLoadout = true,
    restoreOnLeave = true,
    -- Items granted in addition to the chosen weapon (armor, medkits, etc.)
    extras = {
        -- { item = 'armour', count = 1 },
    },
}

--[[
    wasabi_ambulance integration
    While in an arena match, death is handled by the arena (instant/delayed respawn).
    Outside matches, wasabi remains the authority.
]]
Config.WasabiAmbulance = {
    enabled = true,
    resourceName = 'wasabi_ambulance',
    -- Events commonly used by wasabi_ambulance (override if your fork differs)
    reviveEvent = 'wasabi_ambulance:revive',          -- client event
    deathStateExport = 'isPlayerDead',                -- export name if available
    blockDeathScreen = true,                          -- hide wasabi death UI inside arena
    forceReviveOnRespawn = true,
    -- Optional: disable ambulance job interactions while in arena
    disableJobInteractions = true,
}

--[[
    Match rules applied globally (modes can override)
]]
Config.Rules = {
    friendlyFire = false,          -- team modes
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
    -- Weapons / controls to block while in arena
    blockedControls = {
        -- 37, -- weapon wheel (optional)
    },
    -- Prevent leaving the map bounds (soft push-back)
    enforceBounds = true,
    boundsWarning = true,
}

--[[
    Scoreboard / HUD
]]
Config.HUD = {
    showKills = true,
    showDeaths = true,
    showTimer = true,
    showTeamScores = true,
    killfeed = true,
    killfeedDuration = 4000,
}

--[[
    Rewards (optional – set enabled = false to disable)
]]
Config.Rewards = {
    enabled = false,
    win = { money = 500, items = {} },
    loss = { money = 100, items = {} },
    kill = { money = 25, items = {} },
    account = 'money', -- 'money' | 'bank' | 'black_money' (framework dependent)
}

--[[
    Discord / logging webhooks (optional)
]]
Config.Logging = {
    enabled = false,
    webhook = '',
    logMatchStart = true,
    logMatchEnd = true,
}

--[[
    Permissions
]]
Config.Permissions = {
    adminAce = 'arena.admin',
    forceStartAce = 'arena.forcestart',
    createPrivateAce = false, -- false = anyone can create private lobbies
}
