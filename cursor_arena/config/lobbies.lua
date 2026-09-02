--[[
    Persistent lobbies.

    FFA — 3 maps. UI shows map picker.
    PVP — 1v1 / 2v2 / 3v3 / 4v4 (round elimination, one life). UI picks size then map.
    TDM  — team kill race.
]]

local FFA_MAPS = { 'construction', 'cargo', 'dust' }
local PVP_MAPS = { 'construction', 'cargo', 'dust' }

local function ffaLobby(mapId)
    return {
        id = 'ffa_' .. mapId,
        name = 'FFA',
        description = 'Everyone for themselves. First to 30.',
        map = mapId,
        maxPlayers = 16,
        killsToWin = 30,
        loadouts = { 'duelist', 'raider', 'assault', 'shock', 'marksman' },
        kill_rewards = { health = 25 },
        sizeLabel = 'FFA',
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
        loadouts = { 'duelist', 'raider', 'assault', 'shock', 'marksman' },
        teamkill = false,
        joinDuringMatch = false,
        sizeLabel = ('%sv%s'):format(size, size),
        win_rewards = { money = 250 * size },
    }
end

Config.Lobbies = {
    ffa = {
        ffaLobby(FFA_MAPS[1]),
        ffaLobby(FFA_MAPS[2]),
        ffaLobby(FFA_MAPS[3]),
    },
    pvp = {
        pvpLobby(1, PVP_MAPS[1]), pvpLobby(1, PVP_MAPS[2]), pvpLobby(1, PVP_MAPS[3]),
        pvpLobby(2, PVP_MAPS[1]), pvpLobby(2, PVP_MAPS[2]), pvpLobby(2, PVP_MAPS[3]),
        pvpLobby(3, PVP_MAPS[1]), pvpLobby(3, PVP_MAPS[2]), pvpLobby(3, PVP_MAPS[3]),
        pvpLobby(4, PVP_MAPS[1]), pvpLobby(4, PVP_MAPS[2]), pvpLobby(4, PVP_MAPS[3]),
    },
    tdm = {
        {
            id = 'tdm_dust',
            name = 'Dust TDM',
            description = 'Two sides, one strip of sand.',
            map = 'dust',
            maxPlayersPerTeam = 8,
            killsToWin = 50,
            loadouts = { 'duelist', 'raider', 'assault', 'marksman' },
            kill_rewards = { health = 20 },
            win_rewards = { money = 500 },
            teamkill = false,
            sizeLabel = 'TDM',
        },
        {
            id = 'tdm_cargo',
            name = 'Cargo TDM',
            description = 'Close quarters. Hold the corridor.',
            map = 'cargo',
            maxPlayersPerTeam = 6,
            killsToWin = 40,
            loadouts = { 'duelist', 'raider', 'shock' },
            kill_rewards = { health = 25, armor = 15 },
            win_rewards = { money = 500 },
            teamkill = false,
            sizeLabel = 'TDM',
        },
        {
            id = 'tdm_construction',
            name = 'Construction TDM',
            description = 'Vertical team fights.',
            map = 'construction',
            maxPlayersPerTeam = 6,
            killsToWin = 40,
            loadouts = { 'duelist', 'raider', 'assault' },
            kill_rewards = { health = 20 },
            teamkill = false,
            sizeLabel = 'TDM',
        },
    },
}

Config.FfaMaps = FFA_MAPS
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
