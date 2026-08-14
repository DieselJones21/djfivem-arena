Arena = Arena or {}
Arena.Inventory = {}

--[[
    Uses ox_inventory ConfiscateInventory / ReturnInventory when available.
    Falls back to an in-memory snapshot keyed by player identifier.
]]

local stashed = {} -- [src] = { method = 'confiscate'|'snapshot', items = optional }

local function oxReady()
    return Config.OxInventory.enabled and GetResourceState('ox_inventory') == 'started'
end

local function identifier(src)
    return Arena.Framework.GetIdentifier(src) or tostring(src)
end

local function snapshotItems(src)
    local items = {}
    local inventory = exports.ox_inventory:GetInventoryItems(src)
    if not inventory then return items end

    for _, item in pairs(inventory) do
        if item and item.name and item.count and item.count > 0 then
            items[#items + 1] = {
                name = item.name,
                count = item.count,
                metadata = item.metadata,
                slot = item.slot,
            }
        end
    end
    return items
end

local function giveItems(src, items)
    if not items then return end
    for i = 1, #items do
        local item = items[i]
        if item and item.name and item.count and item.count > 0 then
            local ok = exports.ox_inventory:AddItem(src, item.name, item.count, item.metadata)
            if not ok then
                Arena.Utils.Debug('Failed to restore item', item.name, 'for', src)
            end
        end
    end
end

function Arena.Inventory.IsStashed(src)
    return stashed[src] ~= nil
end

function Arena.Inventory.StashPlayer(src)
    if not oxReady() then return true end
    if stashed[src] then return true end

    -- Preferred: built-in confiscate (stores + clears reliably across ox_inventory versions)
    local confiscateOk = pcall(function()
        exports.ox_inventory:ConfiscateInventory(src)
    end)

    if confiscateOk then
        stashed[src] = { method = 'confiscate', id = identifier(src) }
        Arena.Utils.Debug('Confiscated inventory for', src)
        return true
    end

    -- Fallback: snapshot then clear
    local items = snapshotItems(src)
    exports.ox_inventory:ClearInventory(src)
    stashed[src] = { method = 'snapshot', id = identifier(src), items = items }
    Arena.Utils.Debug('Snapshot stashed inventory for', src, #items, 'stacks')
    return true
end

function Arena.Inventory.RestorePlayer(src)
    if not oxReady() then return true end

    local entry = stashed[src]
    if not entry then
        -- Recovery: try return even if our flag was lost (e.g. resource restart mid-match)
        pcall(function()
            exports.ox_inventory:ReturnInventory(src)
        end)
        return true
    end

    -- Always strip arena loadout first
    pcall(function()
        exports.ox_inventory:ClearInventory(src)
    end)

    Wait(50)

    if entry.method == 'confiscate' then
        local ok, err = pcall(function()
            exports.ox_inventory:ReturnInventory(src)
        end)
        if not ok then
            Arena.Utils.Debug('ReturnInventory failed', err)
            -- last resort: if we somehow still have snapshot data
            if entry.items then
                giveItems(src, entry.items)
            end
        end
    elseif entry.method == 'snapshot' then
        giveItems(src, entry.items)
    end

    stashed[src] = nil
    Arena.Utils.Debug('Restored inventory for', src)
    return true
end

function Arena.Inventory.GiveLoadout(src, weaponDef)
    if not weaponDef then return false end

    if oxReady() then
        -- Do NOT clear here if we already confiscated — only clear leftover loadout
        if Config.OxInventory.clearBeforeLoadout then
            -- Safe clear of current (empty / partial) player inv without touching confiscated store
            local current = exports.ox_inventory:GetInventoryItems(src)
            if current then
                for _, item in pairs(current) do
                    if item and item.name and item.count and item.count > 0 then
                        exports.ox_inventory:RemoveItem(src, item.name, item.count, item.metadata, item.slot)
                    end
                end
            end
        end

        local metadata = {
            ammo = weaponDef.ammo or 0,
            registered = false,
            durability = 100,
        }

        local weaponName = weaponDef.weapon
        local ok = exports.ox_inventory:AddItem(src, weaponName, 1, metadata)
        if not ok then
            ok = exports.ox_inventory:AddItem(src, weaponName:lower(), 1, metadata)
        end

        if weaponDef.ammoItem and (weaponDef.ammo or 0) > 0 then
            exports.ox_inventory:AddItem(src, weaponDef.ammoItem, weaponDef.ammo)
        end

        if Config.OxInventory.extras then
            for i = 1, #Config.OxInventory.extras do
                local extra = Config.OxInventory.extras[i]
                if extra.item then
                    exports.ox_inventory:AddItem(src, extra.item, extra.count or 1, extra.metadata)
                end
            end
        end

        return ok ~= false
    end

    TriggerClientEvent('cursor_arena:client:giveWeaponFallback', src, weaponDef.weapon, weaponDef.ammo or 0)
    return true
end

function Arena.Inventory.ClearLoadout(src)
    if not oxReady() then
        TriggerClientEvent('cursor_arena:client:stripWeapons', src)
        return
    end

    -- Only clear the active inventory (arena weapons), never touch confiscated store
    local current = exports.ox_inventory:GetInventoryItems(src)
    if current then
        for _, item in pairs(current) do
            if item and item.name and item.count and item.count > 0 then
                exports.ox_inventory:RemoveItem(src, item.name, item.count, item.metadata, item.slot)
            end
        end
    end
end

function Arena.Inventory.RefillAmmo(src, weaponDef)
    if not weaponDef or not oxReady() then return end
    if weaponDef.ammoItem and (weaponDef.ammo or 0) > 0 then
        local current = exports.ox_inventory:Search(src, 'count', weaponDef.ammoItem) or 0
        local need = weaponDef.ammo - current
        if need > 0 then
            exports.ox_inventory:AddItem(src, weaponDef.ammoItem, need)
        end
    end
end

AddEventHandler('playerDropped', function()
    local src = source
    if stashed[src] then
        -- Try restore before player fully drops so items are not lost
        Arena.Inventory.RestorePlayer(src)
    end
end)

lib.addCommand('arena_restoreinv', {
    help = 'Force-return arena confiscated inventory for a player',
    restricted = Config.Permissions.adminAce,
    params = {
        { name = 'id', type = 'playerId', help = 'Player server id' },
    },
}, function(source, args)
    local target = args.id
    if not target then return end

    -- Force flag so RestorePlayer always attempts ReturnInventory
    if not stashed[target] then
        stashed[target] = { method = 'confiscate', id = identifier(target) }
    end
    Arena.Inventory.RestorePlayer(target)
    Arena.Utils.Notify(source, { type = 'success', description = 'Inventory restore attempted for ' .. tostring(target) })
    Arena.Utils.Notify(target, { type = 'inform', description = L('inventory_restored') })
end)
