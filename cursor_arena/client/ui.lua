Arena = Arena or {}

function Arena.Client.OpenUI()
    if Arena.Client.uiOpen then return end
    if Arena.Client.inArena then
        lib.notify({ type = 'error', description = L('already_in_match') })
        return
    end

    local bootstrap = lib.callback.await('cursor_arena:getBootstrap', false)
    if not bootstrap then return end

    Arena.Client.uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = bootstrap })
end

function Arena.Client.CloseUI()
    Arena.Client.uiOpen = false
    Arena.Client.loadoutOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
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
    Arena.Client.CloseUI()
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
    if result and result.ok then
        Arena.Client.CloseUI()
    end
    cb(result or { ok = false })
end)

RegisterNUICallback('leaveLobby', function(_, cb)
    cb(lib.callback.await('cursor_arena:leaveLobby', false) or { ok = true })
    Arena.Client.CloseUI()
end)

RegisterNUICallback('setTeam', function(data, cb)
    cb(lib.callback.await('cursor_arena:setTeam', false, data and data.team) or { ok = false })
end)

RegisterNUICallback('changeLoadout', function(data, cb)
    local result = lib.callback.await('cursor_arena:changeLoadout', false, data)
    if result and result.ok then
        Arena.Client.loadoutOpen = false
        SetNuiFocus(false, false)
    end
    cb(result or { ok = false })
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

RegisterNetEvent('cursor_arena:client:openUI', function()
    if Arena.Client.inArena then
        lib.notify({ type = 'error', description = L('already_in_match') })
        return
    end
    Arena.Client.OpenUI()
end)

RegisterNetEvent('cursor_arena:client:openLoadout', function()
    Arena.Client.OpenLoadout()
end)

RegisterNetEvent('cursor_arena:client:lobbiesDirty', function()
    if Arena.Client.uiOpen then
        SendNUIMessage({ action = 'refreshLobbies' })
    end
end)
