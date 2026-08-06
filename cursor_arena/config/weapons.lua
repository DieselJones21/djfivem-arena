--[[
    Weapon classes — Pistol / SMG / Rifle
    Exactly 5 weapons per class. Edit labels, weapon hashes, and ammo to match ox_inventory.
]]

Config.WeaponCategories = {
    pistols = {
        label = 'Pistol',
        weapons = {
            { id = 'pistol',        label = 'Pistol',          weapon = 'WEAPON_PISTOL',        ammo = 120, ammoItem = 'ammo-9' },
            { id = 'combatpistol',  label = 'Combat Pistol',   weapon = 'WEAPON_COMBATPISTOL',  ammo = 120, ammoItem = 'ammo-9' },
            { id = 'heavypistol',   label = 'Heavy Pistol',    weapon = 'WEAPON_HEAVYPISTOL',   ammo = 90,  ammoItem = 'ammo-45' },
            { id = 'appistol',     label = 'AP Pistol',       weapon = 'WEAPON_APPISTOL',      ammo = 150, ammoItem = 'ammo-9' },
            { id = 'pistol50',      label = 'Pistol .50',      weapon = 'WEAPON_PISTOL50',      ammo = 60,  ammoItem = 'ammo-50' },
        },
    },
    smgs = {
        label = 'SMG',
        weapons = {
            { id = 'smg',           label = 'SMG',             weapon = 'WEAPON_SMG',           ammo = 180, ammoItem = 'ammo-9' },
            { id = 'microsmg',      label = 'Micro SMG',       weapon = 'WEAPON_MICROSMG',      ammo = 180, ammoItem = 'ammo-9' },
            { id = 'assaultsmg',    label = 'Assault SMG',     weapon = 'WEAPON_ASSAULTSMG',    ammo = 180, ammoItem = 'ammo-9' },
            { id = 'combatpdw',     label = 'Combat PDW',      weapon = 'WEAPON_COMBATPDW',     ammo = 180, ammoItem = 'ammo-9' },
            { id = 'machinepistol', label = 'Machine Pistol',  weapon = 'WEAPON_MACHINEPISTOL', ammo = 180, ammoItem = 'ammo-9' },
        },
    },
    rifles = {
        label = 'Rifle',
        weapons = {
            { id = 'assaultrifle',  label = 'Assault Rifle',   weapon = 'WEAPON_ASSAULTRIFLE',  ammo = 180, ammoItem = 'ammo-rifle' },
            { id = 'carbinerifle',  label = 'Carbine Rifle',   weapon = 'WEAPON_CARBINERIFLE',  ammo = 180, ammoItem = 'ammo-rifle' },
            { id = 'specialcarbine',label = 'Special Carbine', weapon = 'WEAPON_SPECIALCARBINE',ammo = 180, ammoItem = 'ammo-rifle' },
            { id = 'bullpuprifle',  label = 'Bullpup Rifle',   weapon = 'WEAPON_BULLPUPRIFLE',  ammo = 180, ammoItem = 'ammo-rifle' },
            { id = 'advancedrifle', label = 'Advanced Rifle',  weapon = 'WEAPON_ADVANCEDRIFLE', ammo = 180, ammoItem = 'ammo-rifle' },
        },
    },
}

--[[
    Classes available when a mode uses weaponCategory = 'any' or 'choice'
]]
Config.ChoiceCategories = { 'pistols', 'smgs', 'rifles' }

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
