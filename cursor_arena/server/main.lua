Arena = Arena or {}
Arena.PlayerHub = Arena.PlayerHub or {}

local function requireHub(src)
    if not Arena.PlayerHub[src] then
        return false, 'must_be_in_hub'
    end
    return true
end

local function bootstrapPayload(src)
    local stats = Arena.Stats and Arena.Stats.GetPlayer(src) or { kills = 0, deaths = 0, elo = 1000, wins = 0 }
    return {
        modes = Arena.Utils.SerializeModes(),
        maps = Arena.Utils.SerializeMaps(),
        weapons = (function()
            local all = {}
            for catId, cat in pairs(Config.WeaponCategories) do
                all[catId] = {
                    label = cat.label,
                    weapons = cat.weapons,
                }
            end
            return all
        end)(),
        choiceCategories = Config.ChoiceCategories,
        lobby = {
            command = Config.Command,
            openKey = Config.MenuKey or 'G',
        },
        locale = Config.Locale,
        playerId = src,
        playerName = Arena.Framework.GetName(src),
        inHub = Arena.PlayerHub[src] == true,
        inMatch = Arena.PlayerMatch[src] ~= nil,
        queue = Arena.GetQueueStatus(src),
        openLobbies = Arena.ListOpenLobbies(),
        stats = stats,
        leaderboard = Arena.Stats and Arena.Stats.GetLeaderboard(25) or {},
    }
end

RegisterNetEvent('cursor_arena:server:setHub', function(state)
    local src = source
    Arena.PlayerHub[src] = state == true or nil
end)

lib.callback.register('cursor_arena:getBootstrap', function(source)
    return bootstrapPayload(source)
end)

lib.callback.register('cursor_arena:getWeaponsForMode', function(_, modeId)
    local mode = Config.GetMode(modeId)
    return Config.GetWeaponsForMode(mode)
end)

lib.callback.register('cursor_arena:getMapsForMode', function(_, modeId)
    local maps = Config.GetMapsForMode(modeId)
    local out = {}
    for i = 1, #maps do
        out[#out + 1] = {
            id = maps[i].id,
            label = maps[i].label,
            description = maps[i].description,
            image = maps[i].image,
        }
    end
    return out
end)

lib.callback.register('cursor_arena:joinQueue', function(source, modeId, weaponId, mapId)
    local hubOk, hubErr = requireHub(source)
    if not hubOk then
        return { ok = false, error = hubErr, message = L(hubErr) }
    end
    local ok, result = Arena.JoinQueue(source, modeId, weaponId, mapId)
    if not ok then
        return { ok = false, error = result, message = L(result) }
    end
    return { ok = true, data = result }
end)

lib.callback.register('cursor_arena:leaveQueue', function(source)
    Arena.LeaveQueue(source)
    return true
end)

lib.callback.register('cursor_arena:createPrivate', function(source, modeId, mapId, weaponId)
    local hubOk, hubErr = requireHub(source)
    if not hubOk then
        return { ok = false, error = hubErr, message = L(hubErr) }
    end
    local ok, result = Arena.CreatePrivateLobby(source, modeId, mapId, weaponId)
    if not ok then
        return { ok = false, error = result, message = L(result) }
    end
    return { ok = true, lobby = result }
end)

lib.callback.register('cursor_arena:createLobby', function(source, data)
    local hubOk, hubErr = requireHub(source)
    if not hubOk then
        return { ok = false, error = hubErr, message = L(hubErr) }
    end
    local ok, result = Arena.CreateLobbyFromUI(source, data)
    if not ok then
        return { ok = false, error = result, message = L(result or 'error') }
    end
    return { ok = true, lobby = result }
end)

lib.callback.register('cursor_arena:getLeaderboard', function()
    return Arena.Stats and Arena.Stats.GetLeaderboard(50) or {}
end)

lib.callback.register('cursor_arena:getMyStats', function(source)
    return Arena.Stats and Arena.Stats.GetPlayer(source) or {}
end)

lib.callback.register('cursor_arena:getWeaponsForClass', function(_, classId)
    local cat = Config.WeaponCategories[classId]
    if not cat then return {} end
    local list = {}
    for i = 1, #cat.weapons do
        local w = cat.weapons[i]
        list[#list + 1] = {
            id = w.id,
            label = w.label,
            weapon = w.weapon,
            ammo = w.ammo,
            category = classId,
            categoryLabel = cat.label,
        }
    end
    return list
end)

lib.callback.register('cursor_arena:joinLobby', function(source, matchId, weaponId)
    local hubOk, hubErr = requireHub(source)
    if not hubOk then
        return { ok = false, error = hubErr, message = L(hubErr) }
    end
    local ok, result = Arena.JoinMatch(source, matchId, weaponId)
    if not ok then
        return { ok = false, error = result, message = L(result) }
    end
    return { ok = true, lobby = result }
end)

lib.callback.register('cursor_arena:setReady', function(source, ready, weaponId)
    local ok, result = Arena.SetReady(source, ready, weaponId)
    if not ok then
        return { ok = false, error = result or 'error', message = L(result or 'need_weapon') }
    end
    return { ok = true, lobby = result }
end)

lib.callback.register('cursor_arena:setTeam', function(source, team)
    local ok, err = Arena.SetTeam(source, team)
    if not ok then
        return { ok = false, error = err, message = L(err or 'lobby_full') }
    end
    return { ok = true }
end)

lib.callback.register('cursor_arena:startMatch', function(source)
    local match = Arena.GetPlayerMatch(source)
    if not match then return { ok = false, message = 'Not in a lobby' } end
    if match.host ~= source and not IsPlayerAceAllowed(source, Config.Permissions.forceStartAce) then
        return { ok = false, message = L('no_permission') }
    end
    local ok, err = Arena.StartMatch(match.id)
    if not ok then
        return { ok = false, error = err, message = L(err or 'not_enough_players') }
    end
    return { ok = true }
end)

lib.callback.register('cursor_arena:leave', function(source)
    Arena.LeaveQueue(source)
    Arena.LeaveMatch(source, false)
    return true
end)

lib.callback.register('cursor_arena:listLobbies', function()
    return Arena.ListOpenLobbies()
end)

lib.callback.register('cursor_arena:getLobby', function(source)
    local match = Arena.GetPlayerMatch(source)
    if not match then return nil end
    return Arena.GetPublicLobby(match.id)
end)

RegisterNetEvent('cursor_arena:server:playerDied', function(killerServerId, weaponHash)
    local src = source
    Arena.OnPlayerDeath(src, killerServerId, weaponHash)
end)

RegisterNetEvent('cursor_arena:server:invite', function(targetId)
    local src = source
    local match = Arena.GetPlayerMatch(src)
    if not match or match.state ~= 'lobby' then return end
    targetId = tonumber(targetId)
    if not targetId or not GetPlayerName(targetId) then return end

    TriggerClientEvent('cursor_arena:client:invite', targetId, {
        from = Arena.Framework.GetName(src),
        fromId = src,
        matchId = match.id,
        modeLabel = match.mode.label,
        mapLabel = match.map.label,
        timeout = Config.InviteTimeout,
    })

    Arena.Utils.Notify(src, { type = 'inform', description = L('invite_sent') })
end)

lib.addCommand(Config.Command, {
    help = 'Enter the arena spawn lobby (or open UI if already inside)',
}, function(source)
    TriggerClientEvent('cursor_arena:client:openUI', source)
end)

lib.addCommand('arena_leave', {
    help = 'Leave match/queue, or exit the spawn lobby to the city',
}, function(source)
    Arena.LeaveQueue(source)
    if Arena.PlayerMatch[source] then
        Arena.LeaveMatch(source, false)
        Arena.Utils.Notify(source, { type = 'inform', description = L('left_match') })
    elseif Arena.PlayerHub[source] then
        TriggerClientEvent('cursor_arena:client:exitHub', source)
    end
end)

AddEventHandler('playerDropped', function()
    Arena.PlayerHub[source] = nil
end)

lib.addCommand('arena_forcestart', {
    help = 'Force start your current arena lobby',
    restricted = Config.Permissions.forceStartAce,
}, function(source)
    local match = Arena.GetPlayerMatch(source)
    if not match then return end
    Arena.StartMatch(match.id, true)
end)

-- Export API for other resources
exports('IsInArena', function(src)
    return Arena.PlayerMatch[src] ~= nil
end)

exports('IsInHub', function(src)
    return Arena.PlayerHub[src] == true
end)

exports('GetMatchId', function(src)
    return Arena.PlayerMatch[src]
end)

exports('LeaveArena', function(src)
    Arena.LeaveQueue(src)
    return Arena.LeaveMatch(src, true)
end)
