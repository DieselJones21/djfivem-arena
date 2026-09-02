Arena = Arena or {}

local function bootstrap(src)
    local lobby = Arena.GetPlayerLobby(src)
    local stats = Arena.Stats.GetAllModes(src)
    return {
        playerId = src,
        playerName = Arena.Framework.GetName(src),
        framework = Arena.Framework.name,
        loadouts = Arena.Shop.SerializeLoadouts(src),
        shop = Arena.Shop.Catalog(src),
        coins = Arena.Donator.GetBalance(src),
        coinLabel = Arena.Donator.Label(),
        maps = Arena.Utils.SerializeMaps(),
        lobbies = Arena.ListLobbies(),
        stats = stats,
        leaderboard = {
            ffa = Arena.Stats.GetLeaderboard('ffa', 25),
            tdm = Arena.Stats.GetLeaderboard('tdm', 25),
            pvp = Arena.Stats.GetLeaderboard('pvp', 25),
            showdown = Arena.Stats.GetLeaderboard('showdown', 25),
        },
        history = Arena.Stats.GetHistory(src, 20),
        inHub = Arena.PlayerHub[src] == true,
        current = lobby and Arena.PublicLobby(lobby) or nil,
        titles = Config.LeaderboardTitles,
        sounds = Config.Sounds,
        killstreakStyle = Config.KillstreakStyle,
    }
end

lib.callback.register('cursor_arena:getBootstrap', function(source)
    return bootstrap(source)
end)

lib.callback.register('cursor_arena:listLobbies', function()
    return Arena.ListLobbies()
end)

lib.callback.register('cursor_arena:getLobby', function(_, lobbyId)
    local lobby = Arena.Lobbies[lobbyId]
    if not lobby then return end
    return Arena.PublicLobby(lobby)
end)

lib.callback.register('cursor_arena:joinLobby', function(source, data)
    data = data or {}
    local ok, result = Arena.JoinLobby(source, data.lobbyId, {
        team = data.team,
        loadoutId = data.loadoutId,
        weaponId = data.weaponId,
    })
    if not ok then
        return { ok = false, error = result, message = L(result or 'cannot_join') }
    end
    return { ok = true, lobby = result }
end)

lib.callback.register('cursor_arena:leaveLobby', function(source)
    local ok, err = Arena.LeaveLobby(source, false, true)
    if ok == false and err then
        return { ok = false, message = L(err) }
    end
    return { ok = true }
end)

lib.callback.register('cursor_arena:setTeam', function(source, team)
    local ok, err = Arena.SetTeam(source, team)
    if not ok then
        return { ok = false, message = L(err or 'lobby_full') }
    end
    return { ok = true }
end)

lib.callback.register('cursor_arena:changeLoadout', function(source, data)
    data = data or {}
    local ok, err = Arena.ChangeLoadout(source, data.loadoutId, data.weaponId)
    if not ok then
        return { ok = false, message = L(err or 'invalid_loadout') }
    end
    return { ok = true }
end)

lib.callback.register('cursor_arena:getLeaderboard', function(_, mode)
    return Arena.Stats.GetLeaderboard(mode or 'ffa', 50)
end)

lib.callback.register('cursor_arena:getMyStats', function(source)
    return Arena.Stats.GetAllModes(source)
end)

lib.callback.register('cursor_arena:getHistory', function(source)
    return Arena.Stats.GetHistory(source, 25)
end)

lib.callback.register('cursor_arena:myLoadouts', function(source)
    return Arena.Shop.SerializeLoadouts(source)
end)

lib.callback.register('cursor_arena:buyShop', function(source, data)
    data = data or {}
    local ok, err, extra = Arena.Shop.Purchase(source, data.weaponId)
    if not ok then
        return { ok = false, error = err, message = L(err or 'cannot_join') }
    end
    extra = extra or { coins = Arena.Donator.GetBalance(source), shop = Arena.Shop.Catalog(source), loadouts = Arena.Shop.SerializeLoadouts(source) }
    extra.ok = true
    extra.bought = err == 'bought'
    extra.owned = err == 'owned'
    return extra
end)

RegisterNetEvent('cursor_arena:server:playerDied', function(killerServerId, weaponHash)
    Arena.OnPlayerDeath(source, killerServerId, weaponHash)
end)

RegisterNetEvent('cursor_arena:server:activity', function()
    local lobby = Arena.GetPlayerLobby(source)
    if lobby and lobby.players[source] then
        lobby.players[source].lastActivity = os.time()
    end
end)

RegisterNetEvent('cursor_arena:server:setHub', function(state)
    Arena.PlayerHub[source] = state == true or nil
end)

local function findCommand(name)
    for i = 1, #Config.Commands do
        if Config.Commands[i].name == name then
            return Config.Commands[i]
        end
    end
end

local arenasCmd = findCommand('arenas')
if not arenasCmd or arenasCmd.enable ~= false then
    lib.addCommand('arenas', {
        help = 'Open the arena lobby browser',
    }, function(source)
        TriggerClientEvent('cursor_arena:client:openUI', source)
    end)
end

local leaveCmd = findCommand('leavearena')
if not leaveCmd or leaveCmd.enable ~= false then
    lib.addCommand('leavearena', {
        help = 'Leave match, or exit the spawn lobby to the city',
    }, function(source)
        if Arena.PlayerLobby[source] then
            Arena.LeaveLobby(source, false, true)
        elseif Arena.PlayerHub[source] then
            TriggerClientEvent('cursor_arena:client:exitHub', source)
        end
    end)
end

lib.addCommand('changeloadout', {
    help = 'Change your arena loadout',
}, function(source)
    TriggerClientEvent('cursor_arena:client:openLoadout', source)
end)

if Config.Announcements and Config.Announcements.enabled then
    CreateThread(function()
        while true do
            Wait(Config.Announcements.interval or 300000)
            local n = 0
            for src in pairs(Arena.PlayerLobby) do
                if src then n = n + 1 end
            end
            if n > 0 then
                TriggerClientEvent('ox_lib:notify', -1, {
                    type = 'inform',
                    description = L('announcement', tostring(n)),
                })
            end
        end
    end)
end

exports('IsPlayerInArena', function(src)
    return Arena.PlayerLobby[src] ~= nil
end)

exports('IsInArena', function(src)
    return Arena.PlayerLobby[src] ~= nil
end)

exports('GetPlayerArena', function(src)
    local lobby = Arena.GetPlayerLobby(src)
    if not lobby then return end
    local p = lobby.players[src]
    return {
        lobby = lobby.id,
        mode = lobby.mode,
        team = p and p.team,
        joinedAt = p and p.joinedAt,
    }
end)

exports('GetArenaPlayers', function()
    local list = {}
    for src in pairs(Arena.PlayerLobby) do
        list[#list + 1] = src
    end
    return list
end)

exports('RemovePlayerFromArena', function(src)
    return Arena.LeaveLobby(src, true, true)
end)

exports('IsInHub', function(src)
    return Arena.PlayerHub[src] == true
end)

exports('LeaveArena', function(src)
    return Arena.LeaveLobby(src, true, true)
end)
