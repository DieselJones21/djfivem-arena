--[[
    Weapon categories & selectable loadouts

    weapon  = ox_inventory item name (must exist in your items.lua)
    hash    = GTA weapon hash (used as fallback / equip)
    ammo    = ammo count granted with the weapon
    label   = display name in UI
]]

Config.WeaponCategories = {
    pistols = {
        label = 'Pistols',
        weapons = {
            { id = 'pistol',          label = 'Pistol',          weapon = 'WEAPON_PISTOL',          ammo = 120, ammoItem = 'ammo-9' },
            { id = 'pistol_mk2',      label = 'Pistol Mk II',    weapon = 'WEAPON_PISTOL_MK2',      ammo = 120, ammoItem = 'ammo-9' },
            { id = 'combatpistol',    label = 'Combat Pistol',   weapon = 'WEAPON_COMBATPISTOL',    ammo = 120, ammoItem = 'ammo-9' },
            { id = 'heavypistol',     label = 'Heavy Pistol',    weapon = 'WEAPON_HEAVYPISTOL',     ammo = 90,  ammoItem = 'ammo-45' },
            { id = 'appistol',       label = 'AP Pistol',       weapon = 'WEAPON_APPISTOL',        ammo = 150, ammoItem = 'ammo-9' },
            { id = 'pistol50',        label = 'Pistol .50',      weapon = 'WEAPON_PISTOL50',        ammo = 60,  ammoItem = 'ammo-50' },
        },
    },
    rifles = {
        label = 'Rifles',
        weapons = {
            { id = 'assaultrifle',    label = 'Assault Rifle',   weapon = 'WEAPON_ASSAULTRIFLE',    ammo = 180, ammoItem = 'ammo-rifle' },
            { id = 'carbinerifle',    label = 'Carbine Rifle',   weapon = 'WEAPON_CARBINERIFLE',    ammo = 180, ammoItem = 'ammo-rifle' },
            { id = 'specialcarbine',  label = 'Special Carbine', weapon = 'WEAPON_SPECIALCARBINE',  ammo = 180, ammoItem = 'ammo-rifle' },
            { id = 'bullpuprifle',    label = 'Bullpup Rifle',   weapon = 'WEAPON_BULLPUPRIFLE',    ammo = 180, ammoItem = 'ammo-rifle' },
            { id = 'advancedrifle',   label = 'Advanced Rifle',  weapon = 'WEAPON_ADVANCEDRIFLE',   ammo = 180, ammoItem = 'ammo-rifle' },
            { id = 'compactrifle',    label = 'Compact Rifle',   weapon = 'WEAPON_COMPACTRIFLE',    ammo = 180, ammoItem = 'ammo-rifle' },
        },
    },
    smgs = {
        label = 'SMGs',
        weapons = {
            { id = 'smg',             label = 'SMG',             weapon = 'WEAPON_SMG',             ammo = 180, ammoItem = 'ammo-9' },
            { id = 'microsmg',        label = 'Micro SMG',       weapon = 'WEAPON_MICROSMG',        ammo = 180, ammoItem = 'ammo-9' },
            { id = 'assaultsmg',      label = 'Assault SMG',     weapon = 'WEAPON_ASSAULTSMG',      ammo = 180, ammoItem = 'ammo-9' },
            { id = 'combatpdw',       label = 'Combat PDW',      weapon = 'WEAPON_COMBATPDW',       ammo = 180, ammoItem = 'ammo-9' },
        },
    },
    shotguns = {
        label = 'Shotguns',
        weapons = {
            { id = 'pumpshotgun',     label = 'Pump Shotgun',    weapon = 'WEAPON_PUMPSHOTGUN',     ammo = 40,  ammoItem = 'ammo-shotgun' },
            { id = 'sawnoffshotgun',  label = 'Sawn Off',        weapon = 'WEAPON_SAWNOFFSHOTGUN',  ammo = 40,  ammoItem = 'ammo-shotgun' },
            { id = 'combatshotgun',   label = 'Combat Shotgun',  weapon = 'WEAPON_COMBATSHOTGUN',   ammo = 40,  ammoItem = 'ammo-shotgun' },
        },
    },
    snipers = {
        label = 'Snipers',
        weapons = {
            { id = 'sniperrifle',     label = 'Sniper Rifle',    weapon = 'WEAPON_SNIPERRIFLE',     ammo = 30,  ammoItem = 'ammo-sniper' },
            { id = 'heavysniper',     label = 'Heavy Sniper',    weapon = 'WEAPON_HEAVYSNIPER',     ammo = 20,  ammoItem = 'ammo-sniper' },
            { id = 'marksmanrifle',   label = 'Marksman Rifle',  weapon = 'WEAPON_MARKSMANRIFLE',   ammo = 40,  ammoItem = 'ammo-sniper' },
        },
    },
    melee = {
        label = 'Melee',
        weapons = {
            { id = 'knife',           label = 'Knife',           weapon = 'WEAPON_KNIFE',           ammo = 0 },
            { id = 'bat',             label = 'Baseball Bat',    weapon = 'WEAPON_BAT',             ammo = 0 },
            { id = 'machete',         label = 'Machete',         weapon = 'WEAPON_MACHETE',         ammo = 0 },
        },
    },
}

--[[
    Categories available when mode.weaponCategory == 'any' or 'choice'
]]
Config.ChoiceCategories = { 'pistols', 'rifles', 'smgs', 'shotguns', 'snipers' }

function Config.GetWeapon(categoryId, weaponId)
    local category = Config.WeaponCategories[categoryId]
    if not category then return end
    for i = 1, #category.weapons do
        if category.weapons[i].id == weaponId then
            return category.weapons[i], category
        end
    end
end

function Config.FindWeapon(weaponId)
    for catId, category in pairs(Config.WeaponCategories) do
        for i = 1, #category.weapons do
            if category.weapons[i].id == weaponId then
                return category.weapons[i], catId, category
            end
        end
    end
end

function Config.GetWeaponsForMode(mode)
    if not mode then return {} end

    if mode.weaponCategory == 'any' or mode.weaponCategory == 'choice' then
        local list = {}
        for i = 1, #Config.ChoiceCategories do
            local catId = Config.ChoiceCategories[i]
            local cat = Config.WeaponCategories[catId]
            if cat then
                for j = 1, #cat.weapons do
                    local w = cat.weapons[j]
                    list[#list + 1] = {
                        id = w.id,
                        label = w.label,
                        weapon = w.weapon,
                        ammo = w.ammo,
                        ammoItem = w.ammoItem,
                        category = catId,
                        categoryLabel = cat.label,
                    }
                end
            end
        end
        return list
    end

    local category = Config.WeaponCategories[mode.weaponCategory]
    if not category then return {} end

    local list = {}
    for i = 1, #category.weapons do
        local w = category.weapons[i]
        list[#list + 1] = {
            id = w.id,
            label = w.label,
            weapon = w.weapon,
            ammo = w.ammo,
            ammoItem = w.ammoItem,
            category = mode.weaponCategory,
            categoryLabel = category.label,
        }
    end
    return list
end
