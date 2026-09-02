--[[
================================================================================
  No fence. Each map is a center + radius bubble.

  2 FFA/TDM arenas  →  arena_1, arena_2
      FFA: 12 spawn marks    TDM: 5 Alpha + 5 Bravo
  4 PVP maps        →  pvp_1 .. pvp_4
      One Alpha mark, one Bravo mark. The whole team lands on that mark.

  Paste format is in SPAWNS.md. Vanilla fills ship so it boots.
================================================================================
]]

Config.Maps = {
    {
        id = 'arena_1',
        name = 'Arena 1',
        description = 'FFA and TDM.',
        image = 'assets/map_construction.svg',
        center = vec3(87.4, -392.6, 41.6),
        radius = 55.0,
        heading = 160.0,
        spawns = {
            vec4(70.2, -378.4, 41.6, 160.0),
            vec4(102.8, -376.1, 41.6, 200.0),
            vec4(110.4, -404.8, 41.6, 250.0),
            vec4(78.6, -416.2, 41.6, 340.0),
            vec4(58.9, -400.1, 41.6, 70.0),
            vec4(95.0, -392.0, 41.6, 120.0),
            vec4(84.0, -388.0, 41.6, 140.0),
            vec4(98.0, -408.0, 41.6, 260.0),
            vec4(66.0, -410.0, 41.6, 20.0),
            vec4(108.0, -386.0, 41.6, 210.0),
            vec4(74.0, -396.0, 41.6, 90.0),
            vec4(90.0, -420.0, 41.6, 350.0),
        },
        team1_spawns = {
            vec4(62.4, -372.8, 41.6, 165.0),
            vec4(74.1, -370.2, 41.6, 170.0),
            vec4(54.8, -386.6, 41.6, 120.0),
            vec4(68.0, -384.0, 41.6, 155.0),
            vec4(80.5, -368.9, 41.6, 180.0),
        },
        team2_spawns = {
            vec4(114.2, -414.6, 41.6, 340.0),
            vec4(102.7, -418.1, 41.6, 350.0),
            vec4(122.0, -400.4, 41.6, 280.0),
            vec4(108.8, -406.2, 41.6, 330.0),
            vec4(96.4, -420.0, 41.6, 10.0),
        },
    },
    {
        id = 'arena_2',
        name = 'Arena 2',
        description = 'FFA and TDM.',
        image = 'assets/map_warehouse.svg',
        center = vec3(1015.2, -3094.6, 5.9),
        radius = 70.0,
        heading = 90.0,
        spawns = {
            vec4(980.4, -3070.2, 5.9, 90.0),
            vec4(1048.6, -3072.8, 5.9, 270.0),
            vec4(1046.1, -3118.4, 5.9, 280.0),
            vec4(978.8, -3116.0, 5.9, 95.0),
            vec4(1014.0, -3056.5, 5.9, 180.0),
            vec4(1016.4, -3132.8, 5.9, 0.0),
            vec4(990.0, -3088.0, 5.9, 100.0),
            vec4(1038.0, -3090.0, 5.9, 260.0),
            vec4(1000.0, -3062.0, 5.9, 170.0),
            vec4(1028.0, -3124.0, 5.9, 10.0),
            vec4(968.0, -3100.0, 5.9, 85.0),
            vec4(1056.0, -3102.0, 5.9, 275.0),
        },
        team1_spawns = {
            vec4(968.2, -3064.8, 5.9, 95.0),
            vec4(966.0, -3084.4, 5.9, 90.0),
            vec4(970.5, -3104.1, 5.9, 85.0),
            vec4(962.8, -3074.0, 5.9, 92.0),
            vec4(974.2, -3120.6, 5.9, 80.0),
        },
        team2_spawns = {
            vec4(1062.4, -3066.2, 5.9, 270.0),
            vec4(1064.8, -3086.0, 5.9, 265.0),
            vec4(1060.1, -3106.4, 5.9, 275.0),
            vec4(1068.0, -3076.8, 5.9, 268.0),
            vec4(1056.6, -3122.0, 5.9, 280.0),
        },
    },
    {
        id = 'pvp_1',
        name = 'PVP 1',
        description = '1v1–4v4. Whole team on one mark.',
        image = 'assets/map_construction.svg',
        center = vec3(87.4, -392.6, 41.6),
        radius = 55.0,
        heading = 160.0,
        team1_spawns = { vec4(62.4, -372.8, 41.6, 165.0) },
        team2_spawns = { vec4(114.2, -414.6, 41.6, 340.0) },
    },
    {
        id = 'pvp_2',
        name = 'PVP 2',
        description = '1v1–4v4. Whole team on one mark.',
        image = 'assets/map_warehouse.svg',
        center = vec3(1015.2, -3094.6, 5.9),
        radius = 70.0,
        heading = 90.0,
        team1_spawns = { vec4(968.2, -3064.8, 5.9, 95.0) },
        team2_spawns = { vec4(1062.4, -3066.2, 5.9, 270.0) },
    },
    {
        id = 'pvp_3',
        name = 'PVP 3',
        description = '1v1–4v4. Whole team on one mark.',
        image = 'assets/map_docks.svg',
        center = vec3(1731.5, 3310.4, 41.2),
        radius = 85.0,
        heading = 195.0,
        team1_spawns = { vec4(1682.4, 3262.0, 41.1, 20.0) },
        team2_spawns = { vec4(1784.6, 3358.4, 41.1, 200.0) },
    },
    {
        id = 'pvp_4',
        name = 'PVP 4',
        description = '1v1–4v4. Whole team on one mark.',
        image = 'assets/map_ring.svg',
        center = vec3(-819.4, 177.6, 72.2),
        radius = 42.0,
        heading = 110.0,
        team1_spawns = { vec4(-838.2, 164.0, 71.8, 40.0) },
        team2_spawns = { vec4(-798.4, 166.8, 71.8, 250.0) },
    },
}

function Config.GetMap(mapId)
    for i = 1, #Config.Maps do
        if Config.Maps[i].id == mapId then
            return Config.Maps[i]
        end
    end
end

function Config.GetHubSpawn()
    local spawns = Config.SpawnLobby and Config.SpawnLobby.spawns
    if not spawns or #spawns == 0 then
        return vec4(5477.79, -5853.01, 1050.58, 78.04)
    end
    return spawns[math.random(#spawns)]
end
