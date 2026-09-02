local spawned = {}
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
    Wait(250)
    DoScreenFadeIn(500)
end

local function pickHubSpawn()
    return Config.GetHubSpawn and Config.GetHubSpawn() or vec4(5477.79, -5853.01, 1050.58, 78.04)
end

local function addInteract(ped, id, label, cb, dist)
    dist = dist or 2.0
    if Config.Target.enabled ~= false and GetResourceState('interact') == 'started' then
        pcall(function()
            exports.interact:AddLocalEntityInteraction({
                entity = ped,
                id = id,
                name = id,
                distance = 8.0,
                interactDst = dist,
                options = {{
                    label = label,
                    action = function()
                        cb()
                    end,
                }},
            })
        end)
        return 'interact'
    end
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addLocalEntity(ped, {{
            name = id,
            icon = 'fa-solid fa-crosshairs',
            label = label,
            distance = dist,
            onSelect = cb,
        }})
        return 'ox_target'
    end
    if GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddTargetEntity(ped, {
            options = {{
                icon = 'fas fa-crosshairs',
                label = label,
                action = cb,
            }},
            distance = dist,
        })
        return 'qb-target'
    end
    return 'prompt'
end

local function spawnPed(cfg)
    if not cfg or cfg.enabled == false then return end
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
    return ped
end

function Arena.Client.ShowHubHint()
    if Arena.Client.inHub and Config.SpawnLobby.hint and not Arena.Client.inArena and not Arena.Client.uiOpen then
        lib.showTextUI(L('hub_hint'), { position = 'left-center', icon = 'list' })
        hubHintShown = true
    end
end

function Arena.Client.HideHubHint()
    lib.hideTextUI()
    hubHintShown = false
end

function Arena.Client.EnterHub(silent)
    if Arena.Client.inArena then
        lib.notify({ type = 'error', description = L('already_in_match') })
        return
    end
    if Arena.Client.inHub then
        if not silent then
            lib.notify({ type = 'inform', description = L('already_in_hub') })
        end
        return
    end

    local ped = PlayerPedId()
    local c = GetEntityCoords(ped)
    Arena.Client.worldReturnCoords = vec4(c.x, c.y, c.z, GetEntityHeading(ped))
    teleportTo(pickHubSpawn())

    Arena.Client.inHub = true
    LocalPlayer.state:set('arenaHub', true, true)
    TriggerServerEvent('cursor_arena:server:setHub', true)

    Arena.Client.ShowHubHint()
    if not silent then
        lib.notify({ type = 'success', description = L('entered_hub') })
    end
end

function Arena.Client.ExitHub(silent)
    if Arena.Client.inArena then
        lib.notify({ type = 'error', description = L('leave_match_first') })
        return
    end
    if not Arena.Client.inHub then return end

    Arena.Client.CloseUI()
    Arena.Client.inHub = false
    LocalPlayer.state:set('arenaHub', false, true)
    TriggerServerEvent('cursor_arena:server:setHub', false)
    Arena.Client.HideHubHint()

    local exit = Arena.Client.worldReturnCoords
    if not exit and Config.EntryPed then
        local e = Config.EntryPed.coords
        exit = vec4(e.x, e.y, e.z, e.w or 0.0)
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
    Arena.Client.ShowHubHint()
end

function Arena.Client.OpenClothing()
    local res = (Config.ClothingPed and Config.ClothingPed.resource) or 'illenium-appearance'
    if GetResourceState(res) ~= 'started' then
        lib.notify({ type = 'error', description = L('no_appearance') })
        return
    end
    TriggerEvent('illenium-appearance:client:openClothingShop', false)
end

local function createBlip(cfg)
    if not cfg or not cfg.blip or cfg.blip.enabled == false then return end
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
    local entry = spawnPed(Config.EntryPed)
    if entry then
        addInteract(entry, 'cursor_arena_enter', Config.EntryPed.interactLabel or L('target_open'), function()
            Arena.Client.EnterHub()
        end, Config.EntryPed.interactDistance)
        spawned[#spawned + 1] = { ped = entry, blip = createBlip(Config.EntryPed), cfg = Config.EntryPed, kind = 'entry' }
    end

    local exitPed = spawnPed(Config.ExitPed)
    if exitPed then
        addInteract(exitPed, 'cursor_arena_exit', Config.ExitPed.interactLabel or L('target_exit'), function()
            Arena.Client.ExitHub()
        end, Config.ExitPed.interactDistance)
        spawned[#spawned + 1] = { ped = exitPed, cfg = Config.ExitPed, kind = 'exit' }
    end

    local clothes = spawnPed(Config.ClothingPed)
    if clothes then
        addInteract(clothes, 'cursor_arena_clothes', Config.ClothingPed.interactLabel or L('target_clothes'), function()
            Arena.Client.OpenClothing()
        end, Config.ClothingPed.interactDistance)
        spawned[#spawned + 1] = { ped = clothes, cfg = Config.ClothingPed, kind = 'clothes' }
    end
end)

-- Prompt fallback when interact / target is not running
CreateThread(function()
    if GetResourceState('interact') == 'started' or GetResourceState('ox_target') == 'started' or GetResourceState('qb-target') == 'started' then
        return
    end
    local promptShown = false
    while true do
        local sleep = 800
        local coords = GetEntityCoords(PlayerPedId())
        local shown
        for i = 1, #spawned do
            local row = spawned[i]
            local cfg = row.cfg
            if cfg and cfg.coords then
                local dist = #(coords - vec3(cfg.coords.x, cfg.coords.y, cfg.coords.z))
                local inRange = dist < (cfg.interactDistance or 2.0)
                local allowed = (row.kind == 'entry' and not Arena.Client.inHub and not Arena.Client.inArena)
                    or (row.kind ~= 'entry' and Arena.Client.inHub and not Arena.Client.inArena)
                if inRange and allowed then
                    sleep = 0
                    shown = row.kind == 'entry' and L('enter_prompt') or (row.kind == 'exit' and L('exit_prompt') or L('clothes_prompt'))
                    if IsControlJustReleased(0, 38) then
                        if row.kind == 'entry' then Arena.Client.EnterHub()
                        elseif row.kind == 'exit' then Arena.Client.ExitHub()
                        else Arena.Client.OpenClothing() end
                    end
                end
            end
        end
        if shown then
            lib.showTextUI(shown, { position = 'left-center' })
            promptShown = true
        elseif promptShown then
            lib.hideTextUI()
            promptShown = false
            Arena.Client.ShowHubHint()
        end
        Wait(sleep)
    end
end)

CreateThread(function()
    while true do
        local sleep = 1000
        local hub = Config.SpawnLobby
        if Arena.Client.inHub and not Arena.Client.inArena and hub and hub.enforceBounds and hub.center then
            sleep = 400
            if #(GetEntityCoords(PlayerPedId()) - hub.center) > (hub.radius or 40.0) then
                local spawn = pickHubSpawn()
                SetEntityCoordsNoOffset(PlayerPedId(), spawn.x, spawn.y, spawn.z, false, false, false)
                lib.notify({ type = 'error', description = L('out_of_bounds') })
            end
        end
        Wait(sleep)
    end
end)

lib.addKeybind({
    name = 'cursor_arena_menu',
    description = 'Open Arena menu (spawn lobby only)',
    defaultKey = Config.MenuKey or 'G',
    onPressed = function()
        if Arena.Client.inArena then return end
        if not Arena.Client.inHub then
            lib.notify({ type = 'error', description = L('must_be_in_hub') })
            return
        end
        if Arena.Client.uiOpen then
            Arena.Client.CloseUI()
            Arena.Client.ShowHubHint()
        else
            Arena.Client.OpenUI()
        end
    end,
})

local function bind(cmd)
    if not cmd or cmd.enable == false then return end
    if cmd.name == 'arenas' then return end -- G keybind above
    lib.addKeybind({
        name = 'cursor_arena_' .. cmd.name,
        description = 'Arena: ' .. cmd.name,
        defaultKey = cmd.key or '',
        onPressed = function()
            if cmd.name == 'leavearena' then
                if Arena.Client.inArena then
                    lib.callback.await('cursor_arena:leaveLobby', false)
                elseif Arena.Client.inHub then
                    Arena.Client.ExitHub()
                end
            elseif cmd.name == 'killstreak' then
                Arena.Client.muteStreaks = not Arena.Client.muteStreaks
                lib.notify({ type = 'inform', description = L('mute_streaks', Arena.Client.muteStreaks and L('off') or L('on')) })
            elseif cmd.name == 'arenasounds' then
                Arena.Client.muteSounds = not Arena.Client.muteSounds
                lib.notify({ type = 'inform', description = L('mute_sounds', Arena.Client.muteSounds and L('off') or L('on')) })
            elseif cmd.name == 'changeloadout' then
                Arena.Client.OpenLoadout()
            end
        end,
    })
end

for i = 1, #Config.Commands do
    bind(Config.Commands[i])
end

RegisterNetEvent('cursor_arena:client:openUI', function()
    if Arena.Client.inArena then
        lib.notify({ type = 'error', description = L('already_in_match') })
        return
    end
    if Arena.Client.inHub then
        Arena.Client.OpenUI()
    else
        Arena.Client.EnterHub()
    end
end)

RegisterNetEvent('cursor_arena:client:exitHub', function()
    Arena.Client.ExitHub()
end)

RegisterNetEvent('cursor_arena:client:blockInventory', function(blocked)
    Arena.Client.invBlocked = blocked == true
    -- invBusy must stay false or ox_inventory disables shooting
    LocalPlayer.state:set('invBusy', false, true)
    LocalPlayer.state:set('invHotkeys', not Arena.Client.invBlocked, true)
    LocalPlayer.state:set('canUseWeapons', true, true)
    if Arena.Client.invBlocked and GetResourceState('ox_inventory') == 'started' then
        pcall(function()
            exports.ox_inventory:closeInventory()
        end)
    end
end)

local function oxOn()
    return GetResourceState('ox_inventory') == 'started'
end

local function findOxSlot(weaponName, preferred)
    if preferred then return tonumber(preferred) or preferred end
    if not oxOn() or not weaponName then return end
    local names = { weaponName, weaponName:upper(), weaponName:lower() }
    for i = 1, #names do
        local ok, result = pcall(function()
            return exports.ox_inventory:Search('slots', names[i])
        end)
        if ok and type(result) == 'table' then
            for _, data in pairs(result) do
                if type(data) == 'table' and data.slot then
                    return data.slot
                end
            end
        end
    end
end

local function applyAmmo(ped, hash, ammo)
    SetPedInfiniteAmmo(ped, true, hash)
    SetPedInfiniteAmmoClip(ped, true)
    if ammo then SetPedAmmo(ped, hash, ammo) end
    SetPedCurrentWeaponVisible(ped, true, true, true, true)
end

local equipGen = 0
local lastEquipRetryAt = 0

local function weaponInHands(ped, hash, ammo)
    if not HasPedGotWeapon(ped, hash, false) then return false end
    SetCurrentPedWeapon(ped, hash, true)
    applyAmmo(ped, hash, ammo)
    Arena.Client.equipRetries = 0
    return true
end

local function tryUseSlot(weaponName)
    local use = findOxSlot(weaponName, Arena.Client.weaponSlot)
    if not use then
        use = findOxSlot(weaponName)
    end
    if use then
        Arena.Client.weaponSlot = use
        pcall(function()
            exports.ox_inventory:useSlot(tonumber(use) or use)
        end)
        return true
    end
    return false
end

-- Equip through ox_inventory so it owns the gun. GiveWeaponToPed fights ox
-- (weapon flashes every tick and DisablePlayerFiring / disarm blocks shots).
function Arena.Client.EquipWeapon(weaponName, ammo, slot)
    if not weaponName then return end
    ammo = ammo or 9999
    Arena.Client.weaponName = weaponName
    if slot then Arena.Client.weaponSlot = slot end
    local hash = joaat(weaponName)

    equipGen = equipGen + 1
    local gen = equipGen

    LocalPlayer.state:set('invBusy', false, true)
    LocalPlayer.state:set('canUseWeapons', true, true)
    SetWeaponsNoAutoswap(true)
    SetPedCanSwitchWeapon(PlayerPedId(), false)
    SetPlayerCanDoDriveBy(PlayerId(), false)

    CreateThread(function()
        while Arena.Client.frozen and gen == equipGen do
            Wait(50)
        end
        if gen ~= equipGen then return end
        local ped = PlayerPedId()
        if oxOn() then
            if weaponInHands(ped, hash, ammo) then return end
            local equipped
            pcall(function()
                equipped = exports.ox_inventory:getCurrentWeapon()
            end)
            if equipped and (equipped.hash == hash or equipped.name and joaat(equipped.name) == hash) then
                if weaponInHands(ped, hash, ammo) then return end
            end

            tryUseSlot(weaponName)
            local deadline = GetGameTimer() + 4000
            local nextUse = GetGameTimer() + 400
            while GetGameTimer() < deadline do
                if gen ~= equipGen then return end
                ped = PlayerPedId()
                if weaponInHands(ped, hash, ammo) then return end
                if GetGameTimer() >= nextUse then
                    tryUseSlot(weaponName)
                    nextUse = GetGameTimer() + 450
                end
                Wait(80)
            end

            -- Item may not have replicated yet. Ask the server to re-send the slot.
            local now = GetGameTimer()
            Arena.Client.equipRetries = (Arena.Client.equipRetries or 0) + 1
            if Arena.Client.equipRetries <= 2 and now - lastEquipRetryAt > 1500 then
                lastEquipRetryAt = now
                TriggerServerEvent('cursor_arena:server:equipRetry')
            end
            -- Last resort: native give so the player can still fire this match.
            ped = PlayerPedId()
            GiveWeaponToPed(ped, hash, ammo, false, true)
            SetCurrentPedWeapon(ped, hash, true)
            applyAmmo(ped, hash, ammo)
            return
        end

        GiveWeaponToPed(ped, hash, ammo, false, true)
        SetCurrentPedWeapon(ped, hash, true)
        applyAmmo(ped, hash, ammo)
        Arena.Client.equipRetries = 0
    end)
end

function Arena.Client.HolsterArenaWeapon()
    if oxOn() then
        pcall(function()
            TriggerEvent('ox_inventory:disarm', true)
        end)
    else
        RemoveAllPedWeapons(PlayerPedId(), true)
    end
    Arena.Client.weaponName = nil
    Arena.Client.weaponSlot = nil
    SetWeaponsNoAutoswap(false)
    SetPedCanSwitchWeapon(PlayerPedId(), true)
end

RegisterNetEvent('cursor_arena:client:equipWeapon', function(weaponName, ammo, slot)
    Arena.Client.EquipWeapon(weaponName, ammo, slot)
end)

RegisterNetEvent('cursor_arena:client:giveWeaponFallback', function(weaponName, ammo)
    Arena.Client.EquipWeapon(weaponName, ammo)
end)

RegisterNetEvent('cursor_arena:client:stripWeapons', function()
    Arena.Client.HolsterArenaWeapon()
end)

CreateThread(function()
    while true do
        if Arena.Client.invBlocked then
            DisableControlAction(0, 289, true) -- F2 inventory
            DisableControlAction(0, 37, true)  -- weapon wheel
            HideHudComponentThisFrame(19)
            if LocalPlayer.state.invBusy then
                LocalPlayer.state:set('invBusy', false, true)
            end
            if LocalPlayer.state.invOpen and oxOn() then
                pcall(function()
                    exports.ox_inventory:closeInventory()
                end)
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)

CreateThread(function()
    local missingSince = 0
    while true do
        if Arena.Client.inArena and Arena.Client.weaponName and not Arena.Client.frozen and not Arena.Client.down and not Arena.Client.spectating then
            local ped = PlayerPedId()
            local hash = joaat(Arena.Client.weaponName)
            HideHudComponentThisFrame(19)
            if HasPedGotWeapon(ped, hash, false) then
                missingSince = 0
                SetPedInfiniteAmmo(ped, true, hash)
                SetPedInfiniteAmmoClip(ped, true)
                if GetAmmoInPedWeapon(ped, hash) < 40 then
                    SetPedAmmo(ped, hash, 9999)
                end
                local current = GetSelectedPedWeapon(ped)
                if current == `WEAPON_UNARMED` or current == 0 then
                    SetCurrentPedWeapon(ped, hash, true)
                end
            else
                if missingSince == 0 then
                    missingSince = GetGameTimer()
                elseif GetGameTimer() - missingSince > 900 then
                    missingSince = GetGameTimer()
                    Arena.Client.EquipWeapon(Arena.Client.weaponName, 9999, Arena.Client.weaponSlot)
                end
            end
            Wait(400)
        else
            missingSince = 0
            Wait(800)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for i = 1, #spawned do
        if spawned[i].blip then RemoveBlip(spawned[i].blip) end
        if spawned[i].ped and DoesEntityExist(spawned[i].ped) then DeleteEntity(spawned[i].ped) end
    end
    lib.hideTextUI()
    SetNuiFocus(false, false)
    SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
    SetWeaponsNoAutoswap(false)
end)
