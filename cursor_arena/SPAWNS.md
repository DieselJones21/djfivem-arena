# Maps, hub & weapons

## Set

| What | Coords |
|------|--------|
| Entry ped | `vec4(-195.96, -237.48, 30.56, 174.6)` |
| Hub / G | `vec4(5477.79, -5853.01, 1050.58, 78.04)` radius **150** |
| Exit ped | `vec4(5477.07, -5828.0, 1049.95, 174.18)` |
| Clothing ped | `vec4(5499.02, -5865.86, 1050.95, 68.63)` |

Weapons are in `config/weapons.lua` (`WEAPON_BLUEWIRE` for Blue Wire).

Bounds are a **radius from center**. No fence.

All six maps are pasted (`arena_1`, `arena_2`, `pvp_1`–`pvp_4`). TDM uses one Alpha mark and one Bravo mark (whole side lands there).

```
=== MAP arena_1 ===
name: 
center: vector3(x, y, z)
radius: 
ffa (12):
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
alpha (5):
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
bravo (5):
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
vector4(x, y, z, heading)
```

```
=== MAP pvp_1 ===
name: 
center: vector3(x, y, z)
radius: 
alpha: vector4(x, y, z, heading)
bravo: vector4(x, y, z, heading)
```

Repeat `arena_2` like arena_1, and `pvp_2` `pvp_3` `pvp_4` like pvp_1.
