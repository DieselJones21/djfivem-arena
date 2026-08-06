# cursor_arena

Configurable FiveM PVP arena with a **spawn lobby hub**, custom NUI, **ox_inventory** loadouts, and **wasabi_ambulance** death/revive handling.

## How it works

1. Player talks to the **world entry ped** (`[E]`) → teleported into the **spawn lobby map**
2. Inside the spawn lobby, press **`G`** → opens the matchmaking UI
3. Pick mode → map → weapon → queue / private / browse
4. Match ends → returned to the **spawn lobby** (not the city)
5. Talk to the **exit ped** in the hub (or `/arena_leave`) → back to the city

## Features

- Modes: Pistol FFA, SMG FFA, Rifle FFA, Team Deathmatch, 1v1–5v5
- **3 weapon classes** — Pistol / SMG / Rifle — **5 weapons each**
- **5 preset maps** with editable FFA + team spawn coords
- Public queue + private lobbies
- Custom lobby UI + match HUD
- ox_inventory stash → loadout → restore
- wasabi_ambulance arena death/respawn bridge
- Framework auto-detect: ESX / QBCore / QBX / standalone

## Dependencies

| Resource | Required |
|----------|----------|
| ox_lib | Yes |
| ox_inventory | Yes (can disable in config) |
| wasabi_ambulance | Optional |

## Install

```cfg
ensure ox_lib
ensure ox_inventory
ensure wasabi_ambulance
ensure cursor_arena
```

### Config files to edit

| File | What to change |
|------|----------------|
| `config/config.lua` | Entry ped, **spawn lobby hub coords**, menu key (`G`) |
| `config/maps.lua` | **5 maps** — change `center`, `spawns.ffa`, `spawns.team` |
| `config/weapons.lua` | 5 pistols / 5 SMGs / 5 rifles (ox_inventory item names) |
| `config/modes.lua` | Score limits, player counts, which class each mode uses |

## Spawn lobby hub

In `config/config.lua` → `Config.SpawnLobby`:

```lua
Config.SpawnLobby = {
    spawns = {
        vec4(405.0, -997.0, -99.0, 90.0), -- CHANGE to your lobby MLO
        -- more hub spawn points...
    },
    center = vec3(405.0, -997.0, -99.0),
    radius = 40.0,
    exitCoords = vec4(-265.0, -963.0, 31.2, 200.0), -- back to city
    exitPed = { ... }, -- ped inside hub to leave
}
```

World entry ped is `Config.EntryPed`.

## Weapon classes

Only three classes in `config/weapons.lua`:

- `pistols` — 5 weapons
- `smgs` — 5 weapons
- `rifles` — 5 weapons

Modes can lock to one class (`weaponCategory = 'pistols'`) or allow all three (`'choice'`).

## Maps

Five presets in `config/maps.lua`. For each map edit:

- `center` / `radius`
- `spawns.ffa` — list of `vec4(x, y, z, heading)`
- `spawns.team.red` / `spawns.team.blue`

## Player commands

| Input | Action |
|-------|--------|
| Entry ped `[E]` | Teleport into spawn lobby |
| **`G`** (in hub) | Open / close lobby UI |
| Exit ped `[E]` | Leave hub to city |
| `/arena` | Enter hub (or open UI if already inside) |
| `/arena_leave` | Leave match → hub, or exit hub → city |

## Admin

```cfg
add_ace group.admin arena.admin allow
add_ace group.admin arena.forcestart allow
```

| Command | Description |
|---------|-------------|
| `/arena_forcestart` | Force start current lobby |
| `/arena_restoreinv` | Restore a stuck ox_inventory stash |

## Exports

```lua
exports.cursor_arena:IsInArena()          -- client
exports.cursor_arena:ShouldBlockAmbulance()
exports.cursor_arena:IsInArena(source)    -- server
exports.cursor_arena:IsInHub(source)
exports.cursor_arena:LeaveArena(source)
```

## wasabi_ambulance

See `bridges/wasabi_ambulance_guard.lua.example` — paste near death UI / EMS interactions so arena matches are not overridden.
