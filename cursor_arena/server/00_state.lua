--[[
    Shared server state. Loaded first so G / commands never index a nil table
    if a later file fails to start.
]]
Arena = Arena or {}
Arena.Lobbies = Arena.Lobbies or {}
Arena.PlayerLobby = Arena.PlayerLobby or {}
Arena.PlayerHub = Arena.PlayerHub or {}
Arena.LeaveAt = Arena.LeaveAt or {}
Arena.PrivateAdmit = Arena.PrivateAdmit or {}
Arena.PrivateCodes = Arena.PrivateCodes or {}

function Arena.GetPlayerLobby(src)
    local id = Arena.PlayerLobby[src]
    if not id then return end
    return Arena.Lobbies[id]
end

-- True when the player is standing in the spawn-lobby MLO (OneSync).
function Arena.IsInSpawnLobby(src)
    local hub = Config and Config.SpawnLobby
    if not hub or not hub.center then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local c = GetEntityCoords(ped)
    local dx = c.x - hub.center.x
    local dy = c.y - hub.center.y
    local r = (hub.radius or 150.0) + 8.0
    return (dx * dx + dy * dy) <= (r * r)
end

function Arena.EnsurePlayerHub(src)
    if Arena.PlayerHub[src] then return true end
    if Arena.IsInSpawnLobby(src) then
        Arena.PlayerHub[src] = true
        return true
    end
    return false
end
