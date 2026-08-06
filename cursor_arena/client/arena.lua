Arena = Arena or {}

local deathReported = false
local boundsThread = false

local function setMatchHud(visible, payload)
    SendNUIMessage({
        action = 'matchHud',
        visible = visible,
        data = payload,
    })
end

local function freezeForCountdown(seconds)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetPlayerInvincible(PlayerId(), true)

    SendNUIMessage({ action = 'countdown', seconds = seconds })

    local ends = GetGameTimer() + (seconds * 1000)
    while GetGameTimer() < ends do
        DisablePlayerFiring(PlayerId(), true)
        Wait(0)
    end

    FreezeEntityPosition(PlayerPedId(), false)
    SetPlayerInvincible(PlayerId(), false)
    SendNUIMessage({ action = 'countdown', seconds = 0 })
end

local function applySpawn(spawn)
    if not spawn then return end
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false)
    SetEntityHeading(ped, spawn.w or 0.0)
    ClearPedTasksImmediately(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 0)
end

local function startBoundsWatch(map)
    if boundsThread then return end
    if not Config.Rules.enforceBounds or not map then return end
    boundsThread = true

    CreateThread(function()
        while Arena.Client.inMatch and Arena.Client.match do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local center = Arena.Client.match.map.center
            local radius = Arena.Client.match.map.radius or 50.0
            local dist = #(coords - vec3(center.x, center.y, center.z))

            if dist > radius then
                if Config.Rules.boundsWarning then
                    lib.notify({ type = 'error', description = L('out_of_bounds') })
                end
                local heading = GetHeadingFromVector_2d(center.x - coords.x, center.y - coords.y)
                local push = radius * 0.85
                local rad = math.rad(heading)
                -- Pull back toward center
                local nx = center.x - math.sin(rad) * (radius * 0.2)
                local ny = center.y + math.cos(rad) * (radius * 0.2)
                -- Simpler: teleport slightly inside radius along vector to center
                local dx, dy = center.x - coords.x, center.y - coords.y
                local len = math.sqrt(dx * dx + dy * dy)
                if len > 0.01 then
                    dx, dy = dx / len, dy / len
                    SetEntityCoordsNoOffset(ped, center.x - dx * push, center.y - dy * push, coords.z, false, false, false)
                end
                Wait(800)
            end
            Wait(400)
        end
        boundsThread = false
    end)
end

local function watchDeath()
    CreateThread(function()
        deathReported = false
        while Arena.Client.inMatch do
            local ped = PlayerPedId()
            if (IsEntityDead(ped) or IsPedFatallyInjured(ped) or GetEntityHealth(ped) <= 0) and not deathReported then
                deathReported = true

                local killer = GetPedSourceOfDeath(ped)
                local killerServerId = nil
                if killer and killer ~= 0 and IsEntityAPed(killer) and IsPedAPlayer(killer) then
                    local idx = NetworkGetPlayerIndexFromPed(killer)
                    if idx and idx ~= -1 then
                        killerServerId = GetPlayerServerId(idx)
                    end
                end

                local weaponHash = GetPedCauseOfDeath(ped)
                TriggerServerEvent('cursor_arena:server:playerDied', killerServerId, weaponHash)

                if Config.WasabiAmbulance.blockDeathScreen then
                    -- Keep player from softlocking on wasabi UI
                    SendNUIMessage({ action = 'deathOverlay', visible = true })
                end
            elseif not IsEntityDead(ped) and GetEntityHealth(ped) > 0 then
                deathReported = false
                SendNUIMessage({ action = 'deathOverlay', visible = false })
            end
            Wait(200)
        end
    end)
end

local function applyRules(rules)
    rules = rules or Config.Rules
    CreateThread(function()
        while Arena.Client.inMatch do
            if rules.clearWanted then
                ClearPlayerWantedLevel(PlayerId())
                SetMaxWantedLevel(0)
            end
            if rules.disableIdleCam then
                InvalidateIdleCam()
            end
            if rules.blockedControls then
                for i = 1, #rules.blockedControls do
                    DisableControlAction(0, rules.blockedControls[i], true)
                end
            end
            if not rules.allowVehicles then
                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
                end
            end
            Wait(0)
        end
        SetMaxWantedLevel(5)
    end)
end

RegisterNetEvent('cursor_arena:client:enterMatch', function(data)
    Arena.Client.CloseUI(true)
    Arena.Client.inMatch = true
    Arena.Client.match = data
    Arena.Client.returnCoords = GetEntityCoords(PlayerPedId())
    deathReported = false

    applySpawn(data.spawn)
    applyRules(data.rules)
    startBoundsWatch(data.map)
    watchDeath()

    if Config.Rules.infiniteAmmo and data.weapon then
        CreateThread(function()
            Wait(500)
            local ped = PlayerPedId()
            local weaponDef = Config.FindWeapon(data.weapon)
            local hash = weaponDef and joaat(weaponDef.weapon) or GetSelectedPedWeapon(ped)
            if hash and hash ~= `WEAPON_UNARMED` then
                SetPedInfiniteAmmo(ped, true, hash)
                SetCurrentPedWeapon(ped, hash, true)
            end
        end)
    end

    setMatchHud(true, {
        modeLabel = data.mode.label,
        mapLabel = data.map.label,
        team = data.team,
        scoreLimit = data.mode.scoreLimit,
        kills = 0,
        deaths = 0,
        scores = { red = 0, blue = 0 },
    })

    lib.notify({ type = 'inform', description = L('match_starting', tostring(Config.CountdownSeconds)) })
end)

RegisterNetEvent('cursor_arena:client:countdown', function(seconds)
    CreateThread(function()
        freezeForCountdown(seconds or Config.CountdownSeconds)
        lib.notify({ type = 'success', description = L('match_started') })
    end)
end)

RegisterNetEvent('cursor_arena:client:matchActive', function(lobby)
    if not Arena.Client.match then return end
    setMatchHud(true, {
        modeLabel = lobby.modeLabel,
        mapLabel = lobby.mapLabel,
        team = Arena.Client.match.team,
        scoreLimit = lobby.scoreLimit,
        scores = lobby.scores,
        players = lobby.players,
        endsAt = lobby.endsAt,
        round = lobby.round,
    })
end)

RegisterNetEvent('cursor_arena:client:timer', function(endsAt, limit)
    SendNUIMessage({
        action = 'timer',
        endsAt = endsAt,
        limit = limit,
        serverNow = endsAt - (limit or 0),
    })
end)

RegisterNetEvent('cursor_arena:client:killfeed', function(payload)
    SendNUIMessage({ action = 'killfeed', data = payload })
    if Arena.Client.match then
        setMatchHud(true, {
            scores = payload.scores,
            players = payload.players,
        })
    end
end)

RegisterNetEvent('cursor_arena:client:killReward', function(data)
    local ped = PlayerPedId()
    if data.heal and data.heal > 0 then
        local health = GetEntityHealth(ped)
        SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), health + data.heal))
    end
    if data.armor and data.armor > 0 then
        SetPedArmour(ped, math.min(100, GetPedArmour(ped) + data.armor))
    end
end)

RegisterNetEvent('cursor_arena:client:respawn', function(data)
    deathReported = false
    applySpawn(data.spawn)
    SendNUIMessage({ action = 'deathOverlay', visible = false })
    lib.notify({ type = 'inform', description = L('respawning') })
end)

RegisterNetEvent('cursor_arena:client:roundRestart', function(data)
    deathReported = false
    applySpawn(data.spawn)
    setMatchHud(true, {
        scores = data.scores,
        round = data.round,
    })
    lib.notify({ type = 'inform', description = L('round_over') })
end)

RegisterNetEvent('cursor_arena:client:matchEnded', function(payload)
    SendNUIMessage({
        action = 'matchResult',
        data = payload,
    })

    local msg = L('draw')
    if payload.outcome == 'win' then
        msg = L('you_won')
    elseif payload.outcome == 'loss' then
        msg = L('you_lost')
    end
    lib.notify({ type = payload.outcome == 'win' and 'success' or 'inform', description = L('match_ended', msg) })
end)

RegisterNetEvent('cursor_arena:client:leaveMatch', function(data)
    Arena.Client.inMatch = false
    Arena.Client.match = nil
    Arena.Client.ambulanceArena = false
    LocalPlayer.state:set('arenaActive', false, true)
    deathReported = false

    setMatchHud(false)
    SendNUIMessage({ action = 'deathOverlay', visible = false })
    SendNUIMessage({ action = 'countdown', seconds = 0 })
    SendNUIMessage({ action = 'matchResult', data = nil })

    RemoveAllPedWeapons(PlayerPedId(), true)

    local coords = data and data.returnCoords or Config.ReturnLocation.coords
    if coords then
        SetEntityCoordsNoOffset(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false)
        if coords.w then SetEntityHeading(PlayerPedId(), coords.w) end
    end

    SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
    SetPedArmour(PlayerPedId(), 0)
    SetMaxWantedLevel(5)

    if not (data and data.silent) then
        lib.notify({ type = 'inform', description = L('left_match') })
    end
end)
