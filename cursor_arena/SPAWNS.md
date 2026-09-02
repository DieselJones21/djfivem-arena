# Maps, hub & weapons

## Set

| What | Coords |
|------|--------|
| Entry ped | `vec4(-195.96, -237.48, 30.56, 174.6)` |
| Hub / G | `vec4(5477.79, -5853.01, 1050.58, 78.04)` radius **150** |
| Exit ped | `vec4(5477.07, -5828.0, 1049.95, 174.18)` |
| Clothing ped | `vec4(5499.02, -5865.86, 1050.95, 68.63)` |

Weapons are in `config/weapons.lua` (G17 / Spectre / Kiss AR, etc.).

## Map slots waiting for your paste

| Slot | Used by | `id` |
|------|---------|------|
| Arena 1 | FFA + TDM | `arena_1` |
| Arena 2 | FFA + TDM | `arena_2` |
| PVP 1 | 1v1–4v4 | `pvp_1` |
| PVP 2 | 1v1–4v4 | `pvp_2` |
| PVP 3 | 1v1–4v4 | `pvp_3` |
| PVP 4 | 1v1–4v4 | `pvp_4` |

Copy **one block per map**. Rename `name`. Walk the fence in order (`Config.Debug = true` numbers corners). Aim for 6+ FFA spawns on arenas, 4+ Alpha and 4+ Bravo on every map (4v4 needs 4 per side).

```
=== MAP arena_1 ===
name: 
center: vector3(x, y, z)
radius: 
minZ: 
maxZ: 
fence:
vector2(x, y)
vector2(x, y)
vector2(x, y)
vector2(x, y)
ffa_spawns:
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
alpha:
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
bravo:
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
```

Repeat that block with `arena_2`, `pvp_1`, `pvp_2`, `pvp_3`, `pvp_4`.

PVP maps still need `ffa_spawns` (unused in 1v1–4v4) **or** you can skip that list — Alpha/Bravo are what matter. Arenas need all three lists (FFA uses `ffa_spawns`, TDM uses Alpha/Bravo).
