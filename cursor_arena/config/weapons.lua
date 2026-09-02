--[[
    Loadouts by role — same idea as IC Arenas (Duelist / Raider / Assault / Shock / Marksman).

    Twist: each role can offer several of YOUR weapons. Players pick a role, then a gun.
    -- PASTE YOUR WEAPON SPAWN NAMES in the `weapon` field (e.g. WEAPON_PISTOL or a custom addon name).
]]

Config.Loadouts = {
    {
        id = 'duelist',
        label = 'Duelist',
        description = 'Close-range pistols. Fast, honest, lethal.',
        icon = 'pistol',
        category = 'pistol',
        weapons = {
            { id = 'pistol',       label = 'Pistol',         weapon = 'WEAPON_PISTOL',       ammo = 250, ammoItem = 'ammo-9' },
            { id = 'combatpistol', label = 'Combat Pistol',  weapon = 'WEAPON_COMBATPISTOL', ammo = 250, ammoItem = 'ammo-9' },
            { id = 'heavypistol',  label = 'Heavy Pistol',   weapon = 'WEAPON_HEAVYPISTOL',  ammo = 180, ammoItem = 'ammo-45' },
            { id = 'appistol',     label = 'AP Pistol',      weapon = 'WEAPON_APPISTOL',     ammo = 250, ammoItem = 'ammo-9' },
            { id = 'pistol50',     label = 'Pistol .50',     weapon = 'WEAPON_PISTOL50',     ammo = 120, ammoItem = 'ammo-50' },
        },
    },
    {
        id = 'raider',
        label = 'Raider',
        description = 'SMGs for rushing angles and clearing rooms.',
        icon = 'smg',
        category = 'smg',
        weapons = {
            { id = 'smg',           label = 'SMG',            weapon = 'WEAPON_SMG',           ammo = 250, ammoItem = 'ammo-9' },
            { id = 'microsmg',      label = 'Micro SMG',      weapon = 'WEAPON_MICROSMG',      ammo = 250, ammoItem = 'ammo-9' },
            { id = 'assaultsmg',    label = 'Assault SMG',    weapon = 'WEAPON_ASSAULTSMG',    ammo = 250, ammoItem = 'ammo-9' },
            { id = 'combatpdw',     label = 'Combat PDW',     weapon = 'WEAPON_COMBATPDW',     ammo = 250, ammoItem = 'ammo-9' },
            { id = 'machinepistol', label = 'Machine Pistol', weapon = 'WEAPON_MACHINEPISTOL', ammo = 250, ammoItem = 'ammo-9' },
        },
    },
    {
        id = 'assault',
        label = 'Assault',
        description = 'Rifles. The default language of a gunfight.',
        icon = 'rifle',
        category = 'rifle',
        weapons = {
            { id = 'assaultrifle',   label = 'Assault Rifle',   weapon = 'WEAPON_ASSAULTRIFLE',   ammo = 250, ammoItem = 'ammo-rifle' },
            { id = 'carbinerifle',   label = 'Carbine Rifle',   weapon = 'WEAPON_CARBINERIFLE',   ammo = 250, ammoItem = 'ammo-rifle' },
            { id = 'specialcarbine', label = 'Special Carbine', weapon = 'WEAPON_SPECIALCARBINE', ammo = 250, ammoItem = 'ammo-rifle' },
            { id = 'bullpuprifle',   label = 'Bullpup Rifle',   weapon = 'WEAPON_BULLPUPRIFLE',   ammo = 250, ammoItem = 'ammo-rifle' },
            { id = 'advancedrifle',  label = 'Advanced Rifle',  weapon = 'WEAPON_ADVANCEDRIFLE',  ammo = 250, ammoItem = 'ammo-rifle' },
        },
    },
    {
        id = 'shock',
        label = 'Shock',
        description = 'Shotguns. Own the doorway or die in it.',
        icon = 'shotgun',
        category = 'shotgun',
        weapons = {
            { id = 'pumpshotgun',    label = 'Pump Shotgun',    weapon = 'WEAPON_PUMPSHOTGUN',    ammo = 80, ammoItem = 'ammo-shotgun' },
            { id = 'sawnoff',        label = 'Sawed-Off',       weapon = 'WEAPON_SAWNOFFSHOTGUN', ammo = 80, ammoItem = 'ammo-shotgun' },
            { id = 'combatshotgun',  label = 'Combat Shotgun',  weapon = 'WEAPON_COMBATSHOTGUN',  ammo = 80, ammoItem = 'ammo-shotgun' },
            { id = 'assaultshotgun', label = 'Assault Shotgun', weapon = 'WEAPON_ASSAULTSHOTGUN', ammo = 80, ammoItem = 'ammo-shotgun' },
        },
    },
    {
        id = 'marksman',
        label = 'Marksman',
        description = 'Long rifles. One shot should be enough.',
        icon = 'sniper',
        category = 'sniper',
        weapons = {
            { id = 'sniperrifle',   label = 'Sniper Rifle',    weapon = 'WEAPON_SNIPERRIFLE',   ammo = 40, ammoItem = 'ammo-sniper' },
            { id = 'heavysniper',   label = 'Heavy Sniper',    weapon = 'WEAPON_HEAVYSNIPER',   ammo = 30, ammoItem = 'ammo-sniper' },
            { id = 'marksmanrifle', label = 'Marksman Rifle',  weapon = 'WEAPON_MARKSMANRIFLE', ammo = 60, ammoItem = 'ammo-sniper' },
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
