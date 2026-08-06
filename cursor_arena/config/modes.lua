--[[
    Match modes

    type:
      - 'ffa'  free for all
      - 'tdm'  team deathmatch (score by team kills)
      - 'team' fixed team size vs (1v1 .. 5v5), ends when one side wins enough rounds
                 or scoreLimit is reached

    weaponCategory: key into Config.WeaponCategories (or 'any' / 'choice')
    teamSize: players per team for team modes (nil for FFA/TDM flexible)
]]

Config.Modes = {
    {
        id = 'pistol_ffa',
        label = 'Pistol FFA',
        description = 'Every fighter for themselves. Pistols only.',
        type = 'ffa',
        icon = 'pistol',
        weaponCategory = 'pistols',
        allowWeaponChoice = true,
        minPlayers = 2,
        maxPlayers = 16,
        scoreLimit = 25,
        timeLimit = 600,
        teamSize = nil,
        rounds = 1,
        respawn = true,
        color = '#e85d04',
    },
    {
        id = 'rifle_ffa',
        label = 'Rifle FFA',
        description = 'High-speed rifle free-for-all.',
        type = 'ffa',
        icon = 'rifle',
        weaponCategory = 'rifles',
        allowWeaponChoice = true,
        minPlayers = 2,
        maxPlayers = 16,
        scoreLimit = 30,
        timeLimit = 600,
        teamSize = nil,
        rounds = 1,
        respawn = true,
        color = '#2a9d8f',
    },
    {
        id = 'tdm',
        label = 'Team Deathmatch',
        description = 'Red vs Blue. First team to the kill target wins.',
        type = 'tdm',
        icon = 'tdm',
        weaponCategory = 'any',
        allowWeaponChoice = true,
        minPlayers = 2,
        maxPlayers = 20,
        scoreLimit = 50,
        timeLimit = 720,
        teamSize = nil, -- flexible, auto-balance
        rounds = 1,
        respawn = true,
        color = '#e63946',
        friendlyFire = false,
    },
    {
        id = '1v1',
        label = '1v1',
        description = 'Duel. Best of rounds.',
        type = 'team',
        icon = 'duel',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 2,
        maxPlayers = 2,
        scoreLimit = 5,          -- rounds to win
        timeLimit = 180,         -- per round
        teamSize = 1,
        rounds = 5,
        respawn = false,         -- round ends on death
        color = '#f4a261',
        friendlyFire = false,
    },
    {
        id = '2v2',
        label = '2v2',
        description = 'Two-man squads. Coordinate or die.',
        type = 'team',
        icon = 'squad',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 4,
        maxPlayers = 4,
        scoreLimit = 5,
        timeLimit = 240,
        teamSize = 2,
        rounds = 5,
        respawn = false,
        color = '#e9c46a',
        friendlyFire = false,
    },
    {
        id = '3v3',
        label = '3v3',
        description = 'Mid-size team skirmish.',
        type = 'team',
        icon = 'squad',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 6,
        maxPlayers = 6,
        scoreLimit = 5,
        timeLimit = 300,
        teamSize = 3,
        rounds = 5,
        respawn = true,
        color = '#264653',
        friendlyFire = false,
    },
    {
        id = '4v4',
        label = '4v4',
        description = 'Full squad warfare.',
        type = 'team',
        icon = 'war',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 8,
        maxPlayers = 8,
        scoreLimit = 7,
        timeLimit = 360,
        teamSize = 4,
        rounds = 7,
        respawn = true,
        color = '#1d3557',
        friendlyFire = false,
    },
    {
        id = '5v5',
        label = '5v5',
        description = 'Maximum firepower. Ten fighters.',
        type = 'team',
        icon = 'war',
        weaponCategory = 'choice',
        allowWeaponChoice = true,
        minPlayers = 10,
        maxPlayers = 10,
        scoreLimit = 7,
        timeLimit = 420,
        teamSize = 5,
        rounds = 7,
        respawn = true,
        color = '#9b2226',
        friendlyFire = false,
    },
}

function Config.GetMode(modeId)
    for i = 1, #Config.Modes do
        if Config.Modes[i].id == modeId then
            return Config.Modes[i]
        end
    end
end
