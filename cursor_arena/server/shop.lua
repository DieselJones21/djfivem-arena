Arena = Arena or {}
Arena.Shop = {}

local owned = {} -- [identifier] = { [weaponId] = true }

local function ident(src)
    return Arena.Framework.GetIdentifier(src)
end

local function loadOwned(src)
    local id = ident(src)
    if not id then return {} end
    if owned[id] then return owned[id] end
    local raw = GetResourceKvpString('cursor_arena:shop:' .. id)
    local set = {}
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            for i = 1, #data do set[data[i]] = true end
        end
    end
    owned[id] = set
    return set
end

local function saveOwned(src)
    local id = ident(src)
    if not id then return end
    local set = owned[id] or {}
    local list = {}
    for weaponId in pairs(set) do
        list[#list + 1] = weaponId
    end
    SetResourceKvp('cursor_arena:shop:' .. id, json.encode(list))
end

function Arena.Shop.Owns(src, weaponId)
    local wep = Config.FindWeapon(weaponId)
    if not wep or not wep.shop then return true end
    return loadOwned(src)[weaponId] == true
end

function Arena.Shop.Catalog(src)
    local set = loadOwned(src)
    local list = {}
    for i = 1, #Config.Loadouts do
        local group = Config.Loadouts[i]
        for j = 1, #group.weapons do
            local w = group.weapons[j]
            if w.shop then
                list[#list + 1] = {
                    id = w.id,
                    loadoutId = group.id,
                    label = w.label,
                    weapon = w.weapon,
                    category = group.label,
                    price = w.price or 0,
                    owned = set[w.id] == true,
                }
            end
        end
    end
    return list
end

function Arena.Shop.SerializeLoadouts(src)
    local set = loadOwned(src)
    local out = {}
    for i = 1, #Config.Loadouts do
        local l = Config.Loadouts[i]
        local weapons = {}
        for j = 1, #l.weapons do
            local w = l.weapons[j]
            if not w.shop or set[w.id] then
                weapons[#weapons + 1] = w
            end
        end
        if #weapons > 0 then
            out[#out + 1] = {
                id = l.id,
                label = l.label,
                description = l.description,
                icon = l.icon,
                category = l.category,
                weapons = weapons,
            }
        end
    end
    return out
end

function Arena.Shop.Purchase(src, weaponId)
    local wep, group = Config.FindWeapon(weaponId)
    if not wep or not wep.shop then return false, 'not_found' end
    local set = loadOwned(src)
    if set[weaponId] then return true, 'owned' end
    local price = wep.price or 0
    if price > 0 and not Arena.Donator.Remove(src, price) then
        return false, 'need_coins'
    end
    set[weaponId] = true
    saveOwned(src)
    return true, 'bought', {
        coins = Arena.Donator.GetBalance(src),
        shop = Arena.Shop.Catalog(src),
        loadouts = Arena.Shop.SerializeLoadouts(src),
        loadoutId = group and group.id,
        weaponId = weaponId,
    }
end
