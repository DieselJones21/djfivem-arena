Arena.Spectate = Arena.Spectate or {}

local specIndex = 1
local specTarget

local function teammates()
    local list = {}
    local lobby = Arena.Client.lobby
    if not lobby or not lobby.players then return list end
    local myId = GetPlayerServerId(PlayerId())
    for i = 1, #lobby.players do
        local p = lobby.players[i]
        if p.id ~= myId and p.team == Arena.Client.team and p.alive then
            list[#list + 1] = p.id
        end
    end
    return list
end

local function pedForServerId(sid)
    for _, player in ipairs(GetActivePlayers()) do
        if GetPlayerServerId(player) == sid then
            return GetPlayerPed(player), player
        end
    end
end

function Arena.Spectate.Stop()
    if specTarget then
        NetworkSetInSpectatorMode(false, PlayerPedId())
        specTarget = nil
    end
    Arena.Client.spectating = false
    LocalPlayer.state:set('arena_spectator', false, true)
    SendNUIMessage({ action = 'spectate', visible = false })
end

function Arena.Spectate.Start()
    if not Arena.Client.inArena then return end
    Arena.Client.spectating = true
    LocalPlayer.state:set('arena_spectator', true, true)
    specIndex = 1
    Arena.Spectate.Cycle(0)
end

function Arena.Spectate.Cycle(dir)
    local list = teammates()
    if #list == 0 then
        if specTarget then
            NetworkSetInSpectatorMode(false, PlayerPedId())
            specTarget = nil
        end
        SendNUIMessage({ action = 'spectate', visible = true, name = 'Waiting for round...', hint = L('spectate_hint') })
        return
    end
    specIndex = specIndex + (dir or 0)
    if specIndex < 1 then specIndex = #list end
    if specIndex > #list then specIndex = 1 end
    local sid = list[specIndex]
    local ped = pedForServerId(sid)
    if ped then
        NetworkSetInSpectatorMode(true, ped)
        specTarget = ped
        local name = GetPlayerName(GetPlayerFromServerId(sid)) or 'Teammate'
        SendNUIMessage({ action = 'spectate', visible = true, name = name, hint = L('spectate_hint') })
    end
end

CreateThread(function()
    while true do
        if Arena.Client.spectating then
            if IsControlJustReleased(0, 175) then -- right
                Arena.Spectate.Cycle(1)
            elseif IsControlJustReleased(0, 174) then -- left
                Arena.Spectate.Cycle(-1)
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)
