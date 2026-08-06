--[[
    wasabi_ambulance bridge (client)

    While Arena.Client.ambulanceArena is true:
      - death is reported to cursor_arena instead of wasabi flow
      - wasabi death screen can be suppressed
      - arena handles revive/respawn
]]

RegisterNetEvent('cursor_arena:client:setAmbulanceArenaState', function(state)
    Arena.Client.ambulanceArena = state == true
    LocalPlayer.state:set('arenaActive', Arena.Client.ambulanceArena, true)
end)

RegisterNetEvent('cursor_arena:client:arenaRevive', function(coords)
    local ped = PlayerPedId()

    if IsEntityDead(ped) or IsPedFatallyInjured(ped) then
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

        NetworkResurrectLocalPlayer(x, y, z, w, true, false)
        ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
        SetEntityHeading(ped, w)
    end

    SetPlayerInvincible(PlayerId(), false)
    SetEntityInvincible(ped, false)
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 0)
    ClearPedTasksImmediately(ped)

    -- Clear common death state bags used by ambulance scripts
    LocalPlayer.state:set('dead', false, true)
    LocalPlayer.state:set('isDead', false, true)

    -- Best-effort wasabi cleanup
    if Config.WasabiAmbulance.enabled and Config.WasabiAmbulance.blockDeathScreen then
        SendNUIMessage({ action = 'hideDeath' }) -- harmless if unused
    end
end)

-- Optional: if wasabi exposes a death event, ignore / redirect while in arena
AddEventHandler('wasabi_ambulance:onPlayerDeath', function()
    if Arena.Client.ambulanceArena or Arena.Client.inMatch then
        CancelEvent()
    end
end)

-- Export for wasabi / other resources to query
exports('IsInArena', function()
    return Arena.Client.inMatch == true
end)

exports('ShouldBlockAmbulance', function()
    return Arena.Client.ambulanceArena == true
end)
