--[[
    Modes shown in the UI.

    Create-Lobby builds custom lobbies from:
      - size (1v1 .. 5v5)
      - style (pvp = round elimination, tdm = kill score)
      - weapon class (pistols / smgs / rifles)
]]

Config.Modes = {
    -- Quick-play FFA (ARENA FFA tab)
    {
        id = 'pistol_ffa',
        label = 'Pistol FFA',
        description = 'Free-for-all. Pistols only.',
        type = 'ffa',
        icon = 'pistol',
        weaponCategory = 'pistols',
        allowWeaponChoice = true,
        minPlayers = 2,
        maxPlayers = 16,
        scoreLimit = 25,
        timeLimit = 600,
        teamSize = nil,
        rounds = 1,
        respawn = true,
        color = '#e10600',
        tab = 'ffa',
    },
    {
        id = 'smg_ffa',
        label = 'SMG FFA',
        description = 'Free-for-all. SMGs only.',
        type = 'ffa',
        icon = 'smg',
        weaponCategory = 'smgs',
        allowWeaponChoice = true,
        minPlayers = 2,
        maxPlayers = 16,
        scoreLimit = 30,
        timeLimit = 600,
        teamSize = nil,
        rounds = 1,
        respawn = true,
        color = '#e10600',
        tab = 'ffa',
    },
    {
        id = 'rifle_ffa',
        label = 'Rifle FFA',
        description = 'Free-for-all. Rifles only.',
        type = 'ffa',
        icon = 'rifle',
        weaponCategory = 'rifles',
        allowWeaponChoice = true,
        minPlayers = 2,
        maxPlayers = 16,
        scoreLimit = 30,
        timeLimit = 600,
        teamSize = nil,
        rounds = 1,
        respawn = true,
        color = '#e10600',
        tab = 'ffa',
    },

    -- Lobby templates (Create Lobby modal uses these as bases)
    {
        id = '1v1',
        label = '1v1 PVP',
        description = 'Duel. Best of rounds.',
        type = 'team',
        icon = 'duel',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 2,
        maxPlayers = 2,
        scoreLimit = 5,
        timeLimit = 180,
        teamSize = 1,
        rounds = 5,
        respawn = false,
        color = '#e10600',
        tab = 'lobbies',
        style = 'pvp',
    },
    {
        id = '2v2',
        label = '2v2 PVP',
        description = 'Two-man squads.',
        type = 'team',
        icon = 'squad',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 4,
        maxPlayers = 4,
        scoreLimit = 5,
        timeLimit = 240,
        teamSize = 2,
        rounds = 5,
        respawn = false,
        color = '#e10600',
        tab = 'lobbies',
        style = 'pvp',
    },
    {
        id = '3v3',
        label = '3v3 PVP',
        description = 'Mid-size team skirmish.',
        type = 'team',
        icon = 'squad',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 6,
        maxPlayers = 6,
        scoreLimit = 5,
        timeLimit = 300,
        teamSize = 3,
        rounds = 5,
        respawn = true,
        color = '#e10600',
        tab = 'lobbies',
        style = 'pvp',
    },
    {
        id = '4v4',
        label = '4v4 PVP',
        description = 'Full squad warfare.',
        type = 'team',
        icon = 'war',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 8,
        maxPlayers = 8,
        scoreLimit = 7,
        timeLimit = 360,
        teamSize = 4,
        rounds = 7,
        respawn = true,
        color = '#e10600',
        tab = 'lobbies',
        style = 'pvp',
    },
    {
        id = '5v5',
        label = '5v5 PVP',
        description = 'Maximum firepower.',
        type = 'team',
        icon = 'war',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 10,
        maxPlayers = 10,
        scoreLimit = 7,
        timeLimit = 420,
        teamSize = 5,
        rounds = 7,
        respawn = true,
        color = '#e10600',
        tab = 'lobbies',
        style = 'pvp',
    },
    {
        id = 'tdm',
        label = 'Team Deathmatch',
        description = 'Red vs Blue kill race.',
        type = 'tdm',
        icon = 'tdm',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 2,
        maxPlayers = 20,
        scoreLimit = 50,
        timeLimit = 720,
        teamSize = nil,
        rounds = 1,
        respawn = true,
        color = '#e10600',
        tab = 'lobbies',
        style = 'tdm',
        friendlyFire = false,
    },
}

--- Build a dynamic mode for Create Lobby (size + style + class + rounds)
function Config.BuildLobbyMode(size, style, weaponClass, rounds)
    size = tonumber(size) or 1
    style = style == 'tdm' and 'tdm' or 'pvp'
    weaponClass = weaponClass or 'pistols'
    rounds = math.max(1, math.min(40, tonumber(rounds) or 5))

    local players = size * 2
    local isTdm = style == 'tdm'

    return {
        id = ('%sv%s_%s_%s'):format(size, size, style, weaponClass),
        label = ('%sv%s %s'):format(size, size, isTdm and 'TDM' or 'PVP'),
        description = isTdm and 'Team deathmatch lobby' or 'Round-based PVP lobby',
        type = isTdm and 'tdm' or 'team',
        icon = 'squad',
        weaponCategory = weaponClass,
        allowWeaponChoice = true,
        minPlayers = isTdm and 2 or players,
        maxPlayers = players,
        scoreLimit = isTdm and math.max(rounds, 10) or rounds,
        timeLimit = isTdm and 600 or (120 + size * 60),
        teamSize = size,
        rounds = rounds,
        respawn = isTdm or size >= 3,
        color = '#e10600',
        friendlyFire = false,
        dynamic = true,
    }
end

function Config.GetMode(modeId)
    for i = 1, #Config.Modes do
        if Config.Modes[i].id == modeId then
            return Config.Modes[i]
        end
    end
end
