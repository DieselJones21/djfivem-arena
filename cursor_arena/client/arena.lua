local deathReported = false
local boundsUntil = 0
local boundsImmuneUntil = 0

local REL_A = nil
local REL_B = nil

local function applySpawn(spawn)
    if not spawn then return end
    local x, y, z = spawn.x, spawn.y, spawn.z
    local w = spawn.w or 0.0
    RequestCollisionAtCoord(x, y, z)
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        NetworkResurrectLocalPlayer(x, y, z, w, true, false)
        ped = PlayerPedId()
    end
    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, w)
    local deadline = GetGameTimer() + 700
    while not HasCollisionLoadedAroundEntity(ped) and GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, z)
        Wait(0)
    end
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    ResetPedRagdollTimer(ped)
    if Config.Combat and Config.Combat.ragdoll == false then
        SetPedCanRagdoll(ped, false)
    end
    SetPedSuffersCriticalHits(ped, true)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 0)
    ClearEntityLastDamageEntity(ped)
    ClearPedLastWeaponDamage(ped)
end

local function wantsTeamkill(lobby)
    if not lobby then return true end
    if lobby.mode == 'ffa' then return true end
    return lobby.teamkill == true
end

-- Apply once on enter / respawn / countdown end.
-- Re-running this every tick flips invincibility and state bags and desyncs shots.
local combatGen = 0

local function applyCombatLock()
    combatGen = combatGen + 1
    local ped = PlayerPedId()
    local teamkill = Arena.Client.teamkill == true
    NetworkSetFriendlyFireOption(true)
    SetCanAttackFriendly(ped, teamkill, false)
    SetEntityCanBeDamaged(ped, true)
    SetPedSuffersCriticalHits(ped, true)
    if Config.Combat and Config.Combat.ragdoll == false then
        SetPedCanRagdoll(ped, false)
    end
    if not Arena.Client.frozen then
        SetPlayerInvincible(PlayerId(), false)
        SetEntityInvincible(ped, false)
    end
    if LocalPlayer.state.invBusy then
        LocalPlayer.state:set('invBusy', false, true)
    end
    LocalPlayer.state:set('canUseWeapons', true, true)
    DisablePlayerFiring(PlayerId(), false)
end

local function freeze(on)
    Arena.Client.frozen = on
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, on)
    SetPlayerInvincible(PlayerId(), on)
    SetEntityInvincible(ped, on)
    if not on then
        DisablePlayerFiring(PlayerId(), false)
        EnableControlAction(0, 24, true)
        EnableControlAction(0, 25, true)
        EnableControlAction(0, 140, true)
        applyCombatLock()
    end
end

local function setupTeams(teamkill)
    Arena.Client.teamkill = teamkill == true
    if not REL_A then
        local _, hashA = AddRelationshipGroup('ARENA_T1')
        local _, hashB = AddRelationshipGroup('ARENA_T2')
        REL_A = hashA or `ARENA_T1`
        REL_B = hashB or `ARENA_T2`
    end
    local hate = 5
    local same = teamkill and 5 or 0
    SetRelationshipBetweenGroups(same, REL_A, REL_A)
    SetRelationshipBetweenGroups(same, REL_B, REL_B)
    SetRelationshipBetweenGroups(hate, REL_A, REL_B)
    SetRelationshipBetweenGroups(hate, REL_B, REL_A)

    local ped = PlayerPedId()
    if Arena.Client.team == 1 then
        SetPedRelationshipGroupHash(ped, REL_A)
    elseif Arena.Client.team == 2 then
        SetPedRelationshipGroupHash(ped, REL_B)
    end

    applyCombatLock()
end

local function drawBoundaries()
    local map = Arena.Client.map
    if not map then return end
    local show = Config.Debug or (Config.Boundaries and Config.Boundaries.show)
    local points = map.boundaries and map.boundaries.points
    if not points or #points < 2 then
        if show and map.center and map.radius then
            DrawMarker(1, map.center.x, map.center.y, map.center.z - 1.0, 0, 0, 0, 0, 0, 0,
                map.radius * 2, map.radius * 2, 1.2, 0, 242, 255, 70, false, false, 2, false, nil, nil, false)
        end
        return
    end
    if not show then return end
    local outside = not Arena.Utils.InsideMap(GetEntityCoords(PlayerPedId()), map)
    local r, g, b = 0, 242, 255
    if outside then r, g, b = 255, 80, 90 end
    local z = map.boundaries.minZ or (map.center and map.center.z) or 0.0
    local h = ((map.boundaries.maxZ or (z + 8.0)) - z)
    for i = 1, #points do
        local a = points[i]
        local nxt = points[i % #points + 1]
        DrawLine(a.x, a.y, z, nxt.x, nxt.y, z, r, g, b, 200)
        DrawLine(a.x, a.y, z + h, nxt.x, nxt.y, z + h, r, g, b, 160)
        DrawLine(a.x, a.y, z, a.x, a.y, z + h, r, g, b, 120)
        if Config.Debug then
            local onScreen, sx, sy = World3dToScreen2d(a.x, a.y, z + 1.2)
            if onScreen then
                SetTextScale(0.32, 0.32)
                SetTextFont(4)
                SetTextCentre(true)
                SetTextColour(255, 255, 255, 220)
                BeginTextCommandDisplayText('STRING')
                AddTextComponentSubstringPlayerName(tostring(i))
                EndTextCommandDisplayText(sx, sy)
            end
        end
    end
end

local nameplateCache = {}

local function refreshTeammates()
    nameplateCache = {}
    if not Arena.Client.inArena then return end
    local lobby = Arena.Client.lobby
    if not lobby or not lobby.players then return end
    local myId = GetPlayerServerId(PlayerId())
    for i = 1, #lobby.players do
        local p = lobby.players[i]
        local idx = GetPlayerFromServerId(p.id)
        if idx and idx ~= -1 then
            local ped = GetPlayerPed(idx)
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                if p.team == 1 and REL_A then
                    SetPedRelationshipGroupHash(ped, REL_A)
                elseif p.team == 2 and REL_B then
                    SetPedRelationshipGroupHash(ped, REL_B)
                end
                if p.id ~= myId and p.team == Arena.Client.team and p.alive then
                    nameplateCache[#nameplateCache + 1] = ped
                end
            end
        end
    end
end

local function drawNameplates()
    if not Config.Nameplates.enabled then return end
    if not Arena.Utils.IsTeamMode(Arena.Client.lobby and Arena.Client.lobby.mode) then return end
    local myCoords = GetEntityCoords(PlayerPedId())
    local range = Config.Nameplates.range or 120.0
    local r, g, b = 59, 158, 255
    if Arena.Client.team == 1 then r, g, b = 255, 138, 26 end
    for i = 1, #nameplateCache do
        local ped = nameplateCache[i]
        if ped and DoesEntityExist(ped) then
            local coords = GetEntityCoords(ped)
            if #(coords - myCoords) <= range then
                DrawMarker(2, coords.x, coords.y, coords.z + 1.15, 0, 0, 0, 0, 180.0, 0,
                    0.18, 0.18, 0.18, r, g, b, 180, false, true, 2, false, nil, nil, false)
            end
        end
    end
end

local function hudPayload()
    local lobby = Arena.Client.lobby
    if not lobby then return {} end
    local myId = GetPlayerServerId(PlayerId())
    local me
    for i = 1, #(lobby.players or {}) do
        if lobby.players[i].id == myId then me = lobby.players[i] break end
    end
    return {
        mode = lobby.mode,
        name = lobby.name,
        mapName = lobby.mapName,
        scores = Arena.Utils.Scoreboard(lobby.scores),
        round = lobby.round,
        killsToWin = lobby.killsToWin,
        roundsToWin = lobby.roundsToWin,
        endsAt = lobby.endsAt,
        players = lobby.players,
        me = me,
        team = (me and me.team) or Arena.Client.team,
        waiting = lobby.state == 'waiting' or lobby.state == 'idle',
        state = lobby.state,
        sizeLabel = lobby.sizeLabel,
        teamPanel = Config.TeamPanel and Config.TeamPanel.enabled and Arena.Utils.IsTeamMode(lobby.mode),
        titles = Config.TeamPanel and Config.TeamPanel.titles,
        private = lobby.private,
        code = lobby.code,
    }
end

RegisterNetEvent('cursor_arena:client:enterArena', function(data)
    Arena.Client.CloseUI()
    if Arena.Client.HideHubHint then Arena.Client.HideHubHint() end
    lib.hideTextUI()
    Arena.Client.inArena = true
    Arena.Client.lobby = data.lobby
    Arena.Client.map = data.map
    Arena.Client.team = data.team or 0
    Arena.Client.spawn = data.spawn
    Arena.Client.down = false
    Arena.Client.spectating = false
    Arena.Client.equipRetries = 0
    deathReported = false
    boundsImmuneUntil = GetGameTimer() + ((Config.Boundaries.immunityTime or 3) * 1000)
    boundsUntil = 0

    DoScreenFadeOut(200)
    while not IsScreenFadedOut() do Wait(0) end
    applySpawn(data.spawn)
    setupTeams(wantsTeamkill(data.lobby))
    applyCombatLock()
    DoScreenFadeIn(400)

    if data.weapon then
        Arena.Client.weaponName = data.weapon
        Arena.Client.weaponSlot = data.slot or Arena.Client.weaponSlot
        CreateThread(function()
            Wait(500)
            if Arena.Client.weaponName and not Arena.Client.frozen then
                Arena.Client.EquipWeapon(Arena.Client.weaponName, 9999, Arena.Client.weaponSlot)
            end
        end)
    end

    SendNUIMessage({ action = 'close' })
    SendNUIMessage({ action = 'matchHud', visible = true, data = hudPayload() })
    SetNuiFocus(false, false)
    if Arena.Client.team == 1 or Arena.Client.team == 2 then
        lib.notify({
            type = 'inform',
            description = L('your_team', Arena.Client.team == 1 and L('team_1') or L('team_2')),
        })
    end
    if PlayerJoinedLobby then PlayerJoinedLobby() end
end)

RegisterNetEvent('cursor_arena:client:preStart', function(data)
    if data and data.spawn then
        applySpawn(data.spawn)
        boundsImmuneUntil = GetGameTimer() + ((Config.Boundaries.immunityTime or 3) * 1000)
    end
    if data and data.weapon then
        Arena.Client.weaponName = data.weapon
        Arena.Client.weaponSlot = data.slot or Arena.Client.weaponSlot
    end
end)

local countdownGen = 0

RegisterNetEvent('cursor_arena:client:countdown', function(seconds, round)
    countdownGen = countdownGen + 1
    local gen = countdownGen
    CreateThread(function()
        Arena.Client.CloseUI()
        freeze(true)
        SendNUIMessage({ action = 'close' })
        SendNUIMessage({ action = 'countdown', seconds = seconds or 5, round = round })
        local ends = GetGameTimer() + ((seconds or 5) * 1000)
        while GetGameTimer() < ends do
            if gen ~= countdownGen then
                return
            end
            if not Arena.Client.inArena then
                freeze(false)
                return
            end
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            Wait(0)
        end
        if gen ~= countdownGen then return end
        freeze(false)
        DisablePlayerFiring(PlayerId(), false)
        applyCombatLock()
        SendNUIMessage({ action = 'countdown', seconds = 0 })
        if Arena.Client.weaponName then
            Arena.Client.EquipWeapon(Arena.Client.weaponName, 9999, Arena.Client.weaponSlot)
        end
        lib.notify({ type = 'success', description = L('match_started') })
    end)
end)

RegisterNetEvent('cursor_arena:client:matchActive', function(lobby)
    Arena.Client.lobby = lobby
    deathReported = false
    freeze(false)
    DisablePlayerFiring(PlayerId(), false)
    applyCombatLock()
    if Arena.Client.weaponName then
        Arena.Client.EquipWeapon(Arena.Client.weaponName, 9999, Arena.Client.weaponSlot)
    end
    SendNUIMessage({ action = 'matchHud', visible = true, data = hudPayload() })
end)

local function syncMyTeam(lobby)
    if not lobby or not lobby.players then return end
    local myId = GetPlayerServerId(PlayerId())
    for i = 1, #lobby.players do
        if lobby.players[i].id == myId then
            local nextTeam = lobby.players[i].team or 0
            if nextTeam ~= Arena.Client.team then
                Arena.Client.team = nextTeam
                setupTeams(wantsTeamkill(lobby))
            end
            return
        end
    end
end

RegisterNetEvent('cursor_arena:client:lobbySync', function(lobby)
    Arena.Client.lobby = lobby
    if Arena.Client.inArena then
        syncMyTeam(lobby)
        SendNUIMessage({ action = 'matchHud', visible = true, data = hudPayload() })
        return
    end
    if Arena.Client.uiOpen then
        SendNUIMessage({ action = 'lobbyUpdate', data = lobby })
    end
end)

RegisterNetEvent('cursor_arena:client:timer', function(endsAt, limit, remaining)
    SendNUIMessage({ action = 'timer', endsAt = endsAt, limit = limit, remaining = remaining or limit })
end)

RegisterNetEvent('cursor_arena:client:killfeed', function(payload)
    SendNUIMessage({ action = 'killfeed', data = payload })
    if payload.players and Arena.Client.lobby then
        Arena.Client.lobby.players = payload.players
        Arena.Client.lobby.scores = payload.scores
        SendNUIMessage({ action = 'matchHud', visible = true, data = hudPayload() })
    end
end)

RegisterNetEvent('cursor_arena:client:respawn', function(data)
    deathReported = false
    Arena.Client.down = false
    Arena.Spectate.Stop()
    applySpawn(data.spawn)
    boundsImmuneUntil = GetGameTimer() + ((Config.Boundaries.immunityTime or 3) * 1000)
    applyCombatLock()
    if Arena.Client.weaponName then
        Arena.Client.EquipWeapon(Arena.Client.weaponName, 9999, Arena.Client.weaponSlot)
    end
    SendNUIMessage({ action = 'deathOverlay', visible = false })
end)

RegisterNetEvent('cursor_arena:client:roundRestart', function(data)
    deathReported = false
    Arena.Client.down = false
    Arena.Spectate.Stop()
    applySpawn(data.spawn)
    boundsImmuneUntil = GetGameTimer() + ((Config.Boundaries.immunityTime or 3) * 1000)
    applyCombatLock()
    if Arena.Client.weaponName then
        Arena.Client.EquipWeapon(Arena.Client.weaponName, 9999, Arena.Client.weaponSlot)
    end
    if Arena.Client.lobby then
        Arena.Client.lobby.scores = data.scores
        Arena.Client.lobby.round = data.round
    end
    SendNUIMessage({ action = 'deathOverlay', visible = false })
    SendNUIMessage({ action = 'matchHud', visible = true, data = hudPayload() })
    SendNUIMessage({ action = 'roundBanner', round = data.round, winnerTeam = data.winnerTeam })
end)

RegisterNetEvent('cursor_arena:client:downed', function(players)
    Arena.Client.down = true
    if Arena.Client.lobby then Arena.Client.lobby.players = players end
    SendNUIMessage({ action = 'deathOverlay', visible = true })
    Arena.Spectate.Start()
end)

RegisterNetEvent('cursor_arena:client:matchEnded', function(payload)
    SendNUIMessage({ action = 'matchResult', data = payload })
    Arena.Spectate.Stop()
    local msg = L('draw')
    if payload.outcome == 'win' then msg = L('you_won')
    elseif payload.outcome == 'loss' then msg = L('you_lost') end
    lib.notify({
        type = payload.outcome == 'win' and 'success' or 'inform',
        description = L('match_ended', msg),
    })
end)

RegisterNetEvent('cursor_arena:client:loadoutApplied', function(data)
    if data and data.weapon then
        Arena.Client.weaponName = data.weapon
        Arena.Client.weaponSlot = data.slot or Arena.Client.weaponSlot
        if Arena.Client.inArena then
            Arena.Client.EquipWeapon(data.weapon, 9999, Arena.Client.weaponSlot)
        end
    end
end)

RegisterNetEvent('cursor_arena:client:leaveArena', function(data)
    Arena.Client.inArena = false
    Arena.Client.lobby = nil
    Arena.Client.map = nil
    Arena.Client.down = false
    Arena.Client.ambulanceArena = false
    Arena.Spectate.Stop()
    freeze(false)
    deathReported = false
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    SetPedCanRagdoll(PlayerPedId(), true)
    LocalPlayer.state:set('arenaActive', false, true)
    NetworkSetFriendlyFireOption(true)
    SetCanAttackFriendly(PlayerPedId(), false, false)

    SendNUIMessage({ action = 'matchHud', visible = false })
    SendNUIMessage({ action = 'deathOverlay', visible = false })
    SendNUIMessage({ action = 'countdown', seconds = 0 })
    SendNUIMessage({ action = 'roundBanner', visible = false })
    SendNUIMessage({ action = 'bounds', visible = false })
    SendNUIMessage({ action = 'matchResult', data = nil })

    if Arena.Client.HolsterArenaWeapon then
        Arena.Client.HolsterArenaWeapon()
    else
        RemoveAllPedWeapons(PlayerPedId(), true)
        Arena.Client.weaponName = nil
        SetWeaponsNoAutoswap(false)
    end

    if data and data.toHub then
        Arena.Client.ReturnToHub()
        if data.silent then
            lib.notify({ type = 'inform', description = L('returned_hub') })
        end
    elseif data and data.returnCoords then
        local coords = data.returnCoords
        DoScreenFadeOut(250)
        while not IsScreenFadedOut() do Wait(0) end
        SetEntityCoordsNoOffset(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false)
        if coords.w then SetEntityHeading(PlayerPedId(), coords.w) end
        DoScreenFadeIn(400)
    end

    SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
    SetPedArmour(PlayerPedId(), 0)
    SetMaxWantedLevel(5)
    if PlayerLeftLobby then PlayerLeftLobby() end
    if not (data and data.silent) then
        lib.notify({ type = 'inform', description = L('left_match') })
    end
end)

RegisterNetEvent('cursor_arena:client:voice', function(channel)
    if GetResourceState('pma-voice') == 'started' then
        pcall(function()
            exports['pma-voice']:setRadioChannel(channel or 0)
        end)
    end
end)

local function reportArenaDeath()
    local ped = PlayerPedId()
    local killer = GetPedSourceOfDeath(ped)
    local killerServerId
    if killer and killer ~= 0 and IsEntityAPed(killer) and IsPedAPlayer(killer) then
        local idx = NetworkGetPlayerIndexFromPed(killer)
        if idx and idx ~= -1 then
            killerServerId = GetPlayerServerId(idx)
        end
    end
    local headshot = false
    local ok, bone = GetPedLastDamageBone(ped)
    if ok == true then
        local heads = Config.Combat and Config.Combat.headBones or { 31086, 39317, 12844, 65068 }
        for i = 1, #heads do
            if bone == heads[i] then headshot = true break end
        end
    elseif type(ok) == 'number' then
        local heads = Config.Combat and Config.Combat.headBones or { 31086, 39317, 12844, 65068 }
        for i = 1, #heads do
            if ok == heads[i] then headshot = true break end
        end
    end
    TriggerServerEvent('cursor_arena:server:playerDied', killerServerId, GetPedCauseOfDeath(ped), headshot)
    SendNUIMessage({ action = 'deathOverlay', visible = true })
end

-- Death watch. Must treat wasabi laststand as a kill — health stays above 0
-- there, and cancelling wasabi's death event would otherwise leave people crawling.
CreateThread(function()
    while true do
        if Arena.Client.inArena and not Arena.Client.down then
            local ped = PlayerPedId()
            local down = Arena.Client.IsPedDown and Arena.Client.IsPedDown()
                or IsEntityDead(ped) or IsPedFatallyInjured(ped) or GetEntityHealth(ped) <= 100
            local live = Arena.Client.lobby and Arena.Client.lobby.state == 'active'
            if down and live then
                if not deathReported then
                    deathReported = true
                    if not Arena.Client.frozen then
                        SetPlayerInvincible(PlayerId(), false)
                        SetEntityInvincible(ped, false)
                        SetEntityCanBeDamaged(ped, true)
                    end
                    if not IsEntityDead(ped) and GetEntityHealth(ped) > 100 then
                        SetEntityHealth(ped, 0)
                    end
                    reportArenaDeath()
                end
            elseif not down then
                deathReported = false
            end
            Wait(80)
        else
            Wait(500)
        end
    end
end)

-- Only repair what ox / laststand actually flips. Do not reset invincibility every tick.
CreateThread(function()
    while true do
        if Arena.Client.inArena and not Arena.Client.frozen and not Arena.Client.down and not Arena.Client.spectating then
            if LocalPlayer.state.invBusy then
                LocalPlayer.state:set('invBusy', false, true)
            end
            Wait(800)
        else
            Wait(1200)
        end
    end
end)

-- Teammate markers + relationship groups. Not every frame.
CreateThread(function()
    while true do
        if Arena.Client.inArena then
            refreshTeammates()
            Wait(500)
        else
            nameplateCache = {}
            Wait(1500)
        end
    end
end)

-- Rules + bounds. Drawing stays on its own loop so this can sleep.
CreateThread(function()
    local lastBoundsSec = -1
    while true do
        if Arena.Client.inArena then
            local ped = PlayerPedId()
            if Config.Rules.clearWanted then
                ClearPlayerWantedLevel(PlayerId())
                SetMaxWantedLevel(0)
            end
            if Config.Rules.disableIdleCam then InvalidateIdleCam() end
            if not Config.Rules.allowVehicles and IsPedInAnyVehicle(ped, false) then
                TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
            end

            local now = GetGameTimer()
            if now > boundsImmuneUntil and Arena.Client.map then
                local inside = Arena.Utils.InsideMap(GetEntityCoords(ped), {
                    center = Arena.Client.map.center and vec3(Arena.Client.map.center.x, Arena.Client.map.center.y, Arena.Client.map.center.z) or nil,
                    radius = Arena.Client.map.radius,
                    boundaries = Arena.Client.map.boundaries,
                })
                if not inside then
                    if boundsUntil == 0 then
                        boundsUntil = now + ((Config.Boundaries.warningTime or 5) * 1000)
                    end
                    local left = math.max(0, math.ceil((boundsUntil - now) / 1000))
                    if left ~= lastBoundsSec then
                        lastBoundsSec = left
                        SendNUIMessage({ action = 'bounds', visible = true, seconds = left })
                    end
                    if now >= boundsUntil then
                        SetEntityHealth(ped, 0)
                        boundsUntil = 0
                        lastBoundsSec = -1
                    end
                else
                    if boundsUntil ~= 0 then
                        SendNUIMessage({ action = 'bounds', visible = false })
                    end
                    boundsUntil = 0
                    lastBoundsSec = -1
                end
            end
            Wait(200)
        else
            lastBoundsSec = -1
            Wait(800)
        end
    end
end)

CreateThread(function()
    while true do
        if Arena.Client.inArena then
            local showBounds = Config.Debug or (Config.Boundaries and Config.Boundaries.show)
            local showNames = Config.Nameplates.enabled and Arena.Utils.IsTeamMode(Arena.Client.lobby and Arena.Client.lobby.mode)
            if showBounds or showNames then
                if showBounds then drawBoundaries() end
                if showNames then drawNameplates() end
                Wait(0)
            else
                Wait(400)
            end
        else
            Wait(800)
        end
    end
end)

CreateThread(function()
    while true do
        if Arena.Client.inArena then
            TriggerServerEvent('cursor_arena:server:activity')
            Wait(12000)
        else
            Wait(8000)
        end
    end
end)

CreateThread(function()
    while true do
        if Arena.Client.inArena and not Arena.Client.spectating then
            RestorePlayerStamina(PlayerId(), 1.0)
            ResetPlayerStamina(PlayerId())
            Wait(250)
        else
            Wait(800)
        end
    end
end)
