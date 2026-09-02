# cursor_arena

PvP arenas for **Qbox + ox** servers. Players talk to a world ped, land in a spawn-lobby hub, press **G**, pick a mode and map, then drop into a **private routing-bucket copy** of that map.

## Modes

| Mode | Rules |
|------|--------|
| **FFA** | Two arenas, 12 players. Instant respawn. First to 30. |
| **1v1 / 2v2 / 3v3 / 4v4** | Four maps. Whole team on one spawn. One life a round. |
| **TDM** | Same two arenas, 5v5. Instant respawn. |

## Player flow

1. Interact with the **entry ped** in the city (`interact` / ox_target / `[E]`). You teleport into the spawn lobby. Inventory is **not** taken.
2. Inside the hub, press **G** to open the Envy Arena UI.
3. **Lobbies** — tablet UI. Browse public rooms and join. Names use Discord display names when linked.
4. **Loadout** — pick FFA / 1v1–4v4 / TDM, a weapon, a map, and Orange/Blue, then drop in.
5. **Shop** — buy extra arena-only guns with the same coins as the Envy Donator Store.
6. **Ranking / History** — season board and your last drops.
7. **Clothing ped** in the hub opens **illenium-appearance** clothing (not character creator).
8. **Exit ped** sends you back to the city coords you entered from.
9. Leaving a match returns you to the **hub**, not the city.

`/arenas` from the city also walks you into the hub. `/leavearena` leaves a match, or exits the hub if you are not in one.

## Inventory & weapons

- **Nothing is confiscated.** ox_inventory stays on the player.
- In a match the inventory **UI** is closed and F2 / the weapon wheel are blocked. `invBusy` is **not** used, because ox_inventory disables firing while that state is true.
- The selected gun is **added as an ox item** (if you do not already have it) and equipped with `useSlot`, then given infinite ammo. Native `GiveWeaponToPed` is not used while ox_inventory is running — that is what made guns flash and shots fail.
- Only the arena-given gun (and any extra ammo we added) is removed when you leave. Guns you already owned stay.

## Dependencies

| Resource | Required |
|----------|----------|
| ox_lib | Yes |
| oxmysql | Yes (stats + match history; KVP fallback if missing) |
| ox_inventory | Recommended (block-in-match only) |
| interact | Preferred for peds (darktrovx). Falls back to ox_target, qb-target, then `[E]` |
| illenium-appearance | Clothing ped |
| qbx_core | Optional (auto) |
| wasabi_ambulance **or** qbx_medical | Optional (auto) |
| pma-voice | Optional (squad radio) |

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure interact
ensure illenium-appearance
ensure qbx_core
ensure wasabi_ambulance
ensure pma-voice
ensure cursor_arena
```

## What to paste (coords + guns)

See **`SPAWNS.md`**. Vanilla GTA fills ship so it boots without your MLO. Replace:

- `config/config.lua` — entry ped, hub spawns, exit ped, clothing ped
- `config/maps.lua` — center + radius, then FFA / Orange / Blue spawns
- `config/weapons.lua` — `weapon = 'WEAPON_...'` spawn names
- `config/lobbies.lua` — which maps belong to FFA / PVP / TDM

`Config.Debug = true` draws the radius bubble.

## Admin

```cfg
add_ace group.admin arena.admin allow
```

`/arena_restoreinv [id]` — unlock the in-match inventory block after a crash.

Hooks: `server/open_sv.lua`, `client/open_cl.lua`.

Exports: `IsInArena()`, `IsInHub()`, `ShouldBlockAmbulance()`. State bags: `in_arena`, `arenaHub`, `arena_mode`, `arena_lobby`, `arena_team`, `arena_down`, `arena_spectator`.

## Discord names

Lobby cards, HUD, ranking, and history prefer Discord display names. Hook `GetArenaDisplayName` in `server/open_sv.lua`, or run Badger/zdiscord, or `setr cursor_arena:discord_token "BOT_TOKEN"`.

Arena shop coins: hook `GetDonatorBalance` / `RemoveDonatorCurrency`, or set `Config.Donator.resource` / `item`. Shop guns are arena-only unlocks.

## Changelog

### 2.4.0
- Tablet / iPad lobby chrome with top tabs: Lobbies, Loadout, Shop, Ranking, History
- Public lobby cards (host, mode, weapon, map, rounds, players)
- Discord display names when linked
- Arena shop uses donator coins; shop guns are arena-only unlocks

### 2.3.0
- HUD: waiting overlay, map name, round `1/5`, round-end banner, you-highlighted slots
- Rooms drawer: Leave match / Change team while queued; Join disabled once you are in
- Match start: hide overlays before dropping NUI focus so they cannot steal clicks
- Hub `[G]` hint always dismissed when walking away from the hub
- Spectate: empty teammate list no longer aborts 2v2+ waiting
- Spawn armour set to 0 (wasabi PvP)
- Loadout cancel uses `closeLoadout` instead of closing the whole lobby
