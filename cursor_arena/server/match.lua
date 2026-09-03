Arena = Arena or {}
Arena.Lobbies = {}
Arena.PlayerLobby = {}
Arena.PlayerHub = {}
Arena.LeaveAt = {}

local matchSeq = 0
local nextBucket = Config.StartingBucket or 100
local voiceSeq = 0

local function nextMatchUid()
    matchSeq = matchSeq + 1
    return ('a_%s_%s'):format(os.time(), matchSeq)
end

local function countPlayers(lobby)
    return Arena.Utils.TableSize(lobby.players)
end

local function countTeam(lobby, team)
    local n = 0
    for _, p in pairs(lobby.players) do
        if p.team == team then n = n + 1 end
    end
    return n
end

local function livingOnTeam(lobby, team)
    local n = 0
    for _, p in pairs(lobby.players) do
        if p.team == team and p.alive then n = n + 1 end
    end
    return n
end

local function maxPlayers(lobby)
    if Arena.Utils.IsTeamMode(lobby.mode) then
        return (lobby.cfg.maxPlayersPerTeam or 8) * 2
    end
    return lobby.cfg.maxPlayers or 16
end

local function broadcast(lobby, event, ...)
    for src in pairs(lobby.players) do
        TriggerClientEvent(event, src, ...)
    end
end

local function setStateBags(src, lobby, p)
    local ply = Player(src)
    if not ply or not ply.state then return end
    if lobby then
        ply.state:set('in_arena', true, true)
        ply.state:set('arena_mode', lobby.mode, true)
        ply.state:set('arena_lobby', lobby.id, true)
        ply.state:set('arena_team', p and p.team or nil, true)
        ply.state:set('arena_down', p and p.alive == false or false, true)
        ply.state:set('arena_spectator', p and p.spectating or false, true)
    else
        ply.state:set('in_arena', false, true)
        ply.state:set('arena_mode', nil, true)
        ply.state:set('arena_lobby', nil, true)
        ply.state:set('arena_team', nil, true)
        ply.state:set('arena_down', false, true)
        ply.state:set('arena_spectator', false, true)
    end
end

local function playerPayload(lobby)
    local players = {}
    for src, p in pairs(lobby.players) do
        players[#players + 1] = {
            id = src,
            name = p.name,
            team = p.team,
            kills = p.kills,
            deaths = p.deaths,
            alive = p.alive,
            loadout = p.loadoutId,
            weapon = p.weaponId,
            title = p.title,
        }
    end
    table.sort(players, function(a, b) return a.kills > b.kills end)
    return players
end

function Arena.PublicLobby(lobby)
    local map = lobby.map
    local cfg = lobby.cfg
    return {
        id = lobby.id,
        name = cfg.name,
        description = cfg.description,
        mode = lobby.mode,
        mapId = map.id,
        mapName = map.name,
        mapImage = map.image,
        maxPlayers = maxPlayers(lobby),
        maxPlayersPerTeam = cfg.maxPlayersPerTeam,
        killsToWin = cfg.killsToWin,
        roundsToWin = cfg.roundsToWin,
        roundTime = cfg.roundTime,
        playerCount = countPlayers(lobby),
        players = playerPayload(lobby),
        scores = Arena.Utils.Scoreboard(lobby.scores),
        round = lobby.round,
        state = lobby.state,
        endsAt = lobby.endsAt,
        loadouts = Config.ResolveLoadouts(cfg.loadouts),
        kill_rewards = cfg.kill_rewards,
        win_rewards = cfg.win_rewards,
        teamkill = cfg.teamkill == true,
        disableKillstreaks = cfg.disableKillstreaks == true,
        joinDuringMatch = cfg.joinDuringMatch ~= false,
        sizeLabel = cfg.sizeLabel or cfg.name,
        teamSize = cfg.maxPlayersPerTeam,
        watchers = Arena.Watch and Arena.Watch.Count(lobby.id) or 0,
        bets = Arena.Bets and Arena.Bets.List(lobby.id) or {},
        betting = Config.Betting,
    }
end

function Arena.ListLobbies()
    local list = {}
    for _, lobby in pairs(Arena.Lobbies) do
        list[#list + 1] = Arena.PublicLobby(lobby)
    end
    table.sort(list, function(a, b)
        if a.mode == b.mode then return a.name < b.name end
        local order = { ffa = 1, pvp = 2, tdm = 3, showdown = 4 }
        return (order[a.mode] or 9) < (order[b.mode] or 9)
    end)
    return list
end

function Arena.GetPlayerLobby(src)
    local id = Arena.PlayerLobby[src]
    if not id then return end
    return Arena.Lobbies[id]
end

local function syncLobby(lobby)
    local data = Arena.PublicLobby(lobby)
    broadcast(lobby, 'cursor_arena:client:lobbySync', data)
    TriggerClientEvent('cursor_arena:client:lobbiesDirty', -1)
end

local function pickTeam(lobby, requested)
    if not Arena.Utils.IsTeamMode(lobby.mode) then return 0 end
    local cap = lobby.cfg.maxPlayersPerTeam or 8
    -- 1v1: always auto-assign opposite sides. Ignore the Orange/Blue picker.
    local auto = cap == 1
    if not auto and (requested == 1 or requested == 2) then
        if countTeam(lobby, requested) < cap then return requested end
    end
    local t1 = countTeam(lobby, 1)
    local t2 = countTeam(lobby, 2)
    if t1 <= t2 and t1 < cap then return 1 end
    if t2 < cap then return 2 end
    return nil
end

local function dealSpawn(lobby, team)
    local map = lobby.map
    -- 1v1–4v4: whole team lands on the same mark
    if lobby.mode == 'pvp' or lobby.mode == 'tdm' then
        local list = team == 2 and map.team2_spawns or map.team1_spawns
        return Arena.Utils.Vec4(list and list[1])
    end
    if Arena.Utils.IsTeamMode(lobby.mode) then
        local deck = team == 2 and lobby.decks.team2 or lobby.decks.team1
        local list = team == 2 and map.team2_spawns or map.team1_spawns
        local spawn = Arena.Utils.DealSpawn(deck, list and list[1])
        return Arena.Utils.Vec4(spawn)
    end
    local spawn = Arena.Utils.DealSpawn(lobby.decks.ffa, map.spawns and map.spawns[1])
    return Arena.Utils.Vec4(spawn)
end

local function resetDecks(lobby)
    local map = lobby.map
    lobby.decks = {
        ffa = Arena.Utils.CreateSpawnDeck(map.spawns),
        team1 = Arena.Utils.CreateSpawnDeck(map.team1_spawns),
        team2 = Arena.Utils.CreateSpawnDeck(map.team2_spawns),
    }
end

local function enterWorld(src, lobby, p, spawn)
    SetPlayerRoutingBucket(src, lobby.bucket)
    SetRoutingBucketPopulationEnabled(lobby.bucket, false)
    Arena.Ambulance.SetArenaState(src, true)
    Arena.Inventory.StashPlayer(src)
    local weapon = select(1, Config.GetLoadoutWeapon(p.loadoutId, p.weaponId)) or Config.FindWeapon(p.weaponId)
    local slot = Arena.Inventory.GiveLoadout(src, weapon)
    Arena.Voice.Join(src, lobby, p.team)
    setStateBags(src, lobby, p)

    local bounds
    if lobby.map.boundaries and lobby.map.boundaries.points then
        bounds = { minZ = lobby.map.boundaries.minZ, maxZ = lobby.map.boundaries.maxZ, points = {} }
        for i = 1, #lobby.map.boundaries.points do
            local pt = lobby.map.boundaries.points[i]
            bounds.points[i] = { x = pt.x, y = pt.y }
        end
    end

    TriggerClientEvent('cursor_arena:client:enterArena', src, {
        lobby = Arena.PublicLobby(lobby),
        team = p.team,
        spawn = spawn,
        weapon = weapon and weapon.weapon,
        weaponId = p.weaponId,
        loadoutId = p.loadoutId,
        slot = slot,
        map = {
            id = lobby.map.id,
            name = lobby.map.name,
            center = lobby.map.center and { x = lobby.map.center.x, y = lobby.map.center.y, z = lobby.map.center.z } or nil,
            radius = lobby.map.radius,
            boundaries = bounds,
        },
        rules = Config.Rules,
        hitMarkers = Config.HitMarkers,
        killstreaks = not lobby.cfg.disableKillstreaks,
        killstreakStyle = Config.KillstreakStyle,
        nameplates = Config.Nameplates,
        teamPanel = Config.TeamPanel,
        bounds = Config.Boundaries,
        respawnTime = Config.RespawnTime,
        sounds = Config.Sounds,
    })
end

local function shouldStart(lobby)
    if countPlayers(lobby) < 2 then return false end
    if Arena.Utils.IsTeamMode(lobby.mode) then
        return countTeam(lobby, 1) >= 1 and countTeam(lobby, 2) >= 1
    end
    return true
end

local function payWinRewards(src, rewards)
    if not rewards then return end
    if rewards.money then
        Arena.Framework.AddMoney(src, rewards.money)
    end
    if GiveItemRewards then
        GiveItemRewards(src, rewards)
    end
end

local function scoreline(lobby)
    if lobby.mode == 'ffa' then
        local best = 0
        for _, p in pairs(lobby.players) do
            if p.kills > best then best = p.kills end
        end
        return tostring(best)
    end
    return ('%s-%s'):format(lobby.scores[1] or 0, lobby.scores[2] or 0)
end

local function endMatch(lobby, result)
    if lobby.state == 'ended' then return end
    lobby.state = 'ended'
    lobby.endsAt = nil
    lobby.matchResult = result
    lobby.bellRang = false

    local roster = playerPayload(lobby)
    local duration = lobby.startedAt and (os.time() - lobby.startedAt) or 0
    local matchUid = lobby.matchUid or nextMatchUid()
    result.lobby = lobby.id
    result.name = lobby.cfg.name
    result.scoreline = scoreline(lobby)
    result.players = {}

    local teamElo = { [1] = {}, [2] = {} }
    if Arena.Utils.IsElimination(lobby.mode) then
        for src, p in pairs(lobby.players) do
            local row = Arena.Stats.GetPlayer(src, lobby.mode)
            if p.team == 1 or p.team == 2 then
                teamElo[p.team][#teamElo[p.team] + 1] = row.elo or 1000
            end
        end
    end

    local function avg(list)
        if #list == 0 then return 1000 end
        local s = 0
        for i = 1, #list do s = s + list[i] end
        return s / #list
    end

    local history = {}
    local sorted = {}
    for src, p in pairs(lobby.players) do
        sorted[#sorted + 1] = { src = src, p = p }
    end
    table.sort(sorted, function(a, b) return a.p.kills > b.p.kills end)

    for place, row in ipairs(sorted) do
        local src, p = row.src, row.p
        local won = false
        if result.draw then
            won = false
        elseif result.winnerSrc then
            won = src == result.winnerSrc
        elseif result.winner and result.winner ~= 0 then
            won = p.team == result.winner
        end

        local eloChange = 0
        if Arena.Utils.IsElimination(lobby.mode) and (p.team == 1 or p.team == 2) and not result.draw then
            local mine = avg(teamElo[p.team])
            local theirs = avg(teamElo[p.team == 1 and 2 or 1])
            eloChange = Arena.Stats.ComputeElo(mine, theirs, won)
            if result.concededBy == src then
                eloChange = -math.abs(eloChange)
            end
        end

        local statsRow = Arena.Stats.ApplyMatch(src, lobby.mode, {
            kills = p.kills,
            deaths = p.deaths,
            won = won,
            playtime = duration,
            eloChange = eloChange ~= 0 and eloChange or nil,
        })

        if won then
            payWinRewards(src, lobby.cfg.win_rewards)
        end

        p.title = Arena.Utils.TitleForRank(lobby.mode, place)
        result.players[#result.players + 1] = {
            src = src,
            name = p.name,
            kills = p.kills,
            deaths = p.deaths,
            won = won,
            team = p.team,
            place = place,
            eloChange = eloChange,
            elo = statsRow and statsRow.elo,
        }

        history[#history + 1] = {
            matchUid = matchUid,
            identifier = Arena.Framework.GetIdentifier(src),
            name = p.name,
            mode = lobby.mode,
            lobbyId = lobby.id,
            lobbyName = lobby.cfg.name,
            kills = p.kills,
            deaths = p.deaths,
            won = won,
            team = p.team,
            place = place,
            eloChange = eloChange,
            scoreline = result.scoreline,
            duration = duration,
            roster = roster,
        }

        TriggerClientEvent('cursor_arena:client:matchEnded', src, {
            outcome = result.draw and 'draw' or (won and 'win' or 'loss'),
            result = result,
            scores = Arena.Utils.Scoreboard(lobby.scores),
            players = roster,
            eloChange = eloChange,
            duration = duration,
        })
    end

    if Arena.Watchers and Arena.Watchers[lobby.id] then
        for wsrc in pairs(Arena.Watchers[lobby.id]) do
            TriggerClientEvent('cursor_arena:client:matchEnded', wsrc, {
                outcome = result.draw and 'draw' or 'win',
                result = result,
                scores = Arena.Utils.Scoreboard(lobby.scores),
                players = roster,
            })
        end
    end

    Arena.Stats.RecordHistory(history)
    Arena.Discord.MatchEnded(lobby.mode, result)
    if MatchEnded then
        MatchEnded(matchUid, lobby.mode, result)
    end

    if Arena.Bets and Arena.Bets.Settle then
        Arena.Bets.Settle(lobby, result)
    end

    local delay = Config.PostMatchReturn or 8
    local id = lobby.id
    SetTimeout(delay * 1000, function()
        local l = Arena.Lobbies[id]
        if not l then return end
        if Arena.Watch and Arena.Watch.Clear then
            Arena.Watch.Clear(id)
        end
        local srcs = {}
        for src in pairs(l.players) do
            srcs[#srcs + 1] = src
        end
        for i = 1, #srcs do
            Arena.LeaveLobby(srcs[i], true, false)
        end
        l.scores = { [1] = 0, [2] = 0 }
        l.round = 1
        l.matchResult = nil
        l.state = 'idle'
        syncLobby(l)
    end)
end

local function startRoundTimer(lobby)
    local limit
    if Arena.Utils.IsElimination(lobby.mode) then
        limit = lobby.cfg.roundTime or 120
    else
        limit = lobby.cfg.timeLimit or 0
    end
    if not limit or limit <= 0 then
        lobby.endsAt = nil
        return
    end
    lobby.endsAt = os.time() + limit
    local id, endsAt = lobby.id, lobby.endsAt
    broadcast(lobby, 'cursor_arena:client:timer', endsAt, limit)

    CreateThread(function()
        while Arena.Lobbies[id] and Arena.Lobbies[id].endsAt == endsAt do
            local l = Arena.Lobbies[id]
            if l.state ~= 'active' then return end
            if os.time() >= endsAt then
                if Arena.Utils.IsElimination(l.mode) then
                    Arena.NextRound(l.id, 0)
                elseif l.mode == 'ffa' then
                    local bestSrc, bestKills, tie = nil, -1, false
                    for src, p in pairs(l.players) do
                        if p.kills > bestKills then
                            bestKills, bestSrc, tie = p.kills, src, false
                        elseif p.kills == bestKills then
                            tie = true
                        end
                    end
                    if tie or not bestSrc then
                        endMatch(l, { reason = 'time', draw = true, winner = 0 })
                    else
                        endMatch(l, {
                            reason = 'time',
                            winnerSrc = bestSrc,
                            winnerName = l.players[bestSrc].name,
                        })
                    end
                else
                    if (l.scores[1] or 0) == (l.scores[2] or 0) then
                        endMatch(l, { reason = 'time', draw = true, winner = 0 })
                    else
                        endMatch(l, {
                            reason = 'time',
                            winner = (l.scores[1] or 0) > (l.scores[2] or 0) and 1 or 2,
                        })
                    end
                end
                return
            end
            Wait(1000)
        end
    end)
end

function Arena.NextRound(lobbyId, winnerTeam)
    local lobby = Arena.Lobbies[lobbyId]
    if not lobby or not Arena.Utils.IsElimination(lobby.mode) then return end
    if winnerTeam and winnerTeam ~= 0 then
        lobby.scores[winnerTeam] = (lobby.scores[winnerTeam] or 0) + 1
    end
    local need = lobby.cfg.roundsToWin
    if not need then
        need = (lobby.cfg.maxPlayersPerTeam or 1) == 1 and 5 or 4
    end
    if (lobby.scores[1] or 0) >= need then
        endMatch(lobby, { reason = 'rounds', winner = 1 })
        return
    end
    if (lobby.scores[2] or 0) >= need then
        endMatch(lobby, { reason = 'rounds', winner = 2 })
        return
    end

    lobby.round = (lobby.round or 1) + 1
    lobby.state = 'countdown'
    resetDecks(lobby)

    for src, p in pairs(lobby.players) do
        p.alive = true
        p.spectating = false
        p.streak = 0
        local spawn = dealSpawn(lobby, p.team)
        p.spawn = spawn
        local weapon = select(1, Config.GetLoadoutWeapon(p.loadoutId, p.weaponId)) or Config.FindWeapon(p.weaponId)
        Arena.Inventory.GiveLoadout(src, weapon)
        Arena.Ambulance.Revive(src, spawn)
        setStateBags(src, lobby, p)
        TriggerClientEvent('cursor_arena:client:roundRestart', src, {
            round = lobby.round,
            spawn = spawn,
            scores = Arena.Utils.Scoreboard(lobby.scores),
            winnerTeam = winnerTeam,
        })
    end

    broadcast(lobby, 'cursor_arena:client:countdown', Config.CountdownSeconds, lobby.round)
    local id = lobby.id
    SetTimeout((Config.CountdownSeconds or 5) * 1000, function()
        local l = Arena.Lobbies[id]
        if not l or l.state ~= 'countdown' then return end
        l.state = 'active'
        startRoundTimer(l)
        broadcast(l, 'cursor_arena:client:matchActive', Arena.PublicLobby(l))
    end)
end

function Arena.TryStart(lobbyId, delayed)
    local lobby = Arena.Lobbies[lobbyId]
    if not lobby then return false end
    if lobby.state == 'active' or lobby.state == 'countdown' or lobby.state == 'ended' then
        return false
    end
    if not shouldStart(lobby) then
        lobby.state = countPlayers(lobby) > 0 and 'waiting' or 'idle'
        syncLobby(lobby)
        return false
    end

    if Arena.Utils.IsElimination(lobby.mode) and not delayed then
        -- 1v1 that's already full can start now. Only wait when the lobby
        -- still has empty slots (2v2–4v4 filling up).
        local full = countPlayers(lobby) >= maxPlayers(lobby)
        if not full then
            lobby.state = 'waiting'
            syncLobby(lobby)
            local id = lobby.id
            SetTimeout((Config.ShowdownStartDelay or 10) * 1000, function()
                Arena.TryStart(id, true)
            end)
            return true
        end
    end

    lobby.state = 'countdown'
    lobby.matchUid = nextMatchUid()
    lobby.startedAt = os.time()
    lobby.scores = { [1] = 0, [2] = 0 }
    lobby.round = 1
    lobby.bellRang = false
    resetDecks(lobby)

    for src, p in pairs(lobby.players) do
        p.kills = 0
        p.deaths = 0
        p.streak = 0
        p.alive = true
        p.spectating = false
        local spawn = dealSpawn(lobby, p.team)
        p.spawn = spawn
        local weapon = select(1, Config.GetLoadoutWeapon(p.loadoutId, p.weaponId)) or Config.FindWeapon(p.weaponId)
        local slot = Arena.Inventory.GiveLoadout(src, weapon)
        TriggerClientEvent('cursor_arena:client:preStart', src, {
            spawn = spawn,
            weapon = weapon and weapon.weapon,
            slot = slot,
        })
    end

    broadcast(lobby, 'cursor_arena:client:countdown', Config.CountdownSeconds, 1)
    syncLobby(lobby)

    local id = lobby.id
    SetTimeout((Config.CountdownSeconds or 5) * 1000, function()
        local l = Arena.Lobbies[id]
        if not l or l.state ~= 'countdown' then return end
        if not shouldStart(l) then
            l.state = 'waiting'
            syncLobby(l)
            return
        end
        l.state = 'active'
        startRoundTimer(l)
        broadcast(l, 'cursor_arena:client:matchActive', Arena.PublicLobby(l))
        broadcast(l, 'cursor_arena:client:sound', 'round_start')
    end)
    return true
end

local function maybeBell(lobby)
    if lobby.bellRang then return end
    local frac = (Config.Sounds and Config.Sounds.bellAt) or 0.9
    if lobby.mode == 'ffa' then
        local target = lobby.cfg.killsToWin or 30
        for _, p in pairs(lobby.players) do
            if p.kills >= math.floor(target * frac) then
                lobby.bellRang = true
                broadcast(lobby, 'cursor_arena:client:sound', 'bell')
                return
            end
        end
    elseif lobby.mode == 'tdm' then
        local target = lobby.cfg.killsToWin or 50
        if (lobby.scores[1] or 0) >= math.floor(target * frac) or (lobby.scores[2] or 0) >= math.floor(target * frac) then
            lobby.bellRang = true
            broadcast(lobby, 'cursor_arena:client:sound', 'bell')
        end
    end
end

local function checkWin(lobby)
    if lobby.mode == 'ffa' then
        local target = lobby.cfg.killsToWin or 30
        local bestSrc, best = nil, -1
        for src, p in pairs(lobby.players) do
            if p.kills > best then best, bestSrc = p.kills, src end
        end
        if best >= target then
            endMatch(lobby, { reason = 'score', winnerSrc = bestSrc, winnerName = lobby.players[bestSrc].name })
            return true
        end
    elseif lobby.mode == 'tdm' then
        local target = lobby.cfg.killsToWin or 50
        if (lobby.scores[1] or 0) >= target then
            endMatch(lobby, { reason = 'score', winner = 1 })
            return true
        end
        if (lobby.scores[2] or 0) >= target then
            endMatch(lobby, { reason = 'score', winner = 2 })
            return true
        end
    end
    return false
end

function Arena.OnPlayerDeath(victim, killer, weaponHash)
    local lobby = Arena.GetPlayerLobby(victim)
    if not lobby or lobby.state ~= 'active' then return end
    local vp = lobby.players[victim]
    if not vp or not vp.alive then return end

    vp.alive = false
    vp.deaths = vp.deaths + 1
    vp.streak = 0
    vp.lastActivity = os.time()
    setStateBags(victim, lobby, vp)

    local killerSrc = killer
    local kp = killerSrc and lobby.players[killerSrc]
    local friendly = kp and Arena.Utils.IsTeamMode(lobby.mode) and kp.team == vp.team and kp.team ~= 0
    local denyFriendly = friendly and lobby.cfg.teamkill ~= true

    if kp and killerSrc ~= victim and not denyFriendly then
        kp.kills = kp.kills + 1
        kp.streak = (kp.streak or 0) + 1
        kp.lastActivity = os.time()
        if lobby.mode == 'tdm' then
            lobby.scores[kp.team] = (lobby.scores[kp.team] or 0) + 1
        end

        local rewards = lobby.cfg.kill_rewards
        if rewards then
            TriggerClientEvent('cursor_arena:client:killReward', killerSrc, {
                health = rewards.health or 0,
                armor = rewards.armor or 0,
            })
            if rewards.items then
                GiveItemRewards(killerSrc, rewards)
            end
        end

        if not lobby.cfg.disableKillstreaks then
            local streak = Arena.Utils.KillstreakFor(kp.streak)
            local prev = Arena.Utils.KillstreakFor(kp.streak - 1)
            if streak and (not prev or prev.kills ~= streak.kills) then
                TriggerClientEvent('cursor_arena:client:killstreak', killerSrc, streak)
                broadcast(lobby, 'cursor_arena:client:killstreakCall', {
                    name = kp.name,
                    label = streak.label,
                    kills = kp.streak,
                })
            end
        end
    end

    local weaponName
    if kp then
        local def = Config.FindWeapon(kp.weaponId)
        weaponName = def and def.weapon
    end

    broadcast(lobby, 'cursor_arena:client:killfeed', {
        victim = vp.name,
        victimId = victim,
        killer = kp and kp.name or nil,
        killerId = killerSrc,
        weapon = weaponName,
        category = Arena.Utils.WeaponCategory(weaponName),
        headshot = false,
        scores = Arena.Utils.Scoreboard(lobby.scores),
        players = playerPayload(lobby),
        weaponHash = weaponHash,
    })

    maybeBell(lobby)

    if Arena.Utils.IsElimination(lobby.mode) then
        vp.spectating = true
        setStateBags(victim, lobby, vp)
        TriggerClientEvent('cursor_arena:client:downed', victim, playerPayload(lobby))

        local t1 = livingOnTeam(lobby, 1)
        local t2 = livingOnTeam(lobby, 2)
        if t1 == 0 or t2 == 0 then
            local winner = 0
            if t1 > 0 then winner = 1
            elseif t2 > 0 then winner = 2 end
            SetTimeout(1600, function()
                Arena.NextRound(lobby.id, winner)
            end)
            return
        end
        return
    end

    if checkWin(lobby) then return end
    syncLobby(lobby)

    SetTimeout((Config.RespawnTime or 3) * 1000, function()
        local l = Arena.Lobbies[lobby.id]
        if not l or l.state ~= 'active' then return end
        local p = l.players[victim]
        if not p then return end
        local spawn = dealSpawn(l, p.team)
        p.spawn = spawn
        p.alive = true
        p.spectating = false
        local weapon = select(1, Config.GetLoadoutWeapon(p.loadoutId, p.weaponId)) or Config.FindWeapon(p.weaponId)
        if Config.Rules.refillAmmoOnRespawn then
            Arena.Inventory.RefillAmmo(victim, weapon)
        end
        Arena.Ambulance.Revive(victim, spawn)
        setStateBags(victim, l, p)
        TriggerClientEvent('cursor_arena:client:respawn', victim, { spawn = spawn })
    end)
end

function Arena.JoinLobby(src, lobbyId, opts)
    opts = opts or {}
    if Arena.PlayerLobby[src] then return false, 'already_in_match' end
    if not Arena.PlayerHub[src] then return false, 'must_be_in_hub' end
    if Arena.LeaveAt[src] and os.time() < Arena.LeaveAt[src] then
        return false, 'already_in_match'
    end

    local lobby = Arena.Lobbies[lobbyId]
    if not lobby then return false, 'not_found' end

    if CanPlayerJoinLobby and CanPlayerJoinLobby(src, lobbyId) == false then
        return false, 'cannot_join'
    end

    if Config.RequireItem and not Arena.Framework.HasItem(src, Config.RequireItem, 1) then
        return false, 'need_item'
    end

    if countPlayers(lobby) >= maxPlayers(lobby) then return false, 'lobby_full' end

    if lobby.state == 'active' or lobby.state == 'countdown' then
        if Arena.Utils.IsElimination(lobby.mode) and lobby.cfg.joinDuringMatch == false then
            return false, 'lobby_full'
        end
    end

    local allowed = Config.ResolveLoadouts(lobby.cfg.loadouts)
    local loadoutId = opts.loadoutId or (allowed[1] and allowed[1].id)
    local weaponId = opts.weaponId
    local loadout = Config.GetLoadout(loadoutId)
    if not loadout then return false, 'invalid_loadout' end
    local okLoadout = false
    for i = 1, #allowed do
        if allowed[i].id == loadoutId then okLoadout = true break end
    end
    if not okLoadout then return false, 'invalid_loadout' end
    if not weaponId then weaponId = loadout.weapons[1] and loadout.weapons[1].id end
    if not Config.GetLoadoutWeapon(loadoutId, weaponId) then return false, 'invalid_loadout' end
    if not Arena.Shop.Owns(src, weaponId) then return false, 'shop_locked' end

    local team = 0
    if Arena.Utils.IsTeamMode(lobby.mode) then
        local requested = tonumber(opts.team)
        if (lobby.cfg.maxPlayersPerTeam or 8) == 1 then
            requested = nil
        end
        team = pickTeam(lobby, requested)
        if not team then return false, 'lobby_full' end
    end

    local ped = GetPlayerPed(src)
    local c = GetEntityCoords(ped)
    local returnCoords = vec4(c.x, c.y, c.z, GetEntityHeading(ped))

    local spawn = dealSpawn(lobby, team)
    lobby.players[src] = {
        name = Arena.Framework.GetName(src),
        team = team,
        loadoutId = loadoutId,
        weaponId = weaponId,
        kills = 0,
        deaths = 0,
        streak = 0,
        alive = not Arena.Utils.IsElimination(lobby.mode) or lobby.state ~= 'active',
        spectating = Arena.Utils.IsElimination(lobby.mode) and lobby.state == 'active',
        joinedAt = os.time(),
        lastActivity = os.time(),
        returnCoords = returnCoords,
        spawn = spawn,
        title = nil,
    }
    Arena.PlayerLobby[src] = lobbyId

    if Arena.Utils.IsElimination(lobby.mode) and lobby.state == 'active' then
        lobby.players[src].alive = false
        lobby.players[src].spectating = true
    end

    enterWorld(src, lobby, lobby.players[src], spawn)
    if PlayerJoinedLobby then PlayerJoinedLobby(src, lobbyId) end

    if lobby.state == 'idle' or lobby.state == 'waiting' then
        Arena.TryStart(lobby.id)
    end

    syncLobby(lobby)
    return true, Arena.PublicLobby(lobby)
end

function Arena.ChangeLoadout(src, loadoutId, weaponId)
    local lobby = Arena.GetPlayerLobby(src)
    if not lobby then return false, 'not_found' end
    local p = lobby.players[src]
    if not p then return false end

    if Arena.Utils.IsElimination(lobby.mode) and lobby.state == 'active' and p.alive then
        return false, 'loadout_locked'
    end

    local allowed = Config.ResolveLoadouts(lobby.cfg.loadouts)
    local ok = false
    for i = 1, #allowed do
        if allowed[i].id == loadoutId then ok = true break end
    end
    if not ok then return false, 'invalid_loadout' end
    local weapon = Config.GetLoadoutWeapon(loadoutId, weaponId)
    if not weapon then return false, 'invalid_loadout' end
    if not Arena.Shop.Owns(src, weaponId) then return false, 'shop_locked' end

    p.loadoutId = loadoutId
    p.weaponId = weaponId
    local slot = Arena.Inventory.GiveLoadout(src, weapon)
    TriggerClientEvent('cursor_arena:client:loadoutApplied', src, {
        weapon = weapon.weapon,
        loadoutId = loadoutId,
        weaponId = weaponId,
        slot = slot,
    })
    syncLobby(lobby)
    return true
end

function Arena.SetTeam(src, team)
    local lobby = Arena.GetPlayerLobby(src)
    if not lobby or not Arena.Utils.IsTeamMode(lobby.mode) then return false end
    if lobby.state == 'active' or lobby.state == 'countdown' then return false, 'lobby_full' end
    team = tonumber(team)
    if team ~= 1 and team ~= 2 then return false end
    local cap = lobby.cfg.maxPlayersPerTeam or 8
    if countTeam(lobby, team) >= cap and lobby.players[src].team ~= team then
        return false, 'lobby_full'
    end
    lobby.players[src].team = team
    Arena.Voice.Join(src, lobby, team)
    setStateBags(src, lobby, lobby.players[src])
    syncLobby(lobby)
    return true
end

function Arena.LeaveLobby(src, silent, conceded)
    local lobbyId = Arena.PlayerLobby[src]
    if not lobbyId then return false end
    local lobby = Arena.Lobbies[lobbyId]
    local p = lobby and lobby.players[src]

    if CanPlayerLeaveLobby and lobby and CanPlayerLeaveLobby(src, lobbyId) == false then
        return false, 'cannot_join'
    end

    Arena.PlayerLobby[src] = nil
    Arena.LeaveAt[src] = os.time() + (Config.LeaveCooldown or 4)

    Arena.Inventory.ClearLoadout(src)
    Arena.Inventory.RestorePlayer(src)
    Arena.Ambulance.Release(src)
    Arena.Voice.Leave(src)
    SetPlayerRoutingBucket(src, 0)
    setStateBags(src, nil)

    Arena.PlayerHub[src] = true
    TriggerClientEvent('cursor_arena:client:leaveArena', src, {
        toHub = true,
        silent = silent == true,
    })

    if lobby then
        lobby.players[src] = nil
        if PlayerLeftLobby then PlayerLeftLobby(src, lobbyId) end

        if lobby.state == 'active' or lobby.state == 'countdown' then
            if Arena.Utils.IsElimination(lobby.mode) and conceded ~= false then
                -- walking out mid-match concedes
                if countTeam(lobby, p and p.team or 0) == 0 and Arena.Utils.IsTeamMode(lobby.mode) then
                    local winner = (p and p.team == 1) and 2 or 1
                    endMatch(lobby, { reason = 'forfeit', winner = winner, concededBy = src })
                    return true
                end
            end
            if Arena.Utils.IsTeamMode(lobby.mode) then
                if countTeam(lobby, 1) == 0 or countTeam(lobby, 2) == 0 then
                    local winner = countTeam(lobby, 1) > 0 and 1 or 2
                    endMatch(lobby, { reason = 'forfeit', winner = winner, concededBy = src })
                    return true
                end
            elseif countPlayers(lobby) < 2 then
                local winnerSrc = next(lobby.players)
                if winnerSrc then
                    endMatch(lobby, {
                        reason = 'forfeit',
                        winnerSrc = winnerSrc,
                        winnerName = lobby.players[winnerSrc].name,
                    })
                else
                    lobby.state = 'idle'
                end
                return true
            end
        elseif countPlayers(lobby) == 0 then
            lobby.state = 'idle'
        end
        syncLobby(lobby)
    end
    return true
end

function Arena.InitLobbies()
    local offset = 0
    for mode, list in pairs(Config.Lobbies) do
        for i = 1, #list do
            local cfg = list[i]
            local map = Config.GetMap(cfg.map)
            if not map then
                print(('[cursor_arena] skipped lobby %s — unknown map %s'):format(cfg.id, tostring(cfg.map)))
            elseif Arena.Lobbies[cfg.id] then
                print(('[cursor_arena] skipped lobby %s — duplicate id'):format(cfg.id))
            else
                nextBucket = nextBucket + 1
                voiceSeq = voiceSeq + 2
                local lobby = {
                    id = cfg.id,
                    mode = mode,
                    cfg = cfg,
                    map = map,
                    bucket = nextBucket,
                    voiceOffset = voiceSeq,
                    players = {},
                    state = 'idle',
                    scores = { [1] = 0, [2] = 0 },
                    round = 1,
                    decks = {},
                }
                resetDecks(lobby)
                SetRoutingBucketPopulationEnabled(lobby.bucket, false)
                Arena.Lobbies[cfg.id] = lobby
            end
            offset = offset + 1
        end
    end
    Arena.Utils.Debug('Lobbies ready', Arena.Utils.TableSize(Arena.Lobbies))
end

CreateThread(function()
    Arena.InitLobbies()
end)

if Config.AfkKick and Config.AfkKick.enabled then
    CreateThread(function()
        while true do
            Wait(15000)
            local now = os.time()
            local limit = (Config.AfkKick.minutes or 5) * 60
            local warn = Config.AfkKick.warnAt or 60
            for id, lobby in pairs(Arena.Lobbies) do
                if lobby.state == 'active' then
                    for src, p in pairs(lobby.players) do
                        local idle = now - (p.lastActivity or now)
                        if idle >= limit then
                            Arena.Utils.Notify(src, { type = 'error', description = L('afk_kick') })
                            Arena.LeaveLobby(src, true, true)
                        elseif idle >= (limit - warn) and not p.afkWarned then
                            p.afkWarned = true
                            Arena.Utils.Notify(src, { type = 'error', description = L('afk_warn') })
                        elseif idle < 10 then
                            p.afkWarned = false
                        end
                    end
                end
            end
        end
    end)
end

AddEventHandler('playerDropped', function()
    local src = source
    Arena.PlayerHub[src] = nil
    if Arena.PlayerLobby[src] then
        if PlayerLeftServer then PlayerLeftServer(src) end
        Arena.LeaveLobby(src, true, true)
    end
end)
