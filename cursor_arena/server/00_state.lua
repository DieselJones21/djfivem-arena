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
