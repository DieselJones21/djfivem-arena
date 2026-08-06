# cursor_arena

Configurable FiveM PVP arena with custom NUI, **ox_inventory** loadouts, and **wasabi_ambulance** death/revive handling.

## Features

- Modes: Pistol FFA, Rifle FFA, Team Deathmatch, 1v1, 2v2, 3v3, 4v4, 5v5
- Weapon choice per mode (category-locked or open choice)
- Multiple maps/locations with FFA + team spawns
- Public queue matchmaking + private lobbies
- Custom lobby UI + in-match HUD (timer, scores, killfeed, countdown)
- ox_inventory: stash street gear → grant match loadout → restore on leave
- wasabi_ambulance: arena owns death/respawn while in a match
- Framework auto-detect: ESX / QBCore / QBX / standalone
- Almost everything driven from `config/`

## Dependencies

| Resource | Required |
|----------|----------|
| [ox_lib](https://github.com/overextended/ox_lib) | Yes |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Yes (can disable in config for fallback weapons) |
| wasabi_ambulance | Optional but supported |
| ESX / QB / QBX | Optional |

## Install

1. Copy `cursor_arena` into your server `resources` folder.
2. Ensure start order in `server.cfg`:

```cfg
ensure ox_lib
ensure ox_inventory
ensure wasabi_ambulance
ensure cursor_arena
```

3. Edit configs:
   - `config/config.lua` — general, lobby marker, inventory, ambulance, rewards
   - `config/modes.lua` — modes, score/time limits, team sizes
   - `config/maps.lua` — **replace placeholder coords with your arenas/MLOs**
   - `config/weapons.lua` — weapon items must match your ox_inventory items

4. Restart / `ensure cursor_arena`.

## Player usage

- `/arena` or **F7** (configurable) opens the lobby UI
- Walk up to the lobby marker/ped and press **E**
- Flow: Mode → Map → Weapon → Queue / Private / Browse
- `/arena_leave` leaves queue or match

## Admin

| Command | ACE | Description |
|---------|-----|-------------|
| `/arena_forcestart` | `arena.forcestart` | Force start current lobby |
| `/arena_restoreinv` | `arena.admin` | Restore a player's arena stash |

```cfg
add_ace group.admin arena.admin allow
add_ace group.admin arena.forcestart allow
```

## ox_inventory

When a match starts the resource:

1. Registers a per-player stash (`arena_<serverId>`)
2. Moves current inventory into that stash
3. Clears inventory and grants the chosen weapon + ammo (+ optional extras)
4. On leave/end, clears loadout and restores the stash

Tune in `Config.OxInventory`. Weapon `weapon` / `ammoItem` names in `config/weapons.lua` must exist in ox_inventory.

## wasabi_ambulance

While `LocalPlayer.state.arenaActive` is true (set automatically in-match):

- Arena listens for death and handles respawn / round flow
- Client revive uses `NetworkResurrectLocalPlayer` + optional wasabi revive event
- Death screen from wasabi should be blocked via the state bag / export

Exports you can use inside wasabi (or other ambulance scripts):

```lua
-- returns true if local player is in an arena match
exports.cursor_arena:IsInArena()
exports.cursor_arena:ShouldBlockAmbulance()
```

Server:

```lua
exports.cursor_arena:IsInArena(source)
exports.cursor_arena:LeaveArena(source)
```

If your wasabi fork uses different event names, set them in `Config.WasabiAmbulance`.

Suggested wasabi guard (add near death UI / ambulance interaction):

```lua
if GetResourceState('cursor_arena') == 'started' and exports.cursor_arena:ShouldBlockAmbulance() then
    return
end
```

## Configuring maps

Each map in `config/maps.lua` needs:

- `center` + `radius` (out-of-bounds pushback)
- `spawns.ffa` — list of `vec4`
- `spawns.team.red` / `spawns.team.blue` — team spawns
- `modes` — list of mode ids or `'*'`

Placeholder coordinates are included so the resource boots; **replace them before going live**.

## Configuring modes

Key fields in `config/modes.lua`:

- `type`: `ffa` | `tdm` | `team`
- `weaponCategory`: `pistols` | `rifles` | `any` | `choice` | …
- `allowWeaponChoice`: show weapon picker
- `minPlayers` / `maxPlayers` / `teamSize`
- `scoreLimit` / `timeLimit` / `respawn`

## UI

NUI lives in `web/`. Brand-forward lobby with mode/map/weapon selection and match HUD. No external build step.

## Notes

- Friendly fire is off for team modes by default (`mode.friendlyFire` / `Config.Rules`)
- Infinite ammo toggle: `Config.Rules.infiniteAmmo`
- Rewards are disabled by default; enable in `Config.Rewards`
