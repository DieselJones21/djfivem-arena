Arena = Arena or {}
Arena.Matches = {}          -- [matchId] = match table
Arena.PlayerMatch = {}      -- [src] = matchId

local matchSeq = 0

local function nextMatchId()
    matchSeq = matchSeq + 1
    return ('m_%s_%s'):format(os.time(), matchSeq)
end

local function getWeaponDef(weaponId)
    local def = Config.FindWeapon(weaponId)
    return def
end

local function broadcast(match, event, ...)
    for src in pairs(match.players) do
        TriggerClientEvent(event, src, ...)
    end
end

local function publicLobby(match)
    local players = {}
    for src, p in pairs(match.players) do
        players[#players + 1] = {
            id = src,
            name = p.name,
            team = p.team,
            ready = p.ready,
            weapon = p.weapon,
            kills = p.kills,
            deaths = p.deaths,
        }
    end

    return {
        id = match.id,
        modeId = match.mode.id,
        modeLabel = match.mode.label,
        modeType = match.mode.type,
        mapId = match.map.id,
        mapLabel = match.map.label,
        host = match.host,
        private = match.private,
        state = match.state,
        players = players,
        maxPlayers = match.mode.maxPlayers,
        minPlayers = match.mode.minPlayers,
        scoreLimit = match.mode.scoreLimit,
        timeLimit = match.mode.timeLimit,
        teamSize = match.mode.teamSize,
        scores = match.scores,
        round = match.round,
        endsAt = match.endsAt,
        allowWeaponChoice = match.mode.allowWeaponChoice,
        weapons = Config.GetWeaponsForMode(match.mode),
    }
end

function Arena.GetPublicLobby(matchId)
    local match = Arena.Matches[matchId]
    if not match then return end
    return publicLobby(match)
end

function Arena.GetPlayerMatch(src)
    local id = Arena.PlayerMatch[src]
    if not id then return end
    return Arena.Matches[id]
end

local function countPlayers(match)
    return Arena.Utils.TableSize(match.players)
end

local function countTeam(match, team)
    local n = 0
    for _, p in pairs(match.players) do
        if p.team == team then n = n + 1 end
    end
    return n
end

local function assignTeam(match, src)
    if not Arena.Utils.IsTeamMode(match.mode) then
        match.players[src].team = 'ffa'
        return
    end

    local red = countTeam(match, 'red')
    local blue = countTeam(match, 'blue')
    local teamSize = match.mode.teamSize

    if teamSize then
        if red < teamSize and red <= blue then
            match.players[src].team = 'red'
        else
            match.players[src].team = 'blue'
        end
    else
        match.players[src].team = red <= blue and 'red' or 'blue'
    end
end

local function everyoneReady(match)
    for _, p in pairs(match.players) do
        if not p.ready or not p.weapon then
            return false
        end
    end
    return countPlayers(match) >= match.mode.minPlayers
end

local function syncLobby(match)
    local data = publicLobby(match)
    broadcast(match, 'cursor_arena:client:lobbyUpdate', data)
    TriggerEvent('cursor_arena:lobbyUpdated', match.id)
end

function Arena.CreateMatch(host, modeId, mapId, opts)
    opts = opts or {}
    local mode = Config.GetMode(modeId)
    local map = Config.GetMap(mapId)
    if not mode or not map then return nil, 'invalid_mode_map' end

    local active = Arena.Utils.TableSize(Arena.Matches)
    if active >= Config.MaxActiveMatches then
        return nil, 'max_matches'
    end

    local id = nextMatchId()
    local match = {
        id = id,
        mode = mode,
        map = map,
        host = host,
        private = opts.private == true,
        state = 'lobby', -- lobby | countdown | active | ended
        players = {},
        scores = { red = 0, blue = 0 },
        round = 1,
        endsAt = nil,
        createdAt = os.time(),
        usedSpawns = {},
    }

    Arena.Matches[id] = match
    Arena.Utils.Debug('Created match', id, modeId, mapId)
    return match
end

function Arena.JoinMatch(src, matchId, weaponId)
    if Arena.PlayerMatch[src] then
        return false, 'already_in_match'
    end

    local match = Arena.Matches[matchId]
    if not match then return false, 'not_found' end
    if match.state ~= 'lobby' then return false, 'lobby_started' end
    if countPlayers(match) >= match.mode.maxPlayers then return false, 'lobby_full' end

    if Config.RequireItem then
        if not Arena.Framework.HasItem(src, Config.RequireItem, 1) then
            return false, 'need_item'
        end
    end

    local weapon = nil
    if weaponId then
        weapon = getWeaponDef(weaponId)
        if not weapon then return false, 'invalid_weapon' end
        local allowed = Config.GetWeaponsForMode(match.mode)
        local ok = false
        for i = 1, #allowed do
            if allowed[i].id == weaponId then ok = true break end
        end
        if not ok then return false, 'invalid_weapon' end
    elseif not match.mode.allowWeaponChoice then
        local allowed = Config.GetWeaponsForMode(match.mode)
        if allowed[1] then
            weapon = getWeaponDef(allowed[1].id)
            weaponId = allowed[1].id
        end
    end

    match.players[src] = {
        name = Arena.Framework.GetName(src),
        team = 'ffa',
        ready = weapon ~= nil,
        weapon = weaponId,
        kills = 0,
        deaths = 0,
        alive = true,
    }
    assignTeam(match, src)
    Arena.PlayerMatch[src] = matchId

    syncLobby(match)
    return true, publicLobby(match)
end

function Arena.SetReady(src, ready, weaponId)
    local match = Arena.GetPlayerMatch(src)
    if not match or match.state ~= 'lobby' then return false end

    if weaponId then
        local weapon = getWeaponDef(weaponId)
        if not weapon then return false, 'invalid_weapon' end
        local allowed = Config.GetWeaponsForMode(match.mode)
        local ok = false
        for i = 1, #allowed do
            if allowed[i].id == weaponId then ok = true break end
        end
        if not ok then return false, 'invalid_weapon' end
        match.players[src].weapon = weaponId
    end

    if ready and not match.players[src].weapon then
        return false, 'need_weapon'
    end

    match.players[src].ready = ready == true
    syncLobby(match)

    if everyoneReady(match) and (match.host == src or not match.private) then
        -- Auto-start when full & ready for public queues
        if countPlayers(match) >= match.mode.minPlayers then
            if match.private then
                -- private: only host can start via StartMatch
            else
                Arena.StartMatch(match.id)
            end
        end
    end

    return true, publicLobby(match)
end

function Arena.SetTeam(src, team)
    local match = Arena.GetPlayerMatch(src)
    if not match or match.state ~= 'lobby' then return false end
    if not Arena.Utils.IsTeamMode(match.mode) then return false end
    if team ~= 'red' and team ~= 'blue' then return false end

    if match.mode.teamSize and countTeam(match, team) >= match.mode.teamSize then
        if match.players[src].team ~= team then
            return false, 'lobby_full'
        end
    end

    match.players[src].team = team
    syncLobby(match)
    return true
end

local function teleportPlayers(match)
    match.usedSpawns = { ffa = {}, red = {}, blue = {} }

    for src, p in pairs(match.players) do
        local spawn
        if Arena.Utils.IsTeamMode(match.mode) then
            local teamSpawns = match.map.spawns.team and match.map.spawns.team[p.team]
            spawn = Arena.Utils.PickSpawn(teamSpawns, match.usedSpawns[p.team])
        else
            spawn = Arena.Utils.PickSpawn(match.map.spawns.ffa, match.usedSpawns.ffa)
        end

        if not spawn then
            spawn = vec4(match.map.center.x, match.map.center.y, match.map.center.z, match.map.heading or 0.0)
        end

        p.spawn = spawn
        p.alive = true
    end
end

local function preparePlayer(src, match)
    local p = match.players[src]
    local weapon = getWeaponDef(p.weapon)

    Arena.Ambulance.SetArenaState(src, true)
    Arena.Inventory.StashPlayer(src)
    Arena.Inventory.GiveLoadout(src, weapon)

    TriggerClientEvent('cursor_arena:client:enterMatch', src, {
        matchId = match.id,
        mode = {
            id = match.mode.id,
            label = match.mode.label,
            type = match.mode.type,
            scoreLimit = match.mode.scoreLimit,
            timeLimit = match.mode.timeLimit,
            respawn = match.mode.respawn,
            friendlyFire = match.mode.friendlyFire,
        },
        map = {
            id = match.map.id,
            label = match.map.label,
            center = { x = match.map.center.x, y = match.map.center.y, z = match.map.center.z },
            radius = match.map.radius,
        },
        team = p.team,
        spawn = { x = p.spawn.x, y = p.spawn.y, z = p.spawn.z, w = p.spawn.w },
        weapon = p.weapon,
        rules = Config.Rules,
        hud = Config.HUD,
        respawnDelay = Config.RespawnDelay,
    })
end

local function endMatch(match, result)
    if match.state == 'ended' then return end
    match.state = 'ended'
    match.result = result

    local winnerTeam = result.winnerTeam
    local winnerSrc = result.winnerSrc

    for src, p in pairs(match.players) do
        local outcome = 'draw'
        if winnerSrc and winnerSrc == src then
            outcome = 'win'
        elseif winnerTeam and p.team == winnerTeam then
            outcome = 'win'
        elseif winnerTeam or winnerSrc then
            outcome = 'loss'
        end

        if Config.Rewards.enabled then
            local reward = Config.Rewards[outcome == 'win' and 'win' or (outcome == 'loss' and 'loss' or nil)]
            if reward and reward.money then
                Arena.Framework.AddMoney(src, reward.money)
            end
        end

        TriggerClientEvent('cursor_arena:client:matchEnded', src, {
            outcome = outcome,
            result = result,
            scores = match.scores,
            players = publicLobby(match).players,
        })
    end

    if Config.Logging.enabled and Config.Logging.logMatchEnd and Config.Logging.webhook ~= '' then
        -- optional webhook omitted to keep dependency-free
    end

    SetTimeout(4000, function()
        for src in pairs(match.players) do
            Arena.LeaveMatch(src, true)
        end
        Arena.Matches[match.id] = nil
    end)
end

local function checkScoreWin(match)
    local mode = match.mode

    if mode.type == 'ffa' then
        local bestSrc, bestKills = nil, -1
        for src, p in pairs(match.players) do
            if p.kills > bestKills then
                bestKills = p.kills
                bestSrc = src
            end
        end
        if bestKills >= (mode.scoreLimit or 9999) then
            endMatch(match, {
                reason = 'score',
                winnerSrc = bestSrc,
                winnerName = match.players[bestSrc] and match.players[bestSrc].name,
            })
            return true
        end
    elseif mode.type == 'tdm' then
        if match.scores.red >= (mode.scoreLimit or 9999) then
            endMatch(match, { reason = 'score', winnerTeam = 'red' })
            return true
        end
        if match.scores.blue >= (mode.scoreLimit or 9999) then
            endMatch(match, { reason = 'score', winnerTeam = 'blue' })
            return true
        end
    elseif mode.type == 'team' then
        -- scoreLimit = rounds won
        if match.scores.red >= (mode.scoreLimit or 9999) then
            endMatch(match, { reason = 'rounds', winnerTeam = 'red' })
            return true
        end
        if match.scores.blue >= (mode.scoreLimit or 9999) then
            endMatch(match, { reason = 'rounds', winnerTeam = 'blue' })
            return true
        end
    end
    return false
end

local function startRoundTimer(match)
    local limit = match.mode.timeLimit or Config.DefaultRoundTime
    match.endsAt = os.time() + limit

    broadcast(match, 'cursor_arena:client:timer', match.endsAt, limit)

    local matchId = match.id
    local endsAt = match.endsAt

    CreateThread(function()
        while Arena.Matches[matchId] and Arena.Matches[matchId].endsAt == endsAt do
            local m = Arena.Matches[matchId]
            if m.state ~= 'active' then return end
            if os.time() >= endsAt then
                if m.mode.type == 'team' and m.mode.respawn == false then
                    -- time expired mid-round: no round point
                    Arena.NextRound(m.id, nil)
                else
                    -- time limit: highest score wins
                    if m.mode.type == 'ffa' then
                        local bestSrc, bestKills = nil, -1
                        local tie = false
                        for src, p in pairs(m.players) do
                            if p.kills > bestKills then
                                bestKills = p.kills
                                bestSrc = src
                                tie = false
                            elseif p.kills == bestKills then
                                tie = true
                            end
                        end
                        if tie then
                            endMatch(m, { reason = 'time', draw = true })
                        else
                            endMatch(m, {
                                reason = 'time',
                                winnerSrc = bestSrc,
                                winnerName = m.players[bestSrc] and m.players[bestSrc].name,
                            })
                        end
                    else
                        if m.scores.red == m.scores.blue then
                            endMatch(m, { reason = 'time', draw = true })
                        else
                            endMatch(m, {
                                reason = 'time',
                                winnerTeam = m.scores.red > m.scores.blue and 'red' or 'blue',
                            })
                        end
                    end
                end
                return
            end
            Wait(1000)
        end
    end)
end

function Arena.StartMatch(matchId, forced)
    local match = Arena.Matches[matchId]
    if not match or match.state ~= 'lobby' then return false end

    if countPlayers(match) < match.mode.minPlayers and not forced then
        return false, 'not_enough_players'
    end

    for _, p in pairs(match.players) do
        if not p.weapon then
            return false, 'need_weapon'
        end
    end

    if Arena.Utils.IsTeamMode(match.mode) and match.mode.teamSize then
        if countTeam(match, 'red') < 1 or countTeam(match, 'blue') < 1 then
            return false, 'not_enough_players'
        end
    end

    match.state = 'countdown'
    teleportPlayers(match)

    for src in pairs(match.players) do
        preparePlayer(src, match)
    end

    broadcast(match, 'cursor_arena:client:countdown', Config.CountdownSeconds)
    syncLobby(match)

    local id = match.id
    SetTimeout(Config.CountdownSeconds * 1000, function()
        local m = Arena.Matches[id]
        if not m or m.state ~= 'countdown' then return end
        m.state = 'active'
        m.scores = { red = 0, blue = 0 }
        m.round = 1
        startRoundTimer(m)
        broadcast(m, 'cursor_arena:client:matchActive', publicLobby(m))
    end)

    return true
end

function Arena.NextRound(matchId, winnerTeam)
    local match = Arena.Matches[matchId]
    if not match or match.state ~= 'active' then return end

    if winnerTeam then
        match.scores[winnerTeam] = (match.scores[winnerTeam] or 0) + 1
    end

    if checkScoreWin(match) then return end

    match.round = match.round + 1
    teleportPlayers(match)

    for src, p in pairs(match.players) do
        p.alive = true
        local weapon = getWeaponDef(p.weapon)
        Arena.Inventory.ClearLoadout(src)
        Arena.Inventory.GiveLoadout(src, weapon)
        TriggerClientEvent('cursor_arena:client:roundRestart', src, {
            round = match.round,
            spawn = { x = p.spawn.x, y = p.spawn.y, z = p.spawn.z, w = p.spawn.w },
            scores = match.scores,
        })
        Arena.Ambulance.Revive(src, p.spawn)
    end

    broadcast(match, 'cursor_arena:client:countdown', Config.CountdownSeconds)
    SetTimeout(Config.CountdownSeconds * 1000, function()
        local m = Arena.Matches[matchId]
        if not m or m.state ~= 'active' then return end
        startRoundTimer(m)
        broadcast(m, 'cursor_arena:client:matchActive', publicLobby(m))
    end)
end

local function livingOnTeam(match, team)
    local n = 0
    for _, p in pairs(match.players) do
        if p.team == team and p.alive then n = n + 1 end
    end
    return n
end

function Arena.OnPlayerDeath(victim, killer, weaponHash)
    local match = Arena.GetPlayerMatch(victim)
    if not match or match.state ~= 'active' then return end

    local vp = match.players[victim]
    if not vp or not vp.alive then return end

    vp.alive = false
    vp.deaths = vp.deaths + 1

    local killerSrc = killer
    if killerSrc and killerSrc > 0 and match.players[killerSrc] and killerSrc ~= victim then
        local kp = match.players[killerSrc]
        -- friendly fire check for team modes
        if Arena.Utils.IsTeamMode(match.mode) and kp.team == vp.team and match.mode.friendlyFire == false then
            -- no kill credit
        else
            kp.kills = kp.kills + 1
            if match.mode.type == 'tdm' then
                match.scores[kp.team] = (match.scores[kp.team] or 0) + 1
            end

            if Config.Rewards.enabled and Config.Rewards.kill and Config.Rewards.kill.money then
                Arena.Framework.AddMoney(killerSrc, Config.Rewards.kill.money)
            end

            if Config.Rules.healOnKill or Config.Rules.armorOnKill then
                TriggerClientEvent('cursor_arena:client:killReward', killerSrc, {
                    heal = Config.Rules.healOnKill and Config.Rules.healOnKillAmount or 0,
                    armor = Config.Rules.armorOnKill and Config.Rules.armorOnKillAmount or 0,
                })
            end
        end
    end

    broadcast(match, 'cursor_arena:client:killfeed', {
        victim = vp.name,
        victimId = victim,
        killer = killerSrc and match.players[killerSrc] and match.players[killerSrc].name or nil,
        killerId = killerSrc,
        scores = match.scores,
        players = publicLobby(match).players,
    })

    -- Round-based elimination (1v1 / 2v2 without respawn)
    if match.mode.type == 'team' and match.mode.respawn == false then
        local redAlive = livingOnTeam(match, 'red')
        local blueAlive = livingOnTeam(match, 'blue')
        if redAlive == 0 or blueAlive == 0 then
            local winner = redAlive > 0 and 'red' or 'blue'
            SetTimeout(1500, function()
                Arena.NextRound(match.id, winner)
            end)
            return
        end
    end

    if checkScoreWin(match) then return end

    -- Respawn flow
    if match.mode.respawn ~= false then
        SetTimeout((Config.RespawnDelay or 3) * 1000, function()
            local m = Arena.Matches[match.id]
            if not m or m.state ~= 'active' then return end
            local p = m.players[victim]
            if not p then return end

            local spawn
            if Arena.Utils.IsTeamMode(m.mode) then
                local teamSpawns = m.map.spawns.team and m.map.spawns.team[p.team]
                spawn = Arena.Utils.PickSpawn(teamSpawns, {})
            else
                spawn = Arena.Utils.PickSpawn(m.map.spawns.ffa, {})
            end
            if not spawn then
                spawn = vec4(m.map.center.x, m.map.center.y, m.map.center.z, m.map.heading or 0.0)
            end

            p.alive = true
            p.spawn = spawn

            local weapon = getWeaponDef(p.weapon)
            if Config.Rules.refillAmmoOnRespawn then
                Arena.Inventory.RefillAmmo(victim, weapon)
            end

            Arena.Ambulance.Revive(victim, spawn)
            TriggerClientEvent('cursor_arena:client:respawn', victim, {
                spawn = { x = spawn.x, y = spawn.y, z = spawn.z, w = spawn.w },
            })
        end)
    end
end

function Arena.LeaveMatch(src, silent)
    local matchId = Arena.PlayerMatch[src]
    if not matchId then return false end

    local match = Arena.Matches[matchId]
    Arena.PlayerMatch[src] = nil

    Arena.Inventory.ClearLoadout(src)
    if Config.OxInventory.restoreOnLeave then
        Arena.Inventory.RestorePlayer(src)
    end
    Arena.Ambulance.Release(src)

    TriggerClientEvent('cursor_arena:client:leaveMatch', src, {
        returnCoords = Config.ReturnLocation.coords,
        silent = silent == true,
    })

    if match then
        match.players[src] = nil

        if match.state ~= 'ended' then
            local remaining = countPlayers(match)
            if remaining == 0 then
                Arena.Matches[matchId] = nil
            elseif match.state == 'active' or match.state == 'countdown' then
                -- Win by forfeit if one team emptied
                if Arena.Utils.IsTeamMode(match.mode) then
                    local red = countTeam(match, 'red')
                    local blue = countTeam(match, 'blue')
                    if red == 0 or blue == 0 then
                        endMatch(match, {
                            reason = 'forfeit',
                            winnerTeam = red > 0 and 'red' or 'blue',
                        })
                        return true
                    end
                elseif remaining < 2 and match.mode.type == 'ffa' then
                    local winnerSrc = next(match.players)
                    endMatch(match, {
                        reason = 'forfeit',
                        winnerSrc = winnerSrc,
                        winnerName = match.players[winnerSrc] and match.players[winnerSrc].name,
                    })
                    return true
                end
                syncLobby(match)
            else
                if match.host == src then
                    local newHost = next(match.players)
                    match.host = newHost
                end
                syncLobby(match)
            end
        end
    end

    return true
end

-- Idle lobby cleanup
CreateThread(function()
    while true do
        Wait(30000)
        local now = os.time()
        for id, match in pairs(Arena.Matches) do
            if match.state == 'lobby' and countPlayers(match) == 0 then
                if now - (match.createdAt or now) >= Config.LobbyIdleTimeout then
                    Arena.Matches[id] = nil
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    if Arena.PlayerMatch[src] then
        Arena.LeaveMatch(src, true)
    end
end)
