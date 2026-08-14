# Spawn coordinates

Paste your coords in chat or edit these files directly:

## Hub (spawn lobby)
`cursor_arena/config/config.lua` → `Config.SpawnLobby`

```lua
spawns = {
    vec4(x, y, z, heading),
},
center = vec3(x, y, z),
exitCoords = vec4(x, y, z, heading),
exitPed = { coords = vec3(x, y, z), heading = 0.0 },
```

## Match maps (5)
`cursor_arena/config/maps.lua`

Maps: **Construction**, **The Pool**, **Dust**, **Cargo**, **Rooftops**

For each map paste:
- `center = vec3(x, y, z)`
- `spawns.ffa` list of `vec4(x, y, z, heading)`
- `spawns.team.red` / `spawns.team.blue`

Reply in chat with blocks like:

```
MAP: construction
center: x, y, z
ffa:
x, y, z, h
x, y, z, h
red:
...
blue:
...
```

and they can be filled in for you.
