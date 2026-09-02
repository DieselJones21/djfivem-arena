local spawned = {}

local function hasOxTarget()
    return Config.Target.enabled and GetResourceState('ox_target') == 'started'
end

local function hasQbTarget()
    return Config.Target.enabled and GetResourceState('qb-target') == 'started'
end

local function spawnPed(cfg)
    local model = cfg.model
    lib.requestModel(model)
    local ped = CreatePed(0, model, cfg.coords.x, cfg.coords.y, cfg.coords.z - 1.0, cfg.coords.w or 0.0, false, false)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if cfg.scenario then
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    end
    SetModelAsNoLongerNeeded(model)

    if hasOxTarget() then
        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'cursor_arena_open',
                icon = 'fa-solid fa-crosshairs',
                label = L('target_open'),
                distance = cfg.interactDistance or 2.2,
                onSelect = function()
                    Arena.Client.OpenUI()
                end,
            },
        })
    elseif hasQbTarget() then
        exports['qb-target']:AddTargetEntity(ped, {
            options = {{
                icon = 'fas fa-crosshairs',
                label = L('target_open'),
                action = function()
                    Arena.Client.OpenUI()
                end,
            }},
            distance = cfg.interactDistance or 2.2,
        })
    end

    return ped
end

local function createBlip(cfg)
    if not cfg.blip or cfg.blip.enabled == false then return end
    local blip = AddBlipForCoord(cfg.coords.x, cfg.coords.y, cfg.coords.z)
    SetBlipSprite(blip, cfg.blip.sprite or 437)
    SetBlipColour(blip, cfg.blip.color or 1)
    SetBlipScale(blip, cfg.blip.scale or 0.85)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(cfg.blip.label or 'PVP Arena')
    EndTextCommandSetBlipName(blip)
    return blip
end

CreateThread(function()
    for i = 1, #Config.Peds do
        local cfg = Config.Peds[i]
        spawned[#spawned + 1] = {
            ped = spawnPed(cfg),
            blip = createBlip(cfg),
            cfg = cfg,
        }
    end
end)

-- Prompt fallback when no target resource is running
CreateThread(function()
    if hasOxTarget() or hasQbTarget() then return end
    while true do
        local sleep = 1000
        if not Arena.Client.inArena then
            local coords = GetEntityCoords(PlayerPedId())
            for i = 1, #spawned do
                local cfg = spawned[i].cfg
                local dist = #(coords - vec3(cfg.coords.x, cfg.coords.y, cfg.coords.z))
                if dist < 12.0 then
                    sleep = 0
                    if dist < (cfg.interactDistance or 2.2) then
                        lib.showTextUI(L('enter_prompt'), { position = 'left-center', icon = 'crosshairs' })
                        if IsControlJustReleased(0, 38) then
                            lib.hideTextUI()
                            Arena.Client.OpenUI()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

local function bind(cmd)
    if not cmd or cmd.enable == false then return end
    local name = cmd.name
    lib.addKeybind({
        name = 'cursor_arena_' .. name,
        description = 'Arena: ' .. name,
        defaultKey = cmd.key or '',
        onPressed = function()
            if name == 'arenas' then
                if Arena.Client.uiOpen then
                    Arena.Client.CloseUI()
                else
                    Arena.Client.OpenUI()
                end
            elseif name == 'leavearena' then
                if Arena.Client.inArena then
                    lib.callback.await('cursor_arena:leaveLobby', false)
                end
            elseif name == 'killstreak' then
                Arena.Client.muteStreaks = not Arena.Client.muteStreaks
                lib.notify({
                    type = 'inform',
                    description = L('mute_streaks', Arena.Client.muteStreaks and L('off') or L('on')),
                })
            elseif name == 'arenasounds' then
                Arena.Client.muteSounds = not Arena.Client.muteSounds
                lib.notify({
                    type = 'inform',
                    description = L('mute_sounds', Arena.Client.muteSounds and L('off') or L('on')),
                })
            elseif name == 'changeloadout' then
                Arena.Client.OpenLoadout()
            end
        end,
    })
end

for i = 1, #Config.Commands do
    bind(Config.Commands[i])
end

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for i = 1, #spawned do
        if spawned[i].blip then RemoveBlip(spawned[i].blip) end
        if spawned[i].ped and DoesEntityExist(spawned[i].ped) then DeleteEntity(spawned[i].ped) end
    end
    lib.hideTextUI()
    SetNuiFocus(false, false)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end)
