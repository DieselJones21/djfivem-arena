--[[
    Loadouts — your addon spawn names.
    Guns are added as ox_inventory items (nothing else is taken) and used into
    the hands so ox owns the weapon. Infinite ammo in-match.
]]

Config.Loadouts = {
    {
        id = 'pistols',
        label = 'Pistols',
        description = 'Sidearms.',
        icon = 'pistol',
        category = 'pistol',
        weapons = {
            { id = 'g17',      label = 'G17',          weapon = 'WEAPON_G17',      ammo = 250 },
            { id = 'g45',      label = 'G45',          weapon = 'WEAPON_G45',      ammo = 250 },
            { id = 'spiderap', label = 'Spider AP',    weapon = 'WEAPON_SPIDERAP', ammo = 250 },
            { id = 'snakeap',  label = 'Snake AP',     weapon = 'WEAPON_SNAKEAP',  ammo = 250 },
            { id = 'bluewire', label = 'Blue Wire',     weapon = 'WEAPON_BLUEWIRE', ammo = 250 },
        },
    },
    {
        id = 'smg',
        label = 'SMG',
        description = 'Close-range spray.',
        icon = 'smg',
        category = 'smg',
        weapons = {
            { id = 'spectre',   label = 'Spectre SMG',         weapon = 'WEAPON_SPECTRESMG',         ammo = 250 },
            { id = 'chromewire',label = 'Chrome Wire SMG',     weapon = 'WEAPON_CHROMEWIRESMG',      ammo = 250 },
            { id = 'chromiummp5', label = 'Chromium MP5',      weapon = 'WEAPON_CHROMIUMMP5',        ammo = 250 },
            { id = 'sharkmp',   label = 'Shark Machine Pistol', weapon = 'WEAPON_SHARKMACHINEPISTOL', ammo = 250 },
            { id = 'pinkwire',  label = 'Pink Wire SMG',       weapon = 'WEAPON_PINKWIRESMG',        ammo = 250 },
        },
    },
    {
        id = 'ar',
        label = 'AR',
        description = 'Rifles.',
        icon = 'rifle',
        category = 'rifle',
        weapons = {
            { id = 'kissar',     label = 'Kiss AR',       weapon = 'WEAPON_KISSAR',       ammo = 250 },
            { id = 'portalpurple', label = 'Portal Purple', weapon = 'WEAPON_PORTALPURPLE', ammo = 250 },
            { id = 'easterar',   label = 'Easter AR',     weapon = 'WEAPON_EASTERAR',     ammo = 250 },
            { id = 'hazardar',   label = 'Hazard AR',     weapon = 'WEAPON_HAZARDAR',     ammo = 250 },
            { id = 'chromiumiso',label = 'Chromium ISO',  weapon = 'WEAPON_CHROMIUMISO',  ammo = 250 },
        },
    },
}

function Config.GetLoadout(loadoutId)
    for i = 1, #Config.Loadouts do
        if Config.Loadouts[i].id == loadoutId then
            return Config.Loadouts[i]
        end
    end
end

function Config.GetLoadoutWeapon(loadoutId, weaponId)
    local loadout = Config.GetLoadout(loadoutId)
    if not loadout then return end
    for i = 1, #loadout.weapons do
        if loadout.weapons[i].id == weaponId then
            return loadout.weapons[i], loadout
        end
    end
end

function Config.FindWeapon(weaponId)
    for i = 1, #Config.Loadouts do
        local loadout = Config.Loadouts[i]
        for j = 1, #loadout.weapons do
            if loadout.weapons[j].id == weaponId then
                return loadout.weapons[j], loadout
            end
        end
    end
end

function Config.ResolveLoadouts(ids)
    local list = {}
    ids = ids or {}
    for i = 1, #ids do
        local loadout = Config.GetLoadout(ids[i])
        if loadout then
            list[#list + 1] = loadout
        end
    end
    if #list == 0 then
        return Config.Loadouts
    end
    return list
end
