--[[
    Persistent lobbies — one list per mode, same shape as IC Arenas.

    FFA starts at 2 players.
    TDM starts once both sides have someone.
    Showdown is ranked (ELO), one life a round.
]]

Config.Lobbies = {
    ffa = {
        {
            id = 'construction_ffa',
            name = 'Construction FFA',
            description = 'Every floor is a fight. First to 30.',
            map = 'construction',
            maxPlayers = 16,
            killsToWin = 30,
            loadouts = { 'duelist', 'raider', 'assault' },
            kill_rewards = { health = 25 },
        },
        {
            id = 'cargo_ffa',
            name = 'Cargo FFA',
            description = 'Containers, corners, chaos.',
            map = 'cargo',
            maxPlayers = 16,
            killsToWin = 30,
            loadouts = { 'duelist', 'raider', 'assault', 'shock' },
            kill_rewards = { health = 20, armor = 10 },
        },
        {
            id = 'dust_ffa',
            name = 'Dust FFA',
            description = 'Long sightlines. No cover for the timid.',
            map = 'dust',
            maxPlayers = 16,
            killsToWin = 25,
            loadouts = { 'duelist', 'assault', 'marksman' },
            kill_rewards = { health = 25 },
        },
    },

    tdm = {
        {
            id = 'dust_tdm',
            name = 'Dust TDM',
            description = 'Two sides, one strip of sand.',
            map = 'dust',
            maxPlayersPerTeam = 8,
            killsToWin = 50,
            loadouts = { 'duelist', 'raider', 'assault', 'marksman' },
            kill_rewards = { health = 20 },
            win_rewards = { money = 500 },
            teamkill = false,
        },
        {
            id = 'cargo_tdm',
            name = 'Cargo TDM',
            description = 'Close quarters. Hold the corridor.',
            map = 'cargo',
            maxPlayersPerTeam = 6,
            killsToWin = 40,
            loadouts = { 'duelist', 'raider', 'shock' },
            kill_rewards = { health = 25, armor = 15 },
            win_rewards = { money = 500 },
            teamkill = false,
        },
        {
            id = 'pool_tdm',
            name = 'Pool TDM',
            description = 'Deck to deck. Friendly fire off.',
            map = 'pool',
            maxPlayersPerTeam = 5,
            killsToWin = 35,
            loadouts = { 'duelist', 'raider', 'assault' },
            kill_rewards = { health = 15 },
            teamkill = false,
        },
    },

    showdown = {
        {
            id = 'rooftops_showdown',
            name = 'Rooftops Showdown',
            description = 'One life. Ranked. Leave and you concede.',
            map = 'rooftops',
            maxPlayersPerTeam = 5,
            roundsToWin = 5,
            roundTime = 120,
            loadouts = { 'duelist', 'raider', 'assault', 'marksman' },
            win_rewards = { money = 1200 },
            teamkill = false,
            joinDuringMatch = true,
        },
        {
            id = 'construction_showdown',
            name = 'Construction Showdown',
            description = 'Ranked elimination across the pit.',
            map = 'construction',
            maxPlayersPerTeam = 4,
            roundsToWin = 5,
            roundTime = 100,
            loadouts = { 'duelist', 'assault', 'shock' },
            win_rewards = { money = 1000 },
            teamkill = false,
            joinDuringMatch = false,
        },
        {
            id = 'pool_showdown',
            name = 'Pool Duel',
            description = 'Tight ranked 3v3 on the deck.',
            map = 'pool',
            maxPlayersPerTeam = 3,
            roundsToWin = 4,
            roundTime = 90,
            loadouts = { 'duelist', 'raider' },
            win_rewards = { money = 800 },
            teamkill = false,
            joinDuringMatch = true,
        },
    },
}

function Config.GetLobby(lobbyId)
    for mode, list in pairs(Config.Lobbies) do
        for i = 1, #list do
            if list[i].id == lobbyId then
                return list[i], mode
            end
        end
    end
end
