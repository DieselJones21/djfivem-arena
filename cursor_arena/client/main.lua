Arena = Arena or {}

local lobbyBlip
local lobbyPed

local function spawnLobbyPed()
    local cfg = Config.Lobby
    if not cfg.enabled or not cfg.ped or not cfg.ped.enabled then return end

    local model = cfg.ped.model
    lib.requestModel(model)

    lobbyPed = CreatePed(0, model, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, cfg.heading or 0.0, false, false)
    SetEntityInvincible(lobbyPed, true)
    SetBlockingOfNonTemporaryEvents(lobbyPed, true)
    FreezeEntityPosition(lobbyPed, true)
    if cfg.ped.scenario then
        TaskStartScenarioInPlace(lobbyPed, cfg.ped.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)
end

local function createLobbyBlip()
    local cfg = Config.Lobby
    if not cfg.enabled or not cfg.blip or not cfg.blip.enabled then return end

    lobbyBlip = AddBlipForCoord(cfg.coords.x, cfg.coords.y, cfg.coords.z)
    SetBlipSprite(lobbyBlip, cfg.blip.sprite)
    SetBlipColour(lobbyBlip, cfg.blip.color)
    SetBlipScale(lobbyBlip, cfg.blip.scale)
    SetBlipAsShortRange(lobbyBlip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(cfg.blip.label or 'PVP Arena')
    EndTextCommandSetBlipName(lobbyBlip)
end

CreateThread(function()
    createLobbyBlip()
    spawnLobbyPed()
end)

CreateThread(function()
    local cfg = Config.Lobby
    if not cfg.enabled then return end

    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - cfg.coords)

        if dist < cfg.drawDistance then
            sleep = 0
            local m = cfg.marker
            DrawMarker(
                m.type,
                cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                m.scale.x, m.scale.y, m.scale.z,
                m.color.r, m.color.g, m.color.b, m.color.a,
                m.bob, m.faceCamera, 2, false, nil, nil, false
            )

            if dist < cfg.interactDistance then
                lib.showTextUI(L('open_prompt'), { position = 'left-center', icon = 'crosshairs' })
                if IsControlJustReleased(0, 38) then -- E
                    lib.hideTextUI()
                    Arena.Client.OpenUI()
                end
            else
                lib.hideTextUI()
            end
        end

        Wait(sleep)
    end
end)

if Config.OpenKey then
    lib.addKeybind({
        name = 'cursor_arena_open',
        description = 'Open PVP Arena',
        defaultKey = Config.OpenKey,
        onPressed = function()
            if Arena.Client.inMatch then return end
            Arena.Client.OpenUI()
        end,
    })
end

RegisterNetEvent('cursor_arena:client:openUI', function()
    Arena.Client.OpenUI()
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
    if lobbyBlip then RemoveBlip(lobbyBlip) end
    if lobbyPed and DoesEntityExist(lobbyPed) then DeleteEntity(lobbyPed) end
    lib.hideTextUI()
    SetNuiFocus(false, false)
end)
