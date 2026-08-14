Arena = Arena or {}

function Arena.Client.OpenUI()
    if Arena.Client.uiOpen then return end
    if Arena.Client.inMatch then
        lib.notify({ type = 'error', description = L('already_in_match') })
        return
    end
    if not Arena.Client.inHub then
        lib.notify({ type = 'error', description = L('must_be_in_hub') })
        return
    end

    local bootstrap = lib.callback.await('cursor_arena:getBootstrap', false)
    if not bootstrap then return end

    Arena.Client.uiOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'open',
        data = bootstrap,
    })
end

function Arena.Client.CloseUI(keepSilent)
    if not Arena.Client.uiOpen and not keepSilent then return end
    Arena.Client.uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })

    -- Restore hub hint after closing menu
    if Arena.Client.inHub and not Arena.Client.inMatch and Config.SpawnLobby.hint then
        lib.showTextUI(L('hub_hint'), { position = 'left-center', icon = 'list' })
    end
end

RegisterNUICallback('close', function(_, cb)
    Arena.Client.CloseUI()
    cb({ ok = true })
end)

RegisterNUICallback('exitHub', function(_, cb)
    Arena.Client.CloseUI()
    Arena.Client.ExitHub()
    cb({ ok = true })
end)

RegisterNUICallback('getWeapons', function(data, cb)
    local weapons = lib.callback.await('cursor_arena:getWeaponsForMode', false, data.modeId)
    cb(weapons or {})
end)

RegisterNUICallback('getMaps', function(data, cb)
    local maps = lib.callback.await('cursor_arena:getMapsForMode', false, data.modeId)
    cb(maps or {})
end)

RegisterNUICallback('joinQueue', function(data, cb)
    local result = lib.callback.await('cursor_arena:joinQueue', false, data.modeId, data.weaponId, data.mapId)
    cb(result or { ok = false })
end)

RegisterNUICallback('leaveQueue', function(_, cb)
    lib.callback.await('cursor_arena:leaveQueue', false)
    cb({ ok = true })
end)

RegisterNUICallback('createPrivate', function(data, cb)
    local result = lib.callback.await('cursor_arena:createPrivate', false, data.modeId, data.mapId, data.weaponId)
    cb(result or { ok = false })
end)

RegisterNUICallback('createLobby', function(data, cb)
    local result = lib.callback.await('cursor_arena:createLobby', false, data)
    cb(result or { ok = false })
end)

RegisterNUICallback('getLeaderboard', function(_, cb)
    local list = lib.callback.await('cursor_arena:getLeaderboard', false)
    cb(list or {})
end)

RegisterNUICallback('getMyStats', function(_, cb)
    local stats = lib.callback.await('cursor_arena:getMyStats', false)
    cb(stats or {})
end)

RegisterNUICallback('getWeaponsForClass', function(data, cb)
    local weapons = lib.callback.await('cursor_arena:getWeaponsForClass', false, data.classId)
    cb(weapons or {})
end)

RegisterNUICallback('joinLobby', function(data, cb)
    local result = lib.callback.await('cursor_arena:joinLobby', false, data.matchId, data.weaponId)
    cb(result or { ok = false })
end)

RegisterNUICallback('setReady', function(data, cb)
    local result = lib.callback.await('cursor_arena:setReady', false, data.ready, data.weaponId)
    cb(result or { ok = false })
end)

RegisterNUICallback('setTeam', function(data, cb)
    local result = lib.callback.await('cursor_arena:setTeam', false, data.team)
    cb(result or { ok = false })
end)

RegisterNUICallback('startMatch', function(_, cb)
    local result = lib.callback.await('cursor_arena:startMatch', false)
    cb(result or { ok = false })
end)

RegisterNUICallback('leave', function(_, cb)
    lib.callback.await('cursor_arena:leave', false)
    Arena.Client.CloseUI()
    cb({ ok = true })
end)

RegisterNUICallback('listLobbies', function(_, cb)
    local list = lib.callback.await('cursor_arena:listLobbies', false)
    cb(list or {})
end)

RegisterNUICallback('refreshLobby', function(_, cb)
    local lobby = lib.callback.await('cursor_arena:getLobby', false)
    cb(lobby)
end)

RegisterNUICallback('invite', function(data, cb)
    if data and data.targetId then
        TriggerServerEvent('cursor_arena:server:invite', data.targetId)
    end
    cb({ ok = true })
end)

RegisterNetEvent('cursor_arena:client:lobbyUpdate', function(lobby)
    SendNUIMessage({ action = 'lobbyUpdate', data = lobby })
end)

RegisterNetEvent('cursor_arena:client:queueMatched', function(lobby)
    SendNUIMessage({ action = 'queueMatched', data = lobby })
    lib.notify({ type = 'success', description = L('match_starting', tostring(Config.CountdownSeconds)) })
end)

RegisterNetEvent('cursor_arena:client:invite', function(payload)
    lib.notify({
        type = 'inform',
        title = 'Arena Invite',
        description = L('invite_received', payload.from, payload.modeLabel),
        duration = (payload.timeout or 30) * 1000,
    })
    SendNUIMessage({ action = 'invite', data = payload })
end)
