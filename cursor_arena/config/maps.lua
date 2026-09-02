--[[
    Radius maps. No fence.
    arena_1 / arena_2 = FFA (12) + TDM (5v5, one mark per side)
    pvp_1 .. pvp_4    = 1v1–4v4, whole team on one mark
]]

Config.Maps = {
    {
        id = 'arena_1',
        name = 'Park',
        description = 'FFA and TDM.',
        image = 'assets/map_construction.svg',
        center = vec3(4016.88, 1311.93, 679.64),
        radius = 300.0,
        heading = 0.0,
        spawns = {
            vec4(3988.31, 1283.45, 679.64, 309.16),
            vec4(4002.53, 1277.1, 679.64, 297.25),
            vec4(4023.35, 1282.61, 679.64, 323.21),
            vec4(4043.09, 1293.19, 679.64, 4.63),
            vec4(4007.81, 1299.52, 679.64, 353.81),
            vec4(3985.21, 1307.59, 679.64, 304.98),
            vec4(3995.42, 1320.98, 679.64, 267.29),
            vec4(3987.15, 1343.97, 679.64, 201.21),
            vec4(4005.12, 1339.05, 679.97, 126.4),
            vec4(4021.32, 1342.74, 679.97, 214.36),
            vec4(4039.99, 1328.86, 679.64, 198.77),
            vec4(4026.35, 1314.49, 679.97, 165.92),
        },
        team1_spawns = { vec4(3987.9, 1344.12, 679.64, 205.84) },
        team2_spawns = { vec4(4043.07, 1282.55, 679.64, 46.53) },
    },
    {
        id = 'arena_2',
        name = 'Wreck',
        description = 'FFA and TDM.',
        image = 'assets/map_warehouse.svg',
        center = vec3(5366.9, -1106.72, 357.59),
        radius = 400.0,
        heading = 0.0,
        spawns = {
            vec4(5355.46, -1100.58, 355.3, 17.5),
            vec4(5402.58, -1096.2, 355.21, 267.51),
            vec4(5417.39, -1063.89, 355.21, 188.55),
            vec4(5390.76, -1052.86, 355.21, 121.27),
            vec4(5347.61, -1071.65, 355.21, 108.35),
            vec4(5316.42, -1065.16, 355.21, 15.8),
            vec4(5308.46, -1124.83, 355.3, 185.82),
            vec4(5346.49, -1131.73, 355.21, 294.21),
            vec4(5370.62, -1119.64, 355.4, 306.55),
            vec4(5411.44, -1138.57, 355.21, 261.62),
            vec4(5420.65, -1166.34, 355.21, 301.18),
            vec4(5387.81, -1170.18, 355.21, 20.04),
        },
        team1_spawns = { vec4(5396.84, -1156.01, 355.21, 0.55) },
        team2_spawns = { vec4(5331.98, -1054.18, 355.21, 179.14) },
    },
    {
        id = 'pvp_1',
        name = 'Stables',
        description = '1v1–4v4.',
        image = 'assets/map_stables.jpg',
        center = vec3(-3267.18, 1685.87, 1010.78),
        radius = 200.0,
        team1_spawns = { vec4(-3264.56, 1710.91, 1006.9, 182.63) },
        team2_spawns = { vec4(-3263.69, 1659.65, 1006.9, 0.09) },
    },
    {
        id = 'pvp_2',
        name = 'Stores',
        description = '1v1–4v4.',
        image = 'assets/map_warehouse.svg',
        center = vec3(-3981.09, 2781.07, 513.31),
        radius = 200.0,
        team1_spawns = { vec4(-3981.6, 2763.71, 513.31, 8.74) },
        team2_spawns = { vec4(-3981.62, 2798.78, 513.31, 183.44) },
    },
    {
        id = 'pvp_3',
        name = 'PVP Map',
        description = '1v1–4v4.',
        image = 'assets/map_pvp.jpg',
        center = vec3(-2823.38, 1906.54, 1011.82),
        radius = 200.0,
        team1_spawns = { vec4(-2823.75, 1892.11, 1008.03, 1.78) },
        team2_spawns = { vec4(-2823.73, 1922.64, 1008.03, 185.56) },
    },
    {
        id = 'pvp_4',
        name = 'Rooftop',
        description = '1v1–4v4.',
        image = 'assets/map_rooftop.jpg',
        center = vec3(-3410.66, 2780.62, 517.29),
        radius = 200.0,
        heading = 338.02,
        team1_spawns = { vec4(-3391.31, 2774.13, 513.92, 76.6) },
        team2_spawns = { vec4(-3429.33, 2787.99, 513.92, 253.32) },
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
