Arena = Arena or {}
Arena.Inventory = {}

local function oxReady()
    return Config.OxInventory.enabled and GetResourceState('ox_inventory') == 'started'
end

function Arena.Inventory.Block(src, blocked)
    if not Config.OxInventory.blockWhileInMatch then return end
    local ply = Player(src)
    if ply and ply.state then
        ply.state:set('invBusy', blocked == true, true)
        ply.state:set('invHotkeys', blocked ~= true, true)
        ply.state:set('canUseWeapons', true, true)
    end
    TriggerClientEvent('cursor_arena:client:blockInventory', src, blocked == true)
end

function Arena.Inventory.IsStashed()
    return false
end

function Arena.Inventory.StashPlayer(src)
    -- Never confiscate. Inventory stays on the player; UI is blocked in-match.
    Arena.Inventory.Block(src, true)
    return true
end

function Arena.Inventory.RestorePlayer(src)
    Arena.Inventory.Block(src, false)
    return true
end

function Arena.Inventory.GiveLoadout(src, weaponDef)
    if not weaponDef then return false end
    TriggerClientEvent('cursor_arena:client:equipWeapon', src, weaponDef.weapon, 9999)
    return true
end

function Arena.Inventory.ClearLoadout(src)
    TriggerClientEvent('cursor_arena:client:stripWeapons', src)
end

function Arena.Inventory.RefillAmmo(src, weaponDef)
    if not weaponDef then return end
    TriggerClientEvent('cursor_arena:client:equipWeapon', src, weaponDef.weapon, 9999)
end

lib.addCommand('arena_restoreinv', {
    help = 'Unblock arena inventory lock for a player',
    restricted = Config.Permissions.adminAce,
    params = {
        { name = 'id', type = 'playerId', help = 'Player server id' },
    },
}, function(source, args)
    local target = args.id
    if not target then return end
    Arena.Inventory.Block(target, false)
    Arena.Utils.Notify(source, { type = 'success', description = 'Inventory unlocked for ' .. tostring(target) })
    Arena.Utils.Notify(target, { type = 'inform', description = L('inventory_restored') })
end)
