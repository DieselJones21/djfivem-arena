Arena = Arena or {}

local lastToggle = 0

local function emptyBootstrap()
    return {
        playerId = GetPlayerServerId(PlayerId()),
        playerName = GetPlayerName(PlayerId()) or 'Player',
        loadouts = {},
        shop = {},
        coins = 0,
        coinLabel = 'Coins',
        maps = {},
        lobbies = {},
        stats = {},
        leaderboard = { ffa = {}, tdm = {}, pvp = {}, showdown = {} },
        history = {},
        inHub = true,
    }
end

function Arena.Client.IsInSpawnLobby()
    local hub = Config.SpawnLobby
    if not hub or not hub.center then
        return Arena.Client.inHub == true
    end
    local c = GetEntityCoords(PlayerPedId())
    -- 2D so a mismatched interior Z cannot keep G dead.
    local dx = c.x - hub.center.x
    local dy = c.y - hub.center.y
    local r = (hub.radius or 150.0) + 8.0
    return (dx * dx + dy * dy) <= (r * r)
end

function Arena.Client.EnsureHubState()
    if not Arena.Client.IsInSpawnLobby() then
        return Arena.Client.inHub == true
    end
    -- Physically in the spawn MLO. Clear leftover match flags so G works.
    if Arena.Client.inArena or Arena.Client.winnerScene or Arena.Client.watching or Arena.Client.frozen then
        Arena.Client.inArena = false
        Arena.Client.winnerScene = false
        Arena.Client.watching = false
        Arena.Client.down = false
        Arena.Client.frozen = false
        Arena.Client.spectating = false
        FreezeEntityPosition(PlayerPedId(), false)
        SetPlayerInvincible(PlayerId(), false)
        if not Arena.Client.uiOpen then
            SendNUIMessage({ action = 'matchHud', visible = false })
            SendNUIMessage({ action = 'matchResult', data = nil })
            SendNUIMessage({ action = 'deathOverlay', visible = false })
            SendNUIMessage({ action = 'countdown', seconds = 0 })
        end
        if Arena.Spectate and Arena.Spectate.Stop then
            Arena.Spectate.Stop()
        end
    end
    if not Arena.Client.inHub then
        Arena.Client.inHub = true
        LocalPlayer.state:set('arenaHub', true, true)
        TriggerServerEvent('cursor_arena:server:setHub', true)
    end
    return true
end

function Arena.Client.OpenUI()
    Arena.Client.EnsureHubState()
    if Arena.Client.watching and not Arena.Client.IsInSpawnLobby() then
        lib.notify({ type = 'error', description = L('already_in_match') })
        return
    end
    if Arena.Client.inArena and not Arena.Client.IsInSpawnLobby() then
        lib.notify({ type = 'error', description = L('already_in_match') })
        return
    end
    if not Arena.Client.inHub and not Arena.Client.IsInSpawnLobby() then
        lib.notify({ type = 'error', description = L('must_be_in_hub') })
        return
    end

    -- Never wait on the server before showing the tablet. A hung
    -- getBootstrap used to swallow G with no notify.
    if Arena.Client.HideHubHint then Arena.Client.HideHubHint() end
    lib.hideTextUI()
    FreezeEntityPosition(PlayerPedId(), false)
    Arena.Client.frozen = false
    Arena.Client.uiOpen = true
    SetNuiFocusKeepInput(false)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = Arena.Client.lastBootstrap or emptyBootstrap() })

    CreateThread(function()
        local ok, bootstrap = pcall(function()
            return lib.callback.await('cursor_arena:getBootstrap', false)
        end)
        if not Arena.Client.uiOpen then return end
        if not ok then
            print('[cursor_arena] getBootstrap error', bootstrap)
            return
        end
        if type(bootstrap) == 'table' then
            Arena.Client.lastBootstrap = bootstrap
            SendNUIMessage({ action = 'open', data = bootstrap })
        end
    end)
end

-- Game-side G only opens. Closing from the same key's release (ox_lib
-- onPressed + control JustReleased) is why the tablet flashed and vanished.
-- Escape / the ✕ button close it.
function Arena.Client.ToggleMenu()
    local now = GetGameTimer()
    if now - lastToggle < 400 then return end
    lastToggle = now
    Arena.Client.EnsureHubState()
    if not Arena.Client.inHub and not Arena.Client.IsInSpawnLobby() then
        lib.notify({ type = 'error', description = L('must_be_in_hub') })
        return
    end
    if Arena.Client.uiOpen then
        -- NUI has exclusive keyboard while focused. If the game still got G,
        -- focus was lost — re-assert the tablet instead of closing it.
        local focused = false
        pcall(function() focused = IsNuiFocused() end)
        if focused then return end
        Arena.Client.OpenUI()
        return
    end
    Arena.Client.OpenUI()
end

function Arena.Client.CloseUI()
    Arena.Client.uiOpen = false
    Arena.Client.loadoutOpen = false
    -- Message first, then drop focus. Dropping focus before the callback
    -- returns is a common way to leave NUI overlays stuck on screen.
    SendNUIMessage({ action = 'close' })
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
end

function Arena.Client.OpenLoadout()
    if not Arena.Client.inArena then return end
    local lobby = Arena.Client.lobby
    if not lobby then return end
    local loadouts = lib.callback.await('cursor_arena:myLoadouts', false)
    Arena.Client.loadoutOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openLoadout',
        data = {
            loadouts = loadouts or lobby.loadouts,
            current = { loadoutId = nil, weaponId = nil },
        },
    })
end

local function nuiAwait(name, payload, fallback)
    local ok, result = pcall(function()
        if payload == nil then
            return lib.callback.await(name, false)
        end
        return lib.callback.await(name, false, payload)
    end)
    if ok then return result end
    print('[cursor_arena] callback', name, result)
    return fallback
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
    cb(nuiAwait('cursor_arena:listLobbies', nil, {}) or {})
end)

RegisterNUICallback('getLobby', function(data, cb)
    cb(nuiAwait('cursor_arena:getLobby', data and data.lobbyId, nil))
end)

RegisterNUICallback('joinLobby', function(data, cb)
    local result = nuiAwait('cursor_arena:joinLobby', data, { ok = false })
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
    local result = nuiAwait('cursor_arena:leaveLobby', nil, { ok = true }) or { ok = true }
    cb(result)
    Arena.Client.CloseUI()
    if Arena.Client.inHub and not Arena.Client.inArena and Arena.Client.ShowHubHint then
        Arena.Client.ShowHubHint()
    end
end)

RegisterNUICallback('setTeam', function(data, cb)
    cb(nuiAwait('cursor_arena:setTeam', data and data.team, { ok = false }) or { ok = false })
end)

RegisterNUICallback('changeLoadout', function(data, cb)
    local result = nuiAwait('cursor_arena:changeLoadout', data, { ok = false })
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
    cb(nuiAwait('cursor_arena:getLeaderboard', data and data.mode, {}) or {})
end)

RegisterNUICallback('getMyStats', function(_, cb)
    cb(nuiAwait('cursor_arena:getMyStats', nil, {}) or {})
end)

RegisterNUICallback('getHistory', function(_, cb)
    cb(nuiAwait('cursor_arena:getHistory', nil, {}) or {})
end)

RegisterNUICallback('watchLobby', function(data, cb)
    local result = nuiAwait('cursor_arena:watchLobby', data and data.lobbyId, { ok = false })
    cb(result or { ok = false })
    if result and result.ok then
        Arena.Client.CloseUI()
    elseif result and result.message then
        lib.notify({ type = 'error', description = result.message })
    end
end)

RegisterNUICallback('placeBet', function(data, cb)
    local result = nuiAwait('cursor_arena:placeBet', data, { ok = false })
    cb(result or { ok = false })
    if result and result.ok then
        lib.notify({ type = 'success', description = L('bet_placed') })
    elseif result and result.message then
        lib.notify({ type = 'error', description = result.message })
    end
end)

RegisterNUICallback('betItems', function(_, cb)
    cb(nuiAwait('cursor_arena:betItems', nil, {}) or {})
end)

RegisterNUICallback('myMoney', function(_, cb)
    cb(nuiAwait('cursor_arena:myMoney', nil, { cash = 0, max = 100000 }) or { cash = 0, max = 100000 })
end)

RegisterNUICallback('createPrivate', function(data, cb)
    local result = nuiAwait('cursor_arena:createPrivate', data, { ok = false })
    cb(result or { ok = false })
    if result and result.ok then
        Arena.Client.CloseUI()
        if Arena.Client.HideHubHint then Arena.Client.HideHubHint() end
        lib.hideTextUI()
    elseif result and result.message then
        lib.notify({ type = 'error', description = result.message })
    end
end)

RegisterNUICallback('joinByCode', function(data, cb)
    local result = nuiAwait('cursor_arena:joinByCode', data, { ok = false })
    cb(result or { ok = false })
    if result and result.ok then
        Arena.Client.CloseUI()
        if Arena.Client.HideHubHint then Arena.Client.HideHubHint() end
        lib.hideTextUI()
    elseif result and result.message then
        lib.notify({ type = 'error', description = result.message })
    end
end)

RegisterNUICallback('watchByCode', function(data, cb)
    local result = nuiAwait('cursor_arena:watchByCode', data, { ok = false })
    cb(result or { ok = false })
    if result and result.ok then
        Arena.Client.CloseUI()
    elseif result and result.message then
        lib.notify({ type = 'error', description = result.message })
    end
end)

RegisterNUICallback('buyShop', function(data, cb)
    local result = nuiAwait('cursor_arena:buyShop', data, { ok = false })
    cb(result or { ok = false })
    if result and result.message and not result.ok then
        lib.notify({ type = 'error', description = result.message })
    elseif result and result.ok and result.bought then
        lib.notify({ type = 'success', description = L('shop_bought') })
    end
end)

RegisterNUICallback('closeLoadout', function(_, cb)
    Arena.Client.loadoutOpen = false
    if not Arena.Client.uiOpen then
        SetNuiFocus(false, false)
    end
    SendNUIMessage({ action = 'closeLoadout' })
    cb({ ok = true })
end)

RegisterNetEvent('cursor_arena:client:openLoadout', function()
    Arena.Client.OpenLoadout()
end)

RegisterNetEvent('cursor_arena:client:lobbiesDirty', function()
    if Arena.Client.uiOpen then
        SendNUIMessage({ action = 'refreshLobbies' })
    end
end)
