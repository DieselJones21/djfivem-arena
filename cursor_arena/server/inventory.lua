Arena = Arena or {}
Arena.Inventory = {}
Arena.ArenaGun = {}

local function oxReady()
    return Config.OxInventory.enabled ~= false and GetResourceState('ox_inventory') == 'started'
end

local function itemNames(weapon)
    if not weapon then return {} end
    local w = tostring(weapon)
    return { w, w:upper(), w:lower() }
end

local function oxItems()
    local ok, items = pcall(function()
        return exports.ox_inventory:Items()
    end)
    if ok and type(items) == 'table' then return items end
end

local function resolveItemName(weapon)
    local names = itemNames(weapon)
    local items = oxItems()
    if items then
        for i = 1, #names do
            if items[names[i]] then return names[i], items[names[i]] end
        end
        local want = tostring(weapon):lower()
        for name, def in pairs(items) do
            if type(name) == 'string' and name:lower() == want then
                return name, def
            end
        end
    end
    return names[1]
end

local function itemCount(src, name)
    local ok, count = pcall(function()
        return exports.ox_inventory:GetItemCount(src, name) or 0
    end)
    if ok and type(count) == 'number' then return count end
    return 0
end

local function findSlot(src, name)
    if not oxReady() or not name then return end
    local ok, result = pcall(function()
        return exports.ox_inventory:Search(src, 'slots', name)
    end)
    if not ok or type(result) ~= 'table' then return end
    for _, data in pairs(result) do
        if type(data) == 'table' and data.slot then
            return data.slot
        end
    end
end

local function addAmmo(src, itemDef, ammo)
    if not itemDef or not itemDef.ammoname then return end
    local name = itemDef.ammoname
    local before = itemCount(src, name)
    pcall(function()
        exports.ox_inventory:AddItem(src, name, ammo or 250)
    end)
    local added = math.max(0, itemCount(src, name) - before)
    if added > 0 then return name, added end
end

function Arena.Inventory.Block(src, blocked)
    if not Config.OxInventory.blockWhileInMatch then return end
    local ply = Player(src)
    if ply and ply.state then
        -- invBusy makes ox_inventory call DisablePlayerFiring. Never use it here.
        ply.state:set('invBusy', false, true)
        ply.state:set('invHotkeys', blocked ~= true, true)
        ply.state:set('canUseWeapons', true, true)
    end
    TriggerClientEvent('cursor_arena:client:blockInventory', src, blocked == true)
end

function Arena.Inventory.IsStashed()
    return false
end

function Arena.Inventory.StashPlayer(src)
    Arena.Inventory.Block(src, true)
    return true
end

function Arena.Inventory.RestorePlayer(src)
    Arena.Inventory.Block(src, false)
    return true
end

function Arena.Inventory.GiveLoadout(src, weaponDef)
    if not weaponDef or not weaponDef.weapon then return end
    Arena.Inventory.ClearLoadout(src, true)

    local ammo = weaponDef.ammo or 9999
    local slot, usedName, addedItem, ammoName, ammoAdded, itemDef

    if oxReady() then
        usedName, itemDef = resolveItemName(weaponDef.weapon)
        if itemCount(src, usedName) <= 0 then
            local ok, success = pcall(function()
                return exports.ox_inventory:AddItem(src, usedName, 1, {
                    ammo = ammo,
                    durability = 100,
                    registered = false,
                    components = {},
                    serial = 'ARENA',
                })
            end)
            if ok and success then
                addedItem = true
            else
                -- Item spawn names sometimes differ from the GTA weapon name.
                local names = itemNames(weaponDef.weapon)
                for i = 1, #names do
                    if names[i] ~= usedName then
                        ok, success = pcall(function()
                            return exports.ox_inventory:AddItem(src, names[i], 1, {
                                ammo = ammo,
                                durability = 100,
                                registered = false,
                                components = {},
                                serial = 'ARENA',
                            })
                        end)
                        if ok and success then
                            addedItem = true
                            usedName = names[i]
                            break
                        end
                    end
                end
            end
        end

        slot = findSlot(src, usedName)
        ammoName, ammoAdded = addAmmo(src, itemDef, math.max(ammo, 250))
        Arena.ArenaGun[src] = {
            item = addedItem and usedName or nil,
            name = usedName,
            ammoItem = ammoName,
            ammoCount = ammoAdded,
        }
    end

    TriggerClientEvent('cursor_arena:client:equipWeapon', src, weaponDef.weapon, ammo, slot)
    return slot
end

function Arena.Inventory.ClearLoadout(src, silent)
    local given = Arena.ArenaGun[src]
    Arena.ArenaGun[src] = nil
    if given and oxReady() then
        if given.item then
            pcall(function()
                exports.ox_inventory:RemoveItem(src, given.item, 1)
            end)
        end
        if given.ammoItem and given.ammoCount and given.ammoCount > 0 then
            pcall(function()
                exports.ox_inventory:RemoveItem(src, given.ammoItem, given.ammoCount)
            end)
        end
    end
    if not silent then
        TriggerClientEvent('cursor_arena:client:stripWeapons', src)
    end
end

function Arena.Inventory.RefillAmmo(src, weaponDef)
    if not weaponDef then return end
    local ammo = weaponDef.ammo or 9999
    local usedName, itemDef = resolveItemName(weaponDef.weapon)
    local slot = findSlot(src, usedName)
    local given = Arena.ArenaGun[src] or {}
    if oxReady() and itemDef then
        local ammoName, ammoAdded = addAmmo(src, itemDef, math.max(ammo, 250))
        if ammoName then
            given.ammoItem = ammoName
            given.ammoCount = (given.ammoCount or 0) + (ammoAdded or 0)
            given.name = usedName
            Arena.ArenaGun[src] = given
        end
        if slot and given.item then
            pcall(function()
                exports.ox_inventory:SetMetadata(src, slot, { ammo = ammo, durability = 100, serial = 'ARENA' })
            end)
        end
    end
    TriggerClientEvent('cursor_arena:client:equipWeapon', src, weaponDef.weapon, ammo, slot)
end

RegisterNetEvent('cursor_arena:server:equipRetry', function()
    local src = source
    local lobby = Arena.GetPlayerLobby and Arena.GetPlayerLobby(src)
    if not lobby or not lobby.players or not lobby.players[src] then return end
    local p = lobby.players[src]
    local weapon = select(1, Config.GetLoadoutWeapon(p.loadoutId, p.weaponId)) or Config.FindWeapon(p.weaponId)
    if not weapon then return end

    local given = Arena.ArenaGun[src]
    local usedName = given and given.name
    if usedName then
        local slot = findSlot(src, usedName)
        if slot then
            TriggerClientEvent('cursor_arena:client:equipWeapon', src, weapon.weapon, weapon.ammo or 9999, slot)
            return
        end
        if itemCount(src, usedName) <= 0 then
            Arena.Inventory.GiveLoadout(src, weapon)
            return
        end
    end
    Arena.Inventory.GiveLoadout(src, weapon)
end)

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
