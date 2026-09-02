Arena.Spectate = Arena.Spectate or {}

local specIndex = 1
local specTarget

local function livingFighters(allSides)
    local list = {}
    local lobby = Arena.Client.lobby
    if not lobby or not lobby.players then return list end
    local myId = GetPlayerServerId(PlayerId())
    for i = 1, #lobby.players do
        local p = lobby.players[i]
        if p.id ~= myId and p.alive ~= false then
            if allSides or p.team == Arena.Client.team then
                list[#list + 1] = p
            end
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

local function ghost(on)
    local ped = PlayerPedId()
    SetEntityVisible(ped, not on, false)
    SetEntityCollision(ped, not on, not on)
    FreezeEntityPosition(ped, on)
    SetEntityInvincible(ped, on)
    SetPlayerInvincible(PlayerId(), on)
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
    if not Arena.Client.inArena and not Arena.Client.watching then return end
    Arena.Client.spectating = true
    LocalPlayer.state:set('arena_spectator', true, true)
    specIndex = 1
    Arena.Spectate.Cycle(0)
end

function Arena.Spectate.Cycle(dir)
    local list = livingFighters(Arena.Client.watching == true or Arena.Client.team == 0)
    if #list == 0 then
        if specTarget then
            NetworkSetInSpectatorMode(false, PlayerPedId())
            specTarget = nil
        end
        SendNUIMessage({ action = 'spectate', visible = true, name = 'Waiting...', hint = L('spectate_hint') })
        return
    end
    specIndex = specIndex + (dir or 0)
    if specIndex < 1 then specIndex = #list end
    if specIndex > #list then specIndex = 1 end
    local row = list[specIndex]
    local ped = pedForServerId(row.id)
    if ped then
        NetworkSetInSpectatorMode(true, ped)
        specTarget = ped
        SendNUIMessage({
            action = 'spectate',
            visible = true,
            name = row.name or GetPlayerName(GetPlayerFromServerId(row.id)) or 'Fighter',
            hint = Arena.Client.watching and L('watching') or L('spectate_hint'),
        })
    end
end

RegisterNetEvent('cursor_arena:client:watchStart', function(lobby)
    Arena.Client.CloseUI()
    Arena.Client.watching = true
    Arena.Client.lobby = lobby
    Arena.Client.inArena = false
    ghost(true)
    Arena.Spectate.Start()
    SendNUIMessage({ action = 'matchHud', visible = true, data = {
        mode = lobby.mode,
        mapName = lobby.mapName,
        scores = lobby.scores,
        round = lobby.round,
        roundsToWin = lobby.roundsToWin,
        killsToWin = lobby.killsToWin,
        players = lobby.players,
        sizeLabel = lobby.sizeLabel,
        state = lobby.state,
        waiting = lobby.state == 'waiting' or lobby.state == 'idle',
        team = 0,
        teamPanel = false,
    } })
end)

RegisterNetEvent('cursor_arena:client:watchStop', function(data)
    Arena.Spectate.Stop()
    Arena.Client.watching = false
    Arena.Client.lobby = nil
    ghost(false)
    SendNUIMessage({ action = 'matchHud', visible = false })
    SendNUIMessage({ action = 'spectate', visible = false })
    if Arena.Client.ReturnToHub then
        Arena.Client.ReturnToHub()
    end
    if not (data and data.silent) then
        lib.notify({ type = 'inform', description = L('watch_left') })
    end
end)

CreateThread(function()
    while true do
        if Arena.Client.spectating or Arena.Client.watching then
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            if Arena.Client.watching then
                if IsControlJustReleased(0, 177) or IsControlJustReleased(0, 202) then -- backspace / ESC
                    TriggerServerEvent('cursor_arena:server:watchLeave')
                end
            end
            if IsControlJustReleased(0, 175) then
                Arena.Spectate.Cycle(1)
            elseif IsControlJustReleased(0, 174) then
                Arena.Spectate.Cycle(-1)
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)
