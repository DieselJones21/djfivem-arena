Arena = Arena or {}
Arena.Queues = {} -- [modeId] = { {src, weapon, joinedAt}, ... }

local function queueCount(modeId)
    local q = Arena.Queues[modeId]
    return q and #q or 0
end

local function removeFromAllQueues(src)
    for modeId, q in pairs(Arena.Queues) do
        for i = #q, 1, -1 do
            if q[i].src == src then
                table.remove(q, i)
            end
        end
        if #q == 0 then
            Arena.Queues[modeId] = nil
        end
    end
end

local function pickMapForMode(modeId)
    local maps = Config.GetMapsForMode(modeId)
    if #maps == 0 then return end
    return maps[math.random(#maps)].id
end

local function tryFormMatch(modeId)
    local mode = Config.GetMode(modeId)
    local q = Arena.Queues[modeId]
    if not mode or not q then return end

    while #q >= mode.minPlayers do
        local take = math.min(#q, mode.maxPlayers)

        -- For fixed team sizes, only form when we can fill both sides
        if mode.teamSize then
            local need = mode.teamSize * 2
            if #q < need then break end
            take = need
        end

        local mapId = pickMapForMode(modeId)
        if not mapId then break end

        local host = q[1].src
        local match = Arena.CreateMatch(host, modeId, mapId, { private = false })
        if not match then break end

        local joined = {}
        for i = 1, take do
            local entry = q[1]
            table.remove(q, 1)
            local ok = Arena.JoinMatch(entry.src, match.id, entry.weapon)
            if ok then
                joined[#joined + 1] = entry.src
                Arena.SetReady(entry.src, true, entry.weapon)
            end
        end

        if Arena.Utils.TableSize(match.players) >= mode.minPlayers then
            -- Balance teams for TDM / team modes
            if Arena.Utils.IsTeamMode(mode) then
                local list = {}
                for src in pairs(match.players) do list[#list + 1] = src end
                list = Arena.Utils.Shuffle(list)
                for i = 1, #list do
                    local team = (i % 2 == 1) and 'red' or 'blue'
                    match.players[list[i]].team = team
                end
            end

            for _, src in ipairs(joined) do
                TriggerClientEvent('cursor_arena:client:queueMatched', src, Arena.GetPublicLobby(match.id))
            end

            SetTimeout(1500, function()
                Arena.StartMatch(match.id)
            end)
        else
            -- rollback
            for _, src in ipairs(joined) do
                Arena.LeaveMatch(src, true)
            end
            Arena.Matches[match.id] = nil
            break
        end
    end

    if q and #q == 0 then
        Arena.Queues[modeId] = nil
    end
end

function Arena.JoinQueue(src, modeId, weaponId, mapId)
    if Arena.PlayerMatch[src] then
        return false, 'already_in_match'
    end

    local mode = Config.GetMode(modeId)
    if not mode then return false, 'invalid_mode' end

    if not weaponId then
        return false, 'need_weapon'
    end

    local weapon = Config.FindWeapon(weaponId)
    if not weapon then return false, 'invalid_weapon' end

    local allowed = Config.GetWeaponsForMode(mode)
    local ok = false
    for i = 1, #allowed do
        if allowed[i].id == weaponId then ok = true break end
    end
    if not ok then return false, 'invalid_weapon' end

    removeFromAllQueues(src)

    -- Direct private-style lobby with chosen map if provided & enough to solo create
    if mapId then
        local map = Config.GetMap(mapId)
        if not map then return false, 'invalid_map' end
        local match = Arena.CreateMatch(src, modeId, mapId, { private = false })
        if not match then return false, 'max_matches' end
        local joined, data = Arena.JoinMatch(src, match.id, weaponId)
        if not joined then
            Arena.Matches[match.id] = nil
            return false, data
        end
        Arena.SetReady(src, true, weaponId)
        return true, { type = 'lobby', lobby = Arena.GetPublicLobby(match.id) }
    end

    Arena.Queues[modeId] = Arena.Queues[modeId] or {}
    Arena.Queues[modeId][#Arena.Queues[modeId] + 1] = {
        src = src,
        weapon = weaponId,
        joinedAt = os.time(),
    }

    tryFormMatch(modeId)

    -- If already matched, PlayerMatch will be set
    if Arena.PlayerMatch[src] then
        return true, { type = 'matched', lobby = Arena.GetPublicLobby(Arena.PlayerMatch[src]) }
    end

    return true, {
        type = 'queued',
        modeId = modeId,
        position = queueCount(modeId),
        needed = mode.minPlayers,
    }
end

function Arena.LeaveQueue(src)
    removeFromAllQueues(src)
    return true
end

function Arena.CreatePrivateLobby(src, modeId, mapId, weaponId)
    if Arena.PlayerMatch[src] then
        return false, 'already_in_match'
    end

    if Config.Permissions.createPrivateAce then
        if not IsPlayerAceAllowed(src, Config.Permissions.createPrivateAce) then
            return false, 'no_permission'
        end
    end

    local mode = Config.GetMode(modeId)
    local map = Config.GetMap(mapId)
    if not mode or not map then return false, 'invalid_mode_map' end

    removeFromAllQueues(src)

    local match = Arena.CreateMatch(src, modeId, mapId, { private = true })
    if not match then return false, 'max_matches' end

    local ok, err = Arena.JoinMatch(src, match.id, weaponId)
    if not ok then
        Arena.Matches[match.id] = nil
        return false, err
    end

    if weaponId then
        Arena.SetReady(src, true, weaponId)
    end

    return true, Arena.GetPublicLobby(match.id)
end

function Arena.ListOpenLobbies()
    local list = {}
    for id, match in pairs(Arena.Matches) do
        if match.state == 'lobby' and not match.private then
            list[#list + 1] = Arena.GetPublicLobby(id)
        end
    end
    return list
end

function Arena.GetQueueStatus(src)
    for modeId, q in pairs(Arena.Queues) do
        for i = 1, #q do
            if q[i].src == src then
                local mode = Config.GetMode(modeId)
                return {
                    modeId = modeId,
                    modeLabel = mode and mode.label or modeId,
                    position = i,
                    waiting = #q,
                    needed = mode and mode.minPlayers or 2,
                }
            end
        end
    end
end

AddEventHandler('playerDropped', function()
    removeFromAllQueues(source)
end)
