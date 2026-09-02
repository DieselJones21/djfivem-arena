local DEATH_FLAGS = { 'dead', 'isDead', 'isdead', 'Laststand', 'laststand' }

local function isDown()
    local ped = PlayerPedId()
    if IsEntityDead(ped) or IsPedFatallyInjured(ped) or GetEntityHealth(ped) <= 101 then
        return true
    end
    local st = LocalPlayer.state
    for i = 1, #DEATH_FLAGS do
        if st[DEATH_FLAGS[i]] then return true end
    end
    return false
end

local function nativeRevive(coords)
    local ped = PlayerPedId()
    local x, y, z, w = 0.0, 0.0, 0.0, 0.0
    if coords then
        x = coords.x or coords[1] or 0.0
        y = coords.y or coords[2] or 0.0
        z = coords.z or coords[3] or 0.0
        w = coords.w or coords[4] or 0.0
    else
        local c = GetEntityCoords(ped)
        x, y, z = c.x, c.y, c.z
        w = GetEntityHeading(ped)
    end

    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
        NetworkResurrectLocalPlayer(x, y, z, w, true, false)
        ped = PlayerPedId()
    end

    SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
    SetEntityHeading(ped, w)
    SetPlayerInvincible(PlayerId(), false)
    SetEntityInvincible(ped, false)
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    ClearPedTasksImmediately(ped)

    LocalPlayer.state:set('dead', false, true)
    LocalPlayer.state:set('isDead', false, true)
    LocalPlayer.state:set('isdead', false, true)
end

local function resourceRevive(kind, resource)
    if not kind then return end
    if kind == 'wasabi' then
        TriggerEvent('wasabi_ambulance:revive')
        pcall(function()
            exports[resource or 'wasabi_ambulance']:RevivePlayer()
        end)
    elseif kind == 'qbx_medical' then
        pcall(function()
            exports.qbx_medical:Revive()
        end)
        TriggerEvent('qbx_medical:client:playerRevived')
    elseif kind == 'qbx_ambulance' then
        TriggerEvent('hospital:client:Revive')
        pcall(function()
            exports.qbx_ambulancejob:Revive()
        end)
    elseif kind == 'qb' then
        TriggerEvent('hospital:client:Revive')
    elseif kind == 'esx' then
        TriggerEvent('esx_ambulancejob:revive')
    end
end

RegisterNetEvent('cursor_arena:client:setAmbulanceArenaState', function(state)
    Arena.Client.ambulanceArena = state == true
    LocalPlayer.state:set('arenaActive', Arena.Client.ambulanceArena, true)
end)

RegisterNetEvent('cursor_arena:client:arenaRevive', function(coords, kind, resource)
    nativeRevive(coords)
    if Config.Ambulance.forceRevive then
        resourceRevive(kind, resource)
    end

    -- IC-style verify: if still down a moment later, ask the server to try again.
    CreateThread(function()
        Wait(400)
        if Arena.Client.inArena and isDown() then
            nativeRevive(coords)
            Wait(350)
            if isDown() then
                TriggerServerEvent('cursor_arena:server:reviveRetry', coords)
            end
        end
    end)
end)

AddEventHandler('wasabi_ambulance:onPlayerDeath', function()
    if Arena.Client.ambulanceArena or Arena.Client.inArena then
        CancelEvent()
    end
end)

exports('IsInHub', function()
    return Arena.Client.inHub == true
end)

exports('IsInArena', function()
    return Arena.Client.inArena == true
end)

exports('IsSpectating', function()
    return Arena.Client.spectating == true
end)

exports('ShouldBlockAmbulance', function()
    return Arena.Client.ambulanceArena == true
end)

exports('GetArenaInfo', function()
    if not Arena.Client.inArena then return end
    return {
        lobby = Arena.Client.lobby and Arena.Client.lobby.id,
        mode = Arena.Client.lobby and Arena.Client.lobby.mode,
        teams = Arena.Client.lobby and Arena.Client.lobby.scores,
        down = Arena.Client.down,
        spectating = Arena.Client.spectating,
    }
end)

exports('LeaveArena', function()
    if not Arena.Client.inArena then return false end
    lib.callback.await('cursor_arena:leaveLobby', false)
    return true
end)
