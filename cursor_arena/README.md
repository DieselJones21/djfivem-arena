# cursor_arena

PvP arenas for **Qbox + ox** servers, modelled on the IC Arenas flow: walk up to an NPC (or bind a key), browse live lobbies, pick a loadout, and drop into a **private routing-bucket copy** of the map.

Three modes ship:

| Mode | Rules |
|------|--------|
| **Free For All** | No teams. Instant respawn. First to the kill target wins. |
| **Team Deathmatch** | Alpha vs Bravo. Instant respawn. Shared team score. Optional friendly fire per lobby. |
| **Showdown** | Ranked. One life a round. Spectate teammates. ELO moves on the result. Leaving mid-match concedes. |

## Twists vs the stock IC script

- **Your maps** — five named arenas in `config/maps.lua` (Construction, The Pool, Dust, Cargo, Rooftops). Vanilla GTA spots are filled in so it works on first start; replace the polygons and spawns with your MLOs.
- **Your weapons** — loadouts are still named Duelist / Raider / Assault / Shock / Marksman, but **each role can offer several guns** from `config/weapons.lua`.
- **ox-first** — `ox_lib`, `ox_inventory`, `ox_target`, `oxmysql`. Qbox (`qbx_core` / `qbx_medical`) is auto-detected.
- **wasabi_ambulance** is first in the ambulance detect list; the client **checks the player actually stood up** and retries if they did not.

## Dependencies

| Resource | Required |
|----------|----------|
| ox_lib | Yes |
| oxmysql | Yes (stats + match history) |
| ox_inventory | Strongly recommended |
| ox_target | Optional (falls back to qb-target, then `[E]`) |
| qbx_core | Optional (auto) |
| wasabi_ambulance **or** qbx_medical | Optional (auto) |
| pma-voice | Optional (squad radio) |

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_inventory
ensure ox_target
ensure qbx_core
ensure wasabi_ambulance
ensure pma-voice
ensure cursor_arena
```

Tables `cursor_arena_stats` and `cursor_arena_matches` are created on first start. Nothing to import by hand.

## What to edit

| File | Purpose |
|------|---------|
| `config/config.lua` | NPC, commands/keybinds, buckets, ELO, killstreaks, titles, ambulance list |
| `config/maps.lua` | **Your maps** — polygon fence + FFA / Alpha / Bravo spawns |
| `config/weapons.lua` | **Your guns** per loadout role + ox_inventory ammo items |
| `config/lobbies.lua` | Permanent FFA / TDM / Showdown rooms |
| `config/discord.lua` | Webhook (server-only, never sent to clients) |

Turn on `Config.Debug = true` and the fence draws in the world with **numbered corners** matching the `points` list.

## Player flow

1. Blip / NPC / `/arenas` / `F6` opens the lobby browser.
2. Filter FFA / TDM / Showdown. Open a card to see the map, loadouts, kill payouts, and the live scoreboard.
3. Pick a role, pick a weapon, pick a side (team modes), drop in.
4. Fight. Killfeed, hit markers, killstreak callouts, out-of-bounds countdown.
5. `/leavearena` returns you to where you entered. Match end does **not** kick you — the lobby starts the next fight.

Every command is also a **GTA Settings → Key Bindings** entry so players can bind them without you editing config.

## ox_inventory note

If weapons will not equip inside a match, add this at the bottom of `ox_inventory/client.lua` (same workaround IC Arenas documents):

```lua
exports("SetCurrentWeapon", function(ThisWeapon)
    local inArenas = LocalPlayer.state.in_arena
    if not inArenas and string.lower(ThisWeapon) ~= "weapon_unarmed" then return end
    if string.lower(ThisWeapon) == "weapon_unarmed" then currentWeapon = nil return end
    currentWeapon = {}
    currentWeapon.metadata = { durability = 100, ammo = 250, specialAmmo = "false" }
    currentWeapon.timer = false
    currentWeapon.name = ThisWeapon
end)
```

## wasabi_ambulance

The resource detects `wasabi_ambulance` / `wasabi_ambulance_v2` automatically and drives its own revive. If wasabi's death UI still appears, paste the guard in `bridges/wasabi_ambulance_guard.lua.example` near the death-screen open.

Client exports other medical scripts can query:

```lua
exports.cursor_arena:IsInArena()
exports.cursor_arena:ShouldBlockAmbulance()
```

Replicated state bags: `in_arena`, `arena_mode`, `arena_lobby`, `arena_team`, `arena_down`, `arena_spectator`.

## Admin

```cfg
add_ace group.admin arena.admin allow
```

`/arena_restoreinv [id]` — force-return a confiscated ox_inventory after a crash.

Hooks you can edit without touching match logic: `server/open_sv.lua`, `client/open_cl.lua`.
