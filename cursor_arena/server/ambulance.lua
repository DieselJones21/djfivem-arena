Arena = Arena or {}
Arena.Ambulance = { resource = nil, kind = nil }

local function detect()
    if not Config.Ambulance.enabled then return end
    for i = 1, #Config.Ambulance.resources do
        local name = Config.Ambulance.resources[i]
        if GetResourceState(name) == 'started' then
            Arena.Ambulance.resource = name
            if name:find('wasabi') then
                Arena.Ambulance.kind = 'wasabi'
            elseif name == 'qbx_medical' then
                Arena.Ambulance.kind = 'qbx_medical'
            elseif name:find('qbx_ambulance') then
                Arena.Ambulance.kind = 'qbx_ambulance'
            elseif name:find('qb-ambulance') then
                Arena.Ambulance.kind = 'qb'
            elseif name:find('esx') then
                Arena.Ambulance.kind = 'esx'
            else
                Arena.Ambulance.kind = 'generic'
            end
            Arena.Utils.Debug('Ambulance detected:', name, Arena.Ambulance.kind)
            return
        end
    end
    Arena.Utils.Debug('No ambulance resource detected — using native revive')
end

CreateThread(function()
    Wait(800)
    detect()
end)

function Arena.Ambulance.SetArenaState(src, inArena)
    TriggerClientEvent('cursor_arena:client:setAmbulanceArenaState', src, inArena == true)
end

--- Revive a player for arena respawn. Client verifies they actually stood up.
function Arena.Ambulance.Revive(src, coords)
    Arena.Ambulance.SetArenaState(src, true)
    TriggerClientEvent('cursor_arena:client:arenaRevive', src, coords, Arena.Ambulance.kind, Arena.Ambulance.resource)
end

function Arena.Ambulance.Release(src)
    TriggerClientEvent('cursor_arena:client:setAmbulanceArenaState', src, false)
end

--- Called from client if the first revive did not stick.
RegisterNetEvent('cursor_arena:server:reviveRetry', function(coords)
    local src = source
    Arena.Ambulance.Revive(src, coords)
end)
