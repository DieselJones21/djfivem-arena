--[[
    5 preset arena maps

    Edit spawn coords freely:
      - spawns.ffa          = free-for-all spawn points (vec4 x, y, z, heading)
      - spawns.team.red     = red team spawns
      - spawns.team.blue    = blue team spawns
      - center / radius     = out-of-bounds bubble during matches

    All maps are available for every mode.
]]

Config.Maps = {
    {
        id = 'warehouse',
        label = 'Warehouse',
        description = 'Tight industrial aisles. Close-range chaos.',
        image = 'assets/map_warehouse.svg',
        center = vec3(1048.0, -3100.0, -39.0), -- CHANGE ME
        radius = 55.0,
        heading = 0.0,
        modes = { '*' },
        spawns = {
            ffa = {
                vec4(1060.0, -3100.0, -39.0, 90.0),  -- CHANGE ME
                vec4(1035.0, -3100.0, -39.0, 270.0),
                vec4(1048.0, -3085.0, -39.0, 180.0),
                vec4(1048.0, -3115.0, -39.0, 0.0),
                vec4(1070.0, -3088.0, -39.0, 135.0),
                vec4(1025.0, -3112.0, -39.0, 315.0),
                vec4(1065.0, -3110.0, -39.0, 45.0),
                vec4(1030.0, -3090.0, -39.0, 225.0),
            },
            team = {
                red = {
                    vec4(1025.0, -3115.0, -39.0, 0.0), -- CHANGE ME
                    vec4(1030.0, -3115.0, -39.0, 0.0),
                    vec4(1035.0, -3115.0, -39.0, 0.0),
                    vec4(1040.0, -3115.0, -39.0, 0.0),
                    vec4(1045.0, -3115.0, -39.0, 0.0),
                },
                blue = {
                    vec4(1025.0, -3085.0, -39.0, 180.0), -- CHANGE ME
                    vec4(1030.0, -3085.0, -39.0, 180.0),
                    vec4(1035.0, -3085.0, -39.0, 180.0),
                    vec4(1040.0, -3085.0, -39.0, 180.0),
                    vec4(1045.0, -3085.0, -39.0, 180.0),
                },
            },
        },
    },
    {
        id = 'construction',
        label = 'Construction Site',
        description = 'Vertical fights across unfinished floors.',
        image = 'assets/map_construction.svg',
        center = vec3(-160.0, -980.0, 254.0), -- CHANGE ME
        radius = 70.0,
        heading = 0.0,
        modes = { '*' },
        spawns = {
            ffa = {
                vec4(-145.0, -970.0, 254.0, 90.0),
                vec4(-175.0, -990.0, 254.0, 270.0),
                vec4(-160.0, -960.0, 254.0, 180.0),
                vec4(-160.0, -1000.0, 254.0, 0.0),
                vec4(-150.0, -985.0, 254.0, 45.0),
                vec4(-170.0, -975.0, 254.0, 225.0),
            },
            team = {
                red = {
                    vec4(-180.0, -1000.0, 254.0, 0.0),
                    vec4(-175.0, -1000.0, 254.0, 0.0),
                    vec4(-170.0, -1000.0, 254.0, 0.0),
                    vec4(-165.0, -1000.0, 254.0, 0.0),
                    vec4(-160.0, -1000.0, 254.0, 0.0),
                },
                blue = {
                    vec4(-180.0, -960.0, 254.0, 180.0),
                    vec4(-175.0, -960.0, 254.0, 180.0),
                    vec4(-170.0, -960.0, 254.0, 180.0),
                    vec4(-165.0, -960.0, 254.0, 180.0),
                    vec4(-160.0, -960.0, 254.0, 180.0),
                },
            },
        },
    },
    {
        id = 'docks',
        label = 'Shipping Docks',
        description = 'Container cover and long sightlines.',
        image = 'assets/map_docks.svg',
        center = vec3(1000.0, -3000.0, 5.9), -- CHANGE ME
        radius = 80.0,
        heading = 90.0,
        modes = { '*' },
        spawns = {
            ffa = {
                vec4(1015.0, -2990.0, 5.9, 180.0),
                vec4(985.0, -3010.0, 5.9, 0.0),
                vec4(1000.0, -2980.0, 5.9, 90.0),
                vec4(1000.0, -3020.0, 5.9, 270.0),
                vec4(1025.0, -3005.0, 5.9, 135.0),
                vec4(975.0, -2995.0, 5.9, 315.0),
            },
            team = {
                red = {
                    vec4(970.0, -3025.0, 5.9, 0.0),
                    vec4(975.0, -3025.0, 5.9, 0.0),
                    vec4(980.0, -3025.0, 5.9, 0.0),
                    vec4(985.0, -3025.0, 5.9, 0.0),
                    vec4(990.0, -3025.0, 5.9, 0.0),
                },
                blue = {
                    vec4(970.0, -2975.0, 5.9, 180.0),
                    vec4(975.0, -2975.0, 5.9, 180.0),
                    vec4(980.0, -2975.0, 5.9, 180.0),
                    vec4(985.0, -2975.0, 5.9, 180.0),
                    vec4(990.0, -2975.0, 5.9, 180.0),
                },
            },
        },
    },
    {
        id = 'arena_ring',
        label = 'Arena Ring',
        description = 'Open circular pit. Nowhere to hide.',
        image = 'assets/map_ring.svg',
        center = vec3(2800.0, -3800.0, 140.0), -- CHANGE ME
        radius = 40.0,
        heading = 0.0,
        modes = { '*' },
        spawns = {
            ffa = {
                vec4(2815.0, -3800.0, 140.0, 90.0),
                vec4(2785.0, -3800.0, 140.0, 270.0),
                vec4(2800.0, -3785.0, 140.0, 180.0),
                vec4(2800.0, -3815.0, 140.0, 0.0),
                vec4(2810.0, -3790.0, 140.0, 135.0),
                vec4(2790.0, -3810.0, 140.0, 315.0),
            },
            team = {
                red = {
                    vec4(2785.0, -3815.0, 140.0, 45.0),
                    vec4(2790.0, -3815.0, 140.0, 45.0),
                    vec4(2795.0, -3815.0, 140.0, 45.0),
                    vec4(2785.0, -3810.0, 140.0, 45.0),
                    vec4(2790.0, -3810.0, 140.0, 45.0),
                },
                blue = {
                    vec4(2815.0, -3785.0, 140.0, 225.0),
                    vec4(2810.0, -3785.0, 140.0, 225.0),
                    vec4(2805.0, -3785.0, 140.0, 225.0),
                    vec4(2815.0, -3790.0, 140.0, 225.0),
                    vec4(2810.0, -3790.0, 140.0, 225.0),
                },
            },
        },
    },
    {
        id = 'rooftops',
        label = 'City Rooftops',
        description = 'Parkour ledges and mid-range duels.',
        image = 'assets/map_rooftops.svg',
        center = vec3(-75.0, -820.0, 326.0), -- CHANGE ME
        radius = 60.0,
        heading = 0.0,
        modes = { '*' },
        spawns = {
            ffa = {
                vec4(-60.0, -810.0, 326.0, 180.0),
                vec4(-90.0, -830.0, 326.0, 0.0),
                vec4(-75.0, -800.0, 326.0, 90.0),
                vec4(-75.0, -840.0, 326.0, 270.0),
                vec4(-55.0, -825.0, 326.0, 135.0),
                vec4(-95.0, -815.0, 326.0, 315.0),
            },
            team = {
                red = {
                    vec4(-95.0, -840.0, 326.0, 0.0),
                    vec4(-90.0, -840.0, 326.0, 0.0),
                    vec4(-85.0, -840.0, 326.0, 0.0),
                    vec4(-80.0, -840.0, 326.0, 0.0),
                    vec4(-75.0, -840.0, 326.0, 0.0),
                },
                blue = {
                    vec4(-95.0, -800.0, 326.0, 180.0),
                    vec4(-90.0, -800.0, 326.0, 180.0),
                    vec4(-85.0, -800.0, 326.0, 180.0),
                    vec4(-80.0, -800.0, 326.0, 180.0),
                    vec4(-75.0, -800.0, 326.0, 180.0),
                },
            },
        },
    },
}

function Config.GetMap(mapId)
    for i = 1, #Config.Maps do
        if Config.Maps[i].id == mapId then
            return Config.Maps[i]
        end
    end
end

function Config.GetMapsForMode(modeId)
    local list = {}
    for i = 1, #Config.Maps do
        local map = Config.Maps[i]
        local allowed = false
        for j = 1, #map.modes do
            if map.modes[j] == '*' or map.modes[j] == modeId then
                allowed = true
                break
            end
        end
        if allowed then
            list[#list + 1] = map
        end
    end
    return list
end

function Config.GetHubSpawn()
    local spawns = Config.SpawnLobby and Config.SpawnLobby.spawns
    if not spawns or #spawns == 0 then
        return vec4(405.0, -997.0, -99.0, 90.0)
    end
    return spawns[math.random(#spawns)]
end
