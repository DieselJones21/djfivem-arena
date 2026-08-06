Arena = Arena or {}
Arena.Ambulance = {}

local function wasabiReady()
    return Config.WasabiAmbulance.enabled
        and GetResourceState(Config.WasabiAmbulance.resourceName) == 'started'
end

function Arena.Ambulance.IsEnabled()
    return wasabiReady()
end

--- Tell client to enter/exit arena death handling mode (blocks wasabi death UI).
function Arena.Ambulance.SetArenaState(src, inArena)
    TriggerClientEvent('cursor_arena:client:setAmbulanceArenaState', src, inArena == true)
end

--- Force a clean revive suitable for arena respawn.
function Arena.Ambulance.Revive(src, coords)
    Arena.Ambulance.SetArenaState(src, true)

    if Config.WasabiAmbulance.forceReviveOnRespawn then
        -- Client-side revive is more reliable across wasabi forks
        TriggerClientEvent('cursor_arena:client:arenaRevive', src, coords)

        if wasabiReady() and Config.WasabiAmbulance.reviveEvent then
            -- Also fire wasabi revive for state sync (death flags, metadata)
            TriggerClientEvent(Config.WasabiAmbulance.reviveEvent, src)
        end
    else
        TriggerClientEvent('cursor_arena:client:arenaRevive', src, coords)
    end
end

--- Called when a player leaves arena — restore normal wasabi behavior.
function Arena.Ambulance.Release(src)
    TriggerClientEvent('cursor_arena:client:setAmbulanceArenaState', src, false)
end
