--[[
================================================================================
  MAP & SPAWN COORDINATES — PASTE YOURS HERE

  Format for every spawn:  vec4(x, y, z, heading)

  How to get coords in-game:
    1. Stand where you want the spawn
    2. Use your admin menu /txAdmin /coords command
    3. Paste the numbers below

  Each map needs:
    - center + radius  (out-of-bounds bubble)
    - spawns.ffa       (free-for-all spawns — add as many as you want)
    - spawns.team.red  (red team spawns — at least 5 recommended)
    - spawns.team.blue (blue team spawns — at least 5 recommended)

  Hub (spawn lobby) coords are in config/config.lua → Config.SpawnLobby
================================================================================
]]

Config.Maps = {
    ---------------------------------------------------------------------------
    -- 1) CONSTRUCTION
    ---------------------------------------------------------------------------
    {
        id = 'construction',
        label = 'Construction',
        description = 'Vertical fights across unfinished floors.',
        image = 'assets/map_construction.svg',
        center = vec3(0.0, 0.0, 0.0), -- PASTE center x, y, z
        radius = 70.0,
        heading = 0.0,
        modes = { '*' },
        spawns = {
            ffa = {
                -- PASTE FFA SPAWNS (vec4 x, y, z, heading)
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
            },
            team = {
                red = {
                    -- PASTE RED TEAM SPAWNS
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                },
                blue = {
                    -- PASTE BLUE TEAM SPAWNS
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                },
            },
        },
    },

    ---------------------------------------------------------------------------
    -- 2) THE POOL
    ---------------------------------------------------------------------------
    {
        id = 'pool',
        label = 'The Pool',
        description = 'Open deck fights around the pool.',
        image = 'assets/map_ring.svg',
        center = vec3(0.0, 0.0, 0.0), -- PASTE center
        radius = 55.0,
        heading = 0.0,
        modes = { '*' },
        spawns = {
            ffa = {
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
            },
            team = {
                red = {
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                },
                blue = {
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                },
            },
        },
    },

    ---------------------------------------------------------------------------
    -- 3) DUST
    ---------------------------------------------------------------------------
    {
        id = 'dust',
        label = 'Dust',
        description = 'Sandy mid-range battles.',
        image = 'assets/map_docks.svg',
        center = vec3(0.0, 0.0, 0.0), -- PASTE center
        radius = 65.0,
        heading = 0.0,
        modes = { '*' },
        spawns = {
            ffa = {
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
            },
            team = {
                red = {
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                },
                blue = {
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                },
            },
        },
    },

    ---------------------------------------------------------------------------
    -- 4) CARGO
    ---------------------------------------------------------------------------
    {
        id = 'cargo',
        label = 'Cargo',
        description = 'Container cover and tight corridors.',
        image = 'assets/map_warehouse.svg',
        center = vec3(0.0, 0.0, 0.0), -- PASTE center
        radius = 60.0,
        heading = 0.0,
        modes = { '*' },
        spawns = {
            ffa = {
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
            },
            team = {
                red = {
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                },
                blue = {
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                },
            },
        },
    },

    ---------------------------------------------------------------------------
    -- 5) ROOFTOPS
    ---------------------------------------------------------------------------
    {
        id = 'rooftops',
        label = 'Rooftops',
        description = 'Parkour ledges and mid-range duels.',
        image = 'assets/map_rooftops.svg',
        center = vec3(0.0, 0.0, 0.0), -- PASTE center
        radius = 60.0,
        heading = 0.0,
        modes = { '*' },
        spawns = {
            ffa = {
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
                vec4(0.0, 0.0, 0.0, 0.0),
            },
            team = {
                red = {
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                },
                blue = {
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
                    vec4(0.0, 0.0, 0.0, 0.0),
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
