Arena = Arena or {}
Arena.Inventory = {}

local stashed = {}

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
            exports.ox_inventory:AddItem(src, item.name, item.count, item.metadata)
        end
    end
end

function Arena.Inventory.IsStashed(src)
    return stashed[src] ~= nil
end

function Arena.Inventory.StashPlayer(src)
    if not oxReady() then return true end
    if stashed[src] then return true end

    local confiscateOk = pcall(function()
        exports.ox_inventory:ConfiscateInventory(src)
    end)

    if confiscateOk then
        stashed[src] = { method = 'confiscate', id = identifier(src) }
        return true
    end

    local items = snapshotItems(src)
    exports.ox_inventory:ClearInventory(src)
    stashed[src] = { method = 'snapshot', id = identifier(src), items = items }
    return true
end

function Arena.Inventory.RestorePlayer(src)
    if not oxReady() then return true end

    local entry = stashed[src]
    if not entry then
        pcall(function()
            exports.ox_inventory:ReturnInventory(src)
        end)
        return true
    end

    pcall(function()
        exports.ox_inventory:ClearInventory(src)
    end)
    Wait(50)

    if entry.method == 'confiscate' then
        local ok = pcall(function()
            exports.ox_inventory:ReturnInventory(src)
        end)
        if not ok and entry.items then
            giveItems(src, entry.items)
        end
    elseif entry.method == 'snapshot' then
        giveItems(src, entry.items)
    end

    stashed[src] = nil
    return true
end

function Arena.Inventory.GiveLoadout(src, weaponDef)
    if not weaponDef then return false end

    if oxReady() then
        if Config.OxInventory.clearBeforeLoadout then
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

        local ok = exports.ox_inventory:AddItem(src, weaponDef.weapon, 1, metadata)
        if not ok then
            ok = exports.ox_inventory:AddItem(src, weaponDef.weapon:lower(), 1, metadata)
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
    if not stashed[target] then
        stashed[target] = { method = 'confiscate', id = identifier(target) }
    end
    Arena.Inventory.RestorePlayer(target)
    Arena.Utils.Notify(source, { type = 'success', description = 'Inventory restore attempted for ' .. tostring(target) })
    Arena.Utils.Notify(target, { type = 'inform', description = L('inventory_restored') })
end)
