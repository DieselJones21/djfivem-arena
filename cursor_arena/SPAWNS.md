# Maps & spawns

Edit `config/maps.lua`. Each map needs a fence and three spawn lists.

## Fence

Prefer a polygon (IC Arenas style):

```lua
boundaries = {
    points = {
        vec2(x, y), -- corner 1
        vec2(x, y), -- corner 2
        -- walk the perimeter in order
    },
    minZ = 0.0,
    maxZ = 80.0,
},
```

`Config.Debug = true` draws the fence and numbers every corner in that order.

A `center` + `radius` bubble still works as a fallback.

## Spawns

```lua
spawns        = { vec4(x, y, z, heading), ... } -- FFA
team1_spawns  = { vec4(...), ... }              -- Alpha
team2_spawns  = { vec4(...), ... }              -- Bravo
```

Points are **dealt**, not rolled. The list is shuffled and every point is used before any repeats, so more points means people spawn further apart.

## Shipping maps

Vanilla GTA fills are in place so you can test without an MLO:

| id | Default location |
|----|------------------|
| `construction` | Alta construction pit |
| `pool` | Vinewood Hills pool deck |
| `dust` | Sandy Shores airfield |
| `cargo` | Port of LS containers |
| `rooftops` | Maze Bank West roof |

Replace coords with your maps, then point lobbies at a map id in `config/lobbies.lua`.
