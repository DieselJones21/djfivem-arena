Arena = Arena or {}

function Arena.Client.OpenUI()
    if Arena.Client.uiOpen then return end
    if Arena.Client.inArena then
        lib.notify({ type = 'error', description = L('already_in_match') })
        return
    end
    if not Arena.Client.inHub then
        lib.notify({ type = 'error', description = L('must_be_in_hub') })
        return
    end

    local bootstrap = lib.callback.await('cursor_arena:getBootstrap', false)
    if not bootstrap then return end

    if Arena.Client.HideHubHint then Arena.Client.HideHubHint() end
    Arena.Client.uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = bootstrap })
end

function Arena.Client.CloseUI()
    Arena.Client.uiOpen = false
    Arena.Client.loadoutOpen = false
    -- Message first, then drop focus. Dropping focus before the callback
    -- returns is a common way to leave NUI overlays stuck on screen.
    SendNUIMessage({ action = 'close' })
    SetNuiFocus(false, false)
end

function Arena.Client.OpenLoadout()
    if not Arena.Client.inArena then return end
    local lobby = Arena.Client.lobby
    if not lobby then return end
    Arena.Client.loadoutOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openLoadout',
        data = {
            loadouts = lobby.loadouts,
            current = { loadoutId = nil, weaponId = nil },
        },
    })
end

RegisterNUICallback('close', function(_, cb)
    local wasOpen = Arena.Client.uiOpen
    Arena.Client.CloseUI()
    if wasOpen and Arena.Client.inHub and not Arena.Client.inArena and Arena.Client.ShowHubHint then
        Arena.Client.ShowHubHint()
    end
    cb({ ok = true })
end)

RegisterNUICallback('listLobbies', function(_, cb)
    cb(lib.callback.await('cursor_arena:listLobbies', false) or {})
end)

RegisterNUICallback('getLobby', function(data, cb)
    cb(lib.callback.await('cursor_arena:getLobby', false, data and data.lobbyId))
end)

RegisterNUICallback('joinLobby', function(data, cb)
    local result = lib.callback.await('cursor_arena:joinLobby', false, data)
    cb(result or { ok = false })
    if result and result.ok then
        Arena.Client.CloseUI()
        if Arena.Client.HideHubHint then Arena.Client.HideHubHint() end
        lib.hideTextUI()
    elseif result and result.message then
        lib.notify({ type = 'error', description = result.message })
    end
end)

RegisterNUICallback('leaveLobby', function(_, cb)
    local result = lib.callback.await('cursor_arena:leaveLobby', false) or { ok = true }
    cb(result)
    Arena.Client.CloseUI()
end)

RegisterNUICallback('setTeam', function(data, cb)
    cb(lib.callback.await('cursor_arena:setTeam', false, data and data.team) or { ok = false })
end)

RegisterNUICallback('changeLoadout', function(data, cb)
    local result = lib.callback.await('cursor_arena:changeLoadout', false, data)
    cb(result or { ok = false })
    if result and result.ok then
        Arena.Client.loadoutOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeLoadout' })
    elseif result and result.message then
        lib.notify({ type = 'error', description = result.message })
    end
end)

RegisterNUICallback('getLeaderboard', function(data, cb)
    cb(lib.callback.await('cursor_arena:getLeaderboard', false, data and data.mode) or {})
end)

RegisterNUICallback('getMyStats', function(_, cb)
    cb(lib.callback.await('cursor_arena:getMyStats', false) or {})
end)

RegisterNUICallback('getHistory', function(_, cb)
    cb(lib.callback.await('cursor_arena:getHistory', false) or {})
end)

RegisterNetEvent('cursor_arena:client:openLoadout', function()
    Arena.Client.OpenLoadout()
end)

RegisterNetEvent('cursor_arena:client:lobbiesDirty', function()
    if Arena.Client.uiOpen then
        SendNUIMessage({ action = 'refreshLobbies' })
    end
end)
