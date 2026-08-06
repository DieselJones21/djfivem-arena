Arena = Arena or {}
Arena.Inventory = {}

local stashed = {} -- [src] = true when stashed

local function oxReady()
    return Config.OxInventory.enabled and GetResourceState('ox_inventory') == 'started'
end

function Arena.Inventory.IsStashed(src)
    return stashed[src] == true
end

--- Move player items into a private stash so they cannot use street gear in arena.
function Arena.Inventory.StashPlayer(src)
    if not oxReady() then return true end
    if stashed[src] then return true end

    local stashId = ('%s%s'):format(Config.OxInventory.stashPrefix, src)

    exports.ox_inventory:RegisterStash(
        stashId,
        'Arena Stash',
        Config.OxInventory.stashSlots,
        Config.OxInventory.stashWeight,
        Arena.Framework.GetIdentifier(src)
    )

    local inventory = exports.ox_inventory:GetInventoryItems(src)
    if inventory then
        for _, item in pairs(inventory) do
            if item and item.name and item.count and item.count > 0 then
                local success = exports.ox_inventory:AddItem(stashId, item.name, item.count, item.metadata)
                if success then
                    exports.ox_inventory:RemoveItem(src, item.name, item.count, item.metadata, item.slot)
                end
            end
        end
    end

    if Config.OxInventory.clearBeforeLoadout then
        exports.ox_inventory:ClearInventory(src)
    end

    stashed[src] = true
    Arena.Utils.Debug('Stashed inventory for', src)
    return true
end

function Arena.Inventory.RestorePlayer(src)
    if not oxReady() then return true end
    if not stashed[src] then return true end

    local stashId = ('%s%s'):format(Config.OxInventory.stashPrefix, src)

    exports.ox_inventory:ClearInventory(src)

    local stashItems = exports.ox_inventory:GetInventoryItems(stashId)
    if stashItems then
        for _, item in pairs(stashItems) do
            if item and item.name and item.count and item.count > 0 then
                exports.ox_inventory:AddItem(src, item.name, item.count, item.metadata)
                exports.ox_inventory:RemoveItem(stashId, item.name, item.count, item.metadata, item.slot)
            end
        end
    end

    stashed[src] = nil
    Arena.Utils.Debug('Restored inventory for', src)
    return true
end

--- Give match loadout using ox_inventory weapon items.
function Arena.Inventory.GiveLoadout(src, weaponDef)
    if not weaponDef then return false end

    if oxReady() then
        if Config.OxInventory.clearBeforeLoadout then
            exports.ox_inventory:ClearInventory(src)
        end

        local metadata = {
            ammo = weaponDef.ammo or 0,
            registered = false,
            durability = 100,
        }

        local ok = exports.ox_inventory:AddItem(src, weaponDef.weapon, 1, metadata)
        if not ok then
            -- Fallback: some servers register lowercase item names
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

    -- Standalone fallback via client
    TriggerClientEvent('cursor_arena:client:giveWeaponFallback', src, weaponDef.weapon, weaponDef.ammo or 0)
    return true
end

function Arena.Inventory.ClearLoadout(src)
    if oxReady() then
        exports.ox_inventory:ClearInventory(src)
    else
        TriggerClientEvent('cursor_arena:client:stripWeapons', src)
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
    if stashed[src] and Config.OxInventory.restoreOnLeave then
        -- Best-effort restore on disconnect; ox stash remains owned by identifier
        stashed[src] = nil
    end
end)

--- Admin / recovery command to restore a stuck stash
lib.addCommand('arena_restoreinv', {
    help = 'Restore arena-stashed inventory for a player',
    restricted = Config.Permissions.adminAce,
    params = {
        { name = 'id', type = 'playerId', help = 'Player server id' },
    },
}, function(source, args)
    local target = args.id
    if target then
        Arena.Inventory.RestorePlayer(target)
        Arena.Utils.Notify(source, { type = 'success', description = 'Inventory restore attempted.' })
    end
end)
