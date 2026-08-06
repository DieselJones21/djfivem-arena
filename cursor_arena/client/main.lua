Arena = Arena or {}

local entryBlip
local entryPed
local exitPed
local hubHintShown = false

local function teleportTo(coords)
    if not coords then return end
    local ped = PlayerPedId()
    DoScreenFadeOut(400)
    while not IsScreenFadedOut() do Wait(0) end
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    if coords.w then SetEntityHeading(ped, coords.w) end
    ClearPedTasksImmediately(ped)
    Wait(300)
    DoScreenFadeIn(500)
end

local function pickHubSpawn()
    local spawns = Config.SpawnLobby.spawns
    if not spawns or #spawns == 0 then
        return vec4(405.0, -997.0, -99.0, 90.0)
    end
    return spawns[math.random(#spawns)]
end

function Arena.Client.EnterHub(silent)
    if Arena.Client.inMatch then
        lib.notify({ type = 'error', description = L('already_in_match') })
        return
    end
    if Arena.Client.inHub then
        if not silent then
            lib.notify({ type = 'inform', description = L('already_in_hub') })
        end
        return
    end

    Arena.Client.worldReturnCoords = GetEntityCoords(PlayerPedId())
    local spawn = pickHubSpawn()
    teleportTo(spawn)

    Arena.Client.inHub = true
    LocalPlayer.state:set('arenaHub', true, true)
    TriggerServerEvent('cursor_arena:server:setHub', true)

    if Config.SpawnLobby.hint then
        lib.showTextUI(L('hub_hint'), { position = 'left-center', icon = 'list' })
        hubHintShown = true
    end

    if not silent then
        lib.notify({ type = 'success', description = L('entered_hub') })
    end
end

function Arena.Client.ExitHub(silent)
    if Arena.Client.inMatch then
        lib.notify({ type = 'error', description = L('leave_match_first') })
        return
    end
    if not Arena.Client.inHub then return end

    Arena.Client.CloseUI()
    lib.callback.await('cursor_arena:leave', false)

    local exit = Config.SpawnLobby.exitCoords or Config.EntryPed and vec4(
        Config.EntryPed.coords.x,
        Config.EntryPed.coords.y,
        Config.EntryPed.coords.z,
        Config.EntryPed.heading or 0.0
    )

    Arena.Client.inHub = false
    LocalPlayer.state:set('arenaHub', false, true)
    TriggerServerEvent('cursor_arena:server:setHub', false)

    if hubHintShown then
        lib.hideTextUI()
        hubHintShown = false
    end

    teleportTo(exit)

    if not silent then
        lib.notify({ type = 'inform', description = L('left_hub') })
    end
end

function Arena.Client.ReturnToHub()
    local spawn = pickHubSpawn()
    teleportTo(spawn)
    Arena.Client.inHub = true
    LocalPlayer.state:set('arenaHub', true, true)
    TriggerServerEvent('cursor_arena:server:setHub', true)

    if Config.SpawnLobby.hint and not hubHintShown then
        lib.showTextUI(L('hub_hint'), { position = 'left-center', icon = 'list' })
        hubHintShown = true
    end
end

local function spawnEntryPed()
    local cfg = Config.EntryPed
    if not cfg or not cfg.enabled or not cfg.ped or not cfg.ped.enabled then return end

    local model = cfg.ped.model
    lib.requestModel(model)
    entryPed = CreatePed(0, model, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, cfg.heading or 0.0, false, false)
    SetEntityInvincible(entryPed, true)
    SetBlockingOfNonTemporaryEvents(entryPed, true)
    FreezeEntityPosition(entryPed, true)
    if cfg.ped.scenario then
        TaskStartScenarioInPlace(entryPed, cfg.ped.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)
end

local function spawnExitPed()
    local cfg = Config.SpawnLobby.exitPed
    if not cfg or not cfg.enabled then return end

    local model = cfg.model
    lib.requestModel(model)
    exitPed = CreatePed(0, model, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, cfg.heading or 0.0, false, false)
    SetEntityInvincible(exitPed, true)
    SetBlockingOfNonTemporaryEvents(exitPed, true)
    FreezeEntityPosition(exitPed, true)
    if cfg.scenario then
        TaskStartScenarioInPlace(exitPed, cfg.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)
end

local function createEntryBlip()
    local cfg = Config.EntryPed
    if not cfg or not cfg.enabled or not cfg.blip or not cfg.blip.enabled then return end

    entryBlip = AddBlipForCoord(cfg.coords.x, cfg.coords.y, cfg.coords.z)
    SetBlipSprite(entryBlip, cfg.blip.sprite)
    SetBlipColour(entryBlip, cfg.blip.color)
    SetBlipScale(entryBlip, cfg.blip.scale)
    SetBlipAsShortRange(entryBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(cfg.blip.label or 'PVP Arena')
    EndTextCommandSetBlipName(entryBlip)
end

CreateThread(function()
    createEntryBlip()
    spawnEntryPed()
    spawnExitPed()
end)

-- World entry ped: teleport into spawn lobby (does not open UI)
CreateThread(function()
    local cfg = Config.EntryPed
    if not cfg or not cfg.enabled then return end

    while true do
        local sleep = 1000
        if not Arena.Client.inHub and not Arena.Client.inMatch then
            local coords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - cfg.coords)

            if dist < cfg.drawDistance then
                sleep = 0
                local m = cfg.marker
                if m then
                    DrawMarker(
                        m.type,
                        cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        m.scale.x, m.scale.y, m.scale.z,
                        m.color.r, m.color.g, m.color.b, m.color.a,
                        m.bob, m.faceCamera, 2, false, nil, nil, false
                    )
                end

                if dist < cfg.interactDistance then
                    lib.showTextUI(L('enter_prompt'), { position = 'left-center', icon = 'door-open' })
                    if IsControlJustReleased(0, 38) then -- E
                        lib.hideTextUI()
                        Arena.Client.EnterHub()
                    end
                else
                    lib.hideTextUI()
                end
            end
        end
        Wait(sleep)
    end
end)

-- Hub exit ped
CreateThread(function()
    local cfg = Config.SpawnLobby.exitPed
    if not cfg or not cfg.enabled then return end

    while true do
        local sleep = 1000
        if Arena.Client.inHub and not Arena.Client.inMatch then
            local coords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - cfg.coords)
            if dist < (cfg.interactDistance or 2.0) + 8.0 then
                sleep = 0
                if dist < (cfg.interactDistance or 2.0) then
                    lib.showTextUI(L('exit_prompt'), { position = 'left-center', icon = 'door-closed' })
                    if IsControlJustReleased(0, 38) then
                        lib.hideTextUI()
                        Arena.Client.ExitHub()
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- Soft bounds inside spawn lobby hub
CreateThread(function()
    while true do
        local sleep = 1000
        local hub = Config.SpawnLobby
        if Arena.Client.inHub and not Arena.Client.inMatch and hub.enforceBounds and hub.center and hub.radius then
            sleep = 400
            local coords = GetEntityCoords(PlayerPedId())
            local dist = #(coords - hub.center)
            if dist > hub.radius then
                local spawn = pickHubSpawn()
                SetEntityCoordsNoOffset(PlayerPedId(), spawn.x, spawn.y, spawn.z, false, false, false)
                if spawn.w then SetEntityHeading(PlayerPedId(), spawn.w) end
                lib.notify({ type = 'error', description = L('out_of_bounds') })
            end
        end
        Wait(sleep)
    end
end)

-- G opens the lobby UI only while inside the spawn lobby
lib.addKeybind({
    name = 'cursor_arena_menu',
    description = 'Open Arena lobbies (spawn lobby only)',
    defaultKey = Config.MenuKey or 'G',
    onPressed = function()
        if Arena.Client.inMatch then return end
        if not Arena.Client.inHub then
            lib.notify({ type = 'error', description = L('must_be_in_hub') })
            return
        end
        if Arena.Client.uiOpen then
            Arena.Client.CloseUI()
        else
            if hubHintShown then
                lib.hideTextUI()
                hubHintShown = false
            end
            Arena.Client.OpenUI()
        end
    end,
})

RegisterNetEvent('cursor_arena:client:openUI', function()
    if Arena.Client.inHub and not Arena.Client.inMatch then
        Arena.Client.OpenUI()
    elseif not Arena.Client.inHub then
        Arena.Client.EnterHub()
    end
end)

RegisterNetEvent('cursor_arena:client:enterHub', function()
    Arena.Client.EnterHub()
end)

RegisterNetEvent('cursor_arena:client:exitHub', function()
    Arena.Client.ExitHub()
end)

RegisterNetEvent('cursor_arena:client:giveWeaponFallback', function(weaponName, ammo)
    local ped = PlayerPedId()
    local hash = joaat(weaponName)
    GiveWeaponToPed(ped, hash, ammo or 0, false, true)
    SetCurrentPedWeapon(ped, hash, true)
    if Config.Rules.infiniteAmmo then
        SetPedInfiniteAmmo(ped, true, hash)
    end
end)

RegisterNetEvent('cursor_arena:client:stripWeapons', function()
    RemoveAllPedWeapons(PlayerPedId(), true)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if entryBlip then RemoveBlip(entryBlip) end
    if entryPed and DoesEntityExist(entryPed) then DeleteEntity(entryPed) end
    if exitPed and DoesEntityExist(exitPed) then DeleteEntity(exitPed) end
    lib.hideTextUI()
    SetNuiFocus(false, false)
end)
