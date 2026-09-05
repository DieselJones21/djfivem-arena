Arena = Arena or {}

local function bootstrap(src)
    Arena.PlayerLobby = Arena.PlayerLobby or {}
    Arena.PlayerHub = Arena.PlayerHub or {}
    Arena.Lobbies = Arena.Lobbies or {}

    local lobby = Arena.GetPlayerLobby and Arena.GetPlayerLobby(src)
    local stats = Arena.Stats and Arena.Stats.GetAllModes and Arena.Stats.GetAllModes(src) or {}
    return {
        playerId = src,
        playerName = Arena.Framework and Arena.Framework.GetName and Arena.Framework.GetName(src) or GetPlayerName(src),
        framework = Arena.Framework and Arena.Framework.name or 'standalone',
        loadouts = Arena.Shop and Arena.Shop.SerializeLoadouts and Arena.Shop.SerializeLoadouts(src) or {},
        shop = Arena.Shop and Arena.Shop.Catalog and Arena.Shop.Catalog(src) or {},
        coins = Arena.Donator and Arena.Donator.GetBalance and Arena.Donator.GetBalance(src) or 0,
        coinLabel = Arena.Donator and Arena.Donator.Label and Arena.Donator.Label() or 'Coins',
        maps = Arena.Utils and Arena.Utils.SerializeMaps and Arena.Utils.SerializeMaps() or {},
        lobbies = Arena.ListLobbies and Arena.ListLobbies(src) or {},
        private = Config.PrivateLobbies,
        stats = stats,
        leaderboard = {
            ffa = Arena.Stats and Arena.Stats.GetLeaderboard and Arena.Stats.GetLeaderboard('ffa', 25) or {},
            tdm = Arena.Stats and Arena.Stats.GetLeaderboard and Arena.Stats.GetLeaderboard('tdm', 25) or {},
            pvp = Arena.Stats and Arena.Stats.GetLeaderboard and Arena.Stats.GetLeaderboard('pvp', 25) or {},
            showdown = Arena.Stats and Arena.Stats.GetLeaderboard and Arena.Stats.GetLeaderboard('showdown', 25) or {},
        },
        history = Arena.Stats and Arena.Stats.GetHistory and Arena.Stats.GetHistory(src, 20) or {},
        inHub = Arena.EnsurePlayerHub(src),
        current = lobby and Arena.PublicLobby and Arena.PublicLobby(lobby, src) or nil,
        titles = Config.LeaderboardTitles,
        sounds = Config.Sounds,
        killstreakStyle = Config.KillstreakStyle,
    }
end

lib.callback.register('cursor_arena:getBootstrap', function(source)
    local ok, result = pcall(bootstrap, source)
    if ok then return result end
    print(('[cursor_arena] getBootstrap failed: %s'):format(result))
    return {
        playerId = source,
        playerName = GetPlayerName(source) or 'Player',
        framework = 'standalone',
        loadouts = {},
        shop = {},
        coins = 0,
        coinLabel = 'Coins',
        maps = Arena.Utils and Arena.Utils.SerializeMaps and Arena.Utils.SerializeMaps() or {},
        lobbies = {},
        private = Config.PrivateLobbies,
        stats = {},
        leaderboard = { ffa = {}, tdm = {}, pvp = {}, showdown = {} },
        history = {},
        inHub = true,
        current = nil,
        titles = Config.LeaderboardTitles,
        sounds = Config.Sounds,
        killstreakStyle = Config.KillstreakStyle,
    }
end)

lib.callback.register('cursor_arena:listLobbies', function(source)
    local ok, list = pcall(function()
        return Arena.ListLobbies(source)
    end)
    if ok then return list or {} end
    print(('[cursor_arena] listLobbies failed: %s'):format(list))
    return {}
end)

lib.callback.register('cursor_arena:getLobby', function(source, lobbyId)
    local lobby = Arena.Lobbies[lobbyId]
    if not lobby then return end
    if lobby.private and source ~= lobby.owner and not lobby.players[source] then
        return
    end
    return Arena.PublicLobby(lobby, source)
end)

lib.callback.register('cursor_arena:createPrivate', function(source, data)
    data = data or {}
    if Arena.AdmitFromTablet then Arena.AdmitFromTablet(source) end
    local ok, result = Arena.CreatePrivate(source, data)
    if not ok then
        return { ok = false, error = result, message = L(result or 'cannot_join') }
    end
    return { ok = true, lobby = result }
end)

lib.callback.register('cursor_arena:joinByCode', function(source, data)
    data = data or {}
    if Arena.AdmitFromTablet then Arena.AdmitFromTablet(source) end
    local ok, result = Arena.JoinByCode(source, data.code, {
        team = data.team,
        loadoutId = data.loadoutId,
        weaponId = data.weaponId,
    })
    if not ok then
        return { ok = false, error = result, message = L(result or 'bad_code') }
    end
    return { ok = true, lobby = result }
end)

lib.callback.register('cursor_arena:watchByCode', function(source, data)
    data = data or {}
    if Arena.AdmitFromTablet then Arena.AdmitFromTablet(source) end
    local ok, result = Arena.WatchByCode(source, data and data.code)
    if not ok then
        return { ok = false, message = L(result or 'bad_code') }
    end
    return { ok = true, lobby = result }
end)

lib.callback.register('cursor_arena:joinLobby', function(source, data)
    data = data or {}
    if Arena.AdmitFromTablet then Arena.AdmitFromTablet(source) end
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

lib.callback.register('cursor_arena:watchLobby', function(source, lobbyId)
    if Arena.AdmitFromTablet then Arena.AdmitFromTablet(source) end
    local ok, result = Arena.Watch.Join(source, lobbyId)
    if not ok then
        return { ok = false, message = L(result or 'cannot_join') }
    end
    return { ok = true, lobby = result }
end)

lib.callback.register('cursor_arena:placeBet', function(source, data)
    data = data or {}
    local ok, err = Arena.Bets.Place(source, data.lobbyId, data)
    if not ok then
        return { ok = false, message = L(err or 'bet_invalid') }
    end
    return { ok = true, bets = Arena.Bets.List(data.lobbyId) }
end)

lib.callback.register('cursor_arena:betItems', function(source)
    return Arena.Bets.ListItems(source)
end)

lib.callback.register('cursor_arena:myMoney', function(source)
    return { cash = Arena.Framework.GetMoney(source), max = (Config.Betting and Config.Betting.maxCash) or 100000 }
end)

RegisterNetEvent('cursor_arena:server:watchLeave', function()
    Arena.Watch.Leave(source, false)
end)

RegisterNetEvent('cursor_arena:server:playerDied', function(killerServerId, weaponHash, headshot)
    Arena.OnPlayerDeath(source, killerServerId, weaponHash, headshot == true)
end)

RegisterNetEvent('cursor_arena:server:headshot', function(victimSrc)
    local src = source
    victimSrc = tonumber(victimSrc)
    if not victimSrc then return end
    local lobby = Arena.GetPlayerLobby(src)
    if not lobby or lobby.state ~= 'active' then return end
    if src == victimSrc then return end
    if not lobby.players[victimSrc] then return end
    TriggerClientEvent('cursor_arena:client:forceHeadshot', victimSrc)
end)

RegisterNetEvent('cursor_arena:server:activity', function()
    local lobby = Arena.GetPlayerLobby(source)
    if lobby and lobby.players[source] then
        lobby.players[source].lastActivity = os.time()
    end
end)

RegisterNetEvent('cursor_arena:server:setHub', function(state)
    Arena.PlayerHub = Arena.PlayerHub or {}
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
        if Arena.PlayerLobby and Arena.PlayerLobby[source] then
            Arena.LeaveLobby(source, false, true)
        elseif Arena.PlayerHub and Arena.PlayerHub[source] then
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
            for src in pairs(Arena.PlayerLobby or {}) do
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
    return Arena.PlayerLobby and Arena.PlayerLobby[src] ~= nil
end)

exports('IsInArena', function(src)
    return Arena.PlayerLobby and Arena.PlayerLobby[src] ~= nil
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
    for src in pairs(Arena.PlayerLobby or {}) do
        list[#list + 1] = src
    end
    return list
end)

exports('RemovePlayerFromArena', function(src)
    return Arena.LeaveLobby(src, true, true)
end)

exports('IsInHub', function(src)
    return Arena.EnsurePlayerHub and Arena.EnsurePlayerHub(src) or (Arena.PlayerHub and Arena.PlayerHub[src] == true)
end)

exports('LeaveArena', function(src)
    return Arena.LeaveLobby(src, true, true)
end)
