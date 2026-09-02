--[[
================================================================================
  MAPS — replace these with YOUR custom arena coords.

  Vanilla GTA spots ship so the resource is playable on first start.
  Swap center / polygon / spawns for your MLOs when you have them.

  Debug: set Config.Debug = true and the fence draws with numbered corners.
  Walk the perimeter, copy vector2(x, y) in order (clockwise or anti-clockwise).

  Each map needs:
    - id, name, image
    - boundaries.points (vector2) + minZ/maxZ     OR  center + radius
    - spawns            (FFA)
    - team1_spawns      (team A / red)
    - team2_spawns      (team B / blue)
================================================================================
]]

Config.Maps = {
    ---------------------------------------------------------------------------
    -- 1) CONSTRUCTION  — Alta construction pit (vanilla). Paste your MLO here.
    ---------------------------------------------------------------------------
    {
        id = 'construction',
        name = 'Construction',
        description = 'Vertical fights across unfinished floors.',
        image = 'assets/map_construction.svg',
        center = vec3(87.4, -392.6, 41.6),
        radius = 55.0,
        heading = 160.0,
        boundaries = {
            points = {
                vec2(48.0, -360.0),
                vec2(128.0, -355.0),
                vec2(132.0, -430.0),
                vec2(44.0, -434.0),
            },
            minZ = 28.0,
            maxZ = 72.0,
        },
        spawns = {
            vec4(70.2, -378.4, 41.6, 160.0),
            vec4(102.8, -376.1, 41.6, 200.0),
            vec4(110.4, -404.8, 41.6, 250.0),
            vec4(78.6, -416.2, 41.6, 340.0),
            vec4(58.9, -400.1, 41.6, 70.0),
            vec4(95.0, -392.0, 41.6, 120.0),
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

    ---------------------------------------------------------------------------
    -- 2) THE POOL  — Vinewood Hills pool deck. Swap for your pool MLO.
    ---------------------------------------------------------------------------
    {
        id = 'pool',
        name = 'The Pool',
        description = 'Open deck fights around the water.',
        image = 'assets/map_ring.svg',
        center = vec3(-819.4, 177.6, 72.2),
        radius = 42.0,
        heading = 110.0,
        boundaries = {
            points = {
                vec2(-848.0, 155.0),
                vec2(-790.0, 152.0),
                vec2(-788.0, 202.0),
                vec2(-850.0, 204.0),
            },
            minZ = 68.0,
            maxZ = 86.0,
        },
        spawns = {
            vec4(-832.6, 166.4, 71.8, 20.0),
            vec4(-806.2, 164.8, 71.8, 330.0),
            vec4(-802.4, 188.6, 71.8, 210.0),
            vec4(-834.1, 190.2, 71.8, 150.0),
            vec4(-818.8, 158.9, 71.8, 0.0),
            vec4(-819.0, 196.4, 71.8, 180.0),
        },
        team1_spawns = {
            vec4(-838.2, 164.0, 71.8, 40.0),
            vec4(-842.0, 176.2, 71.8, 80.0),
            vec4(-836.5, 188.8, 71.8, 120.0),
            vec4(-830.0, 160.4, 71.8, 20.0),
            vec4(-844.1, 170.5, 71.8, 70.0),
        },
        team2_spawns = {
            vec4(-798.4, 166.8, 71.8, 250.0),
            vec4(-794.8, 180.1, 71.8, 270.0),
            vec4(-800.2, 192.4, 71.8, 210.0),
            vec4(-808.6, 158.2, 71.8, 300.0),
            vec4(-792.9, 174.0, 71.8, 260.0),
        },
    },

    ---------------------------------------------------------------------------
    -- 3) DUST  — Sandy Shores airfield. Swap for your desert arena.
    ---------------------------------------------------------------------------
    {
        id = 'dust',
        name = 'Dust',
        description = 'Sandy mid-range battles on the airstrip.',
        image = 'assets/map_docks.svg',
        center = vec3(1731.5, 3310.4, 41.2),
        radius = 85.0,
        heading = 195.0,
        boundaries = {
            points = {
                vec2(1655.0, 3245.0),
                vec2(1815.0, 3240.0),
                vec2(1820.0, 3380.0),
                vec2(1650.0, 3385.0),
            },
            minZ = 36.0,
            maxZ = 62.0,
        },
        spawns = {
            vec4(1690.2, 3268.4, 41.1, 15.0),
            vec4(1774.8, 3266.1, 41.1, 340.0),
            vec4(1778.4, 3352.6, 41.1, 195.0),
            vec4(1686.0, 3356.2, 41.1, 165.0),
            vec4(1732.0, 3254.8, 41.1, 0.0),
            vec4(1730.4, 3368.0, 41.1, 180.0),
            vec4(1668.5, 3310.0, 41.1, 90.0),
            vec4(1794.2, 3312.4, 41.1, 270.0),
        },
        team1_spawns = {
            vec4(1682.4, 3262.0, 41.1, 20.0),
            vec4(1694.8, 3256.6, 41.1, 10.0),
            vec4(1670.1, 3278.4, 41.1, 40.0),
            vec4(1704.0, 3260.2, 41.1, 5.0),
            vec4(1664.8, 3294.0, 41.1, 70.0),
        },
        team2_spawns = {
            vec4(1784.6, 3358.4, 41.1, 200.0),
            vec4(1770.2, 3364.8, 41.1, 190.0),
            vec4(1796.0, 3342.1, 41.1, 220.0),
            vec4(1760.4, 3360.0, 41.1, 185.0),
            vec4(1800.2, 3326.6, 41.1, 250.0),
        },
    },

    ---------------------------------------------------------------------------
    -- 4) CARGO  — Port of Los Santos containers. Swap for your cargo MLO.
    ---------------------------------------------------------------------------
    {
        id = 'cargo',
        name = 'Cargo',
        description = 'Container cover and tight corridors.',
        image = 'assets/map_warehouse.svg',
        center = vec3(1015.2, -3094.6, 5.9),
        radius = 70.0,
        heading = 90.0,
        boundaries = {
            points = {
                vec2(950.0, -3155.0),
                vec2(1085.0, -3150.0),
                vec2(1088.0, -3035.0),
                vec2(948.0, -3040.0),
            },
            minZ = 2.0,
            maxZ = 28.0,
        },
        spawns = {
            vec4(980.4, -3070.2, 5.9, 90.0),
            vec4(1048.6, -3072.8, 5.9, 270.0),
            vec4(1046.1, -3118.4, 5.9, 280.0),
            vec4(978.8, -3116.0, 5.9, 95.0),
            vec4(1014.0, -3056.5, 5.9, 180.0),
            vec4(1016.4, -3132.8, 5.9, 0.0),
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

    ---------------------------------------------------------------------------
    -- 5) ROOFTOPS  — Maze Bank West roof cluster. Swap for your rooftop MLO.
    ---------------------------------------------------------------------------
    {
        id = 'rooftops',
        name = 'Rooftops',
        description = 'Parkour ledges and mid-range duels.',
        image = 'assets/map_rooftops.svg',
        center = vec3(-137.4, -620.8, 168.8),
        radius = 48.0,
        heading = 0.0,
        boundaries = {
            points = {
                vec2(-168.0, -650.0),
                vec2(-106.0, -648.0),
                vec2(-104.0, -590.0),
                vec2(-170.0, -592.0),
            },
            minZ = 155.0,
            maxZ = 190.0,
        },
        spawns = {
            vec4(-150.6, -608.4, 168.8, 160.0),
            vec4(-124.2, -610.1, 168.8, 200.0),
            vec4(-122.8, -634.6, 168.8, 20.0),
            vec4(-152.4, -632.0, 168.8, 340.0),
            vec4(-137.0, -600.8, 168.8, 180.0),
            vec4(-136.2, -640.4, 168.8, 0.0),
        },
        team1_spawns = {
            vec4(-156.8, -604.2, 168.8, 150.0),
            vec4(-148.1, -600.6, 168.8, 165.0),
            vec4(-162.0, -616.4, 168.8, 120.0),
            vec4(-154.4, -612.8, 168.8, 140.0),
            vec4(-144.6, -598.0, 168.8, 175.0),
        },
        team2_spawns = {
            vec4(-118.4, -636.8, 168.8, 330.0),
            vec4(-126.8, -640.2, 168.8, 345.0),
            vec4(-112.6, -624.0, 168.8, 300.0),
            vec4(-120.2, -628.4, 168.8, 320.0),
            vec4(-130.0, -642.6, 168.8, 355.0),
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

function Config.GetHubSpawn()
    local spawns = Config.SpawnLobby and Config.SpawnLobby.spawns
    if not spawns or #spawns == 0 then
        return vec4(5477.79, -5853.01, 1050.58, 78.04)
    end
    return spawns[math.random(#spawns)]
end
