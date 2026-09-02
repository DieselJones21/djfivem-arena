--[[
    Persistent lobbies.

    FFA / TDM — 2 shared arenas (arena_1, arena_2)
    PVP       — 4 maps (pvp_1 .. pvp_4) × 1v1 / 2v2 / 3v3 / 4v4
]]

local ARENA_MAPS = { 'arena_1', 'arena_2' }
local PVP_MAPS = { 'pvp_1', 'pvp_2', 'pvp_3', 'pvp_4' }
local LOADOUTS = { 'pistols', 'smg', 'ar' }

local function ffaLobby(mapId)
    return {
        id = 'ffa_' .. mapId,
        name = 'FFA',
        description = 'Everyone for themselves. First to 30.',
        map = mapId,
        maxPlayers = 12,
        killsToWin = 30,
        loadouts = LOADOUTS,
        kill_rewards = { health = 25 },
        sizeLabel = 'FFA',
    }
end

local function tdmLobby(mapId)
    return {
        id = 'tdm_' .. mapId,
        name = 'TDM',
        description = 'Orange vs Blue. Shared score.',
        map = mapId,
        maxPlayersPerTeam = 5,
        killsToWin = 50,
        loadouts = LOADOUTS,
        kill_rewards = { health = 20 },
        win_rewards = { money = 500 },
        teamkill = false,
        sizeLabel = 'TDM',
    }
end

local function pvpLobby(size, mapId)
    return {
        id = ('pvp_%sv%s_%s'):format(size, size, mapId),
        name = ('%sv%s'):format(size, size),
        description = 'One life a round. First to the round target.',
        map = mapId,
        maxPlayersPerTeam = size,
        roundsToWin = size == 1 and 5 or 4,
        roundTime = 90 + (size * 15),
        loadouts = LOADOUTS,
        teamkill = false,
        joinDuringMatch = false,
        sizeLabel = ('%sv%s'):format(size, size),
        win_rewards = { money = 250 * size },
    }
end

Config.Lobbies = {
    ffa = {
        ffaLobby(ARENA_MAPS[1]),
        ffaLobby(ARENA_MAPS[2]),
    },
    pvp = {
        pvpLobby(1, PVP_MAPS[1]), pvpLobby(1, PVP_MAPS[2]), pvpLobby(1, PVP_MAPS[3]), pvpLobby(1, PVP_MAPS[4]),
        pvpLobby(2, PVP_MAPS[1]), pvpLobby(2, PVP_MAPS[2]), pvpLobby(2, PVP_MAPS[3]), pvpLobby(2, PVP_MAPS[4]),
        pvpLobby(3, PVP_MAPS[1]), pvpLobby(3, PVP_MAPS[2]), pvpLobby(3, PVP_MAPS[3]), pvpLobby(3, PVP_MAPS[4]),
        pvpLobby(4, PVP_MAPS[1]), pvpLobby(4, PVP_MAPS[2]), pvpLobby(4, PVP_MAPS[3]), pvpLobby(4, PVP_MAPS[4]),
    },
    tdm = {
        tdmLobby(ARENA_MAPS[1]),
        tdmLobby(ARENA_MAPS[2]),
    },
}

Config.FfaMaps = ARENA_MAPS
Config.PvpMaps = PVP_MAPS
Config.PvpSizes = { 1, 2, 3, 4 }

function Config.GetLobby(lobbyId)
    for mode, list in pairs(Config.Lobbies) do
        for i = 1, #list do
            if list[i].id == lobbyId then
                return list[i], mode
            end
        end
    end
end
