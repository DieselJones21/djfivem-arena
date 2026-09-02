# Maps, hub & weapons — paste list

Vanilla GTA fills are in place so the resource starts. Send (or paste) the real values below.

Use `vec4(x, y, z, heading)` for peds and spawns, `vec3(x, y, z)` for hub center, `vec2(x, y)` for fence corners.

## 1) World entry ped — SET

`Config.EntryPed.coords = vec4(-195.96, -237.48, 30.56, 174.6)`

Talking to this ped teleports you into the spawn lobby. It does **not** open the UI.

## 2) Spawn lobby hub — SET

`Config.SpawnLobby`

- UI / land point: `vec4(5477.79, -5853.01, 1050.58, 78.04)`
- `center` + `radius` **150**

## 3) Exit ped (inside the hub) — near UI spawn

`Config.ExitPed.coords = vec4(5473.40, -5848.20, 1050.58, 258.04)`

Returns the player to the city coords they entered from. Send a tighter vec4 if this mark is off.

## 4) Clothing ped (inside the hub) — still needs your mark

`Config.ClothingPed.coords` is offset from the UI spawn for now.

Opens `illenium-appearance:client:openClothingShop` (clothing only).

## 5) Maps

`config/maps.lua` — for **construction**, **cargo**, and **dust** (the three used by FFA / 1v1–4v4 / TDM):

```lua
boundaries = {
    points = { vec2(x, y), ... }, -- walk the perimeter in order
    minZ = 0.0,
    maxZ = 80.0,
},
spawns        = { vec4(...), ... }, -- FFA
team1_spawns  = { vec4(...), ... }, -- Alpha
team2_spawns  = { vec4(...), ... }, -- Bravo
```

`Config.Debug = true` numbers every fence corner.

Points are **dealt**, not rolled — the list is shuffled and every point is used before repeats.

Shipping vanilla fills:

| id | Default location |
|----|------------------|
| `construction` | Alta construction pit |
| `cargo` | Port of LS containers |
| `dust` | Sandy Shores airfield |
| `pool` | Vinewood Hills pool deck (unused by default lobbies) |
| `rooftops` | Maze Bank West roof (unused by default lobbies) |

## 6) Weapon spawn names

`config/weapons.lua` — replace the `weapon = 'WEAPON_...'` field on each row with your spawn name (vanilla or addon). Labels can stay as the display name in the UI.

## Interact

Peds prefer `exports.interact:AddLocalEntityInteraction` (resource name `interact`). If that resource is not started, ox_target / qb-target / `[E]` are used automatically.
