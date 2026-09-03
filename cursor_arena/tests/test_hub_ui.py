#!/usr/bin/env python3
"""Static checks for the hub G-key tablet path."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

def read(rel):
    return (ROOT / rel).read_text()

fx = read('fxmanifest.lua')
if "server/00_state.lua" not in fx:
    errors.append('fxmanifest missing server/00_state.lua')
if fx.find("server/00_state.lua") > fx.find("server/main.lua"):
    errors.append('00_state.lua must load before main.lua')
if "config/discord.lua" not in fx:
    errors.append('fxmanifest missing config/discord.lua')

main = read('server/main.lua')
if 'pcall(bootstrap' not in main:
    errors.append('getBootstrap is not pcall-wrapped')
if re.search(r'if Arena\.PlayerLobby\[source\]', main):
    errors.append('unguarded Arena.PlayerLobby[source] in main.lua')
if 'EnsurePlayerHub' not in main:
    errors.append('getBootstrap does not use EnsurePlayerHub')
if 'pcall(function()' not in main or 'listLobbies' not in main:
    errors.append('listLobbies is not pcall-wrapped')

ui = read('client/ui.lua')
for needle in ('EnsureHubState', 'ToggleMenu', 'IsInSpawnLobby', 'getBootstrap', 'SetNuiFocusKeepInput'):
    if needle not in ui:
        errors.append(f'client/ui.lua missing {needle}')

# Tablet must appear before the server callback returns.
open_fn = ui.split('function Arena.Client.OpenUI()', 1)[-1].split('function Arena.Client.ToggleMenu()', 1)[0]
focus_at = open_fn.find('SetNuiFocus(true, true)')
await_at = open_fn.find("lib.callback.await('cursor_arena:getBootstrap'")
if focus_at < 0:
    errors.append('OpenUI never takes NUI focus')
elif await_at >= 0 and await_at < focus_at:
    errors.append('OpenUI waits on getBootstrap before SetNuiFocus — G will look dead if the callback hangs')
if "action = 'close'" in open_fn and open_fn.find("action = 'close'") < open_fn.find("action = 'open'"):
    errors.append('OpenUI still sends close before open (can hide the tablet)')
if 'CreateThread' not in open_fn:
    errors.append('OpenUI does not fetch bootstrap in a background thread')

# Game-side G must not close the tablet (press/release used to flash it shut).
toggle_fn = ui.split('function Arena.Client.ToggleMenu()', 1)[-1].split('function Arena.Client.CloseUI()', 1)[0]
if 'CloseUI()' in toggle_fn:
    errors.append('ToggleMenu still closes the tablet from the game G key')

client_main = read('client/main.lua')
if 'ToggleMenu' not in client_main:
    errors.append('client/main.lua G handler does not call ToggleMenu')
if "RegisterKeyMapping('+cursor_arena_open'" not in client_main:
    errors.append('missing +cursor_arena_open RegisterKeyMapping (press-only)')
if 'IsControlJustReleased(0, 47)' in client_main or 'IsDisabledControlJustReleased(0, 47)' in client_main:
    errors.append('G fallback still listens for key release (closes the tablet on the same tap)')
if 'IsControlJustPressed(0, 47)' not in client_main and 'IsDisabledControlJustPressed(0, 47)' not in client_main:
    errors.append('missing G control press fallback')
if 'DisableControlAction(0, 47' not in client_main:
    errors.append('G is not disabled while the tablet is open')

state = read('server/00_state.lua')
if 'Arena.PlayerLobby = Arena.PlayerLobby or {}' not in state:
    errors.append('00_state.lua does not init PlayerLobby')
if 'function Arena.EnsurePlayerHub' not in state:
    errors.append('00_state.lua missing EnsurePlayerHub')
if 'function Arena.IsInSpawnLobby' not in state:
    errors.append('00_state.lua missing server IsInSpawnLobby')

match = read('server/match.lua')
if 'EnsurePlayerHub' not in match:
    errors.append('JoinLobby does not use EnsurePlayerHub')

js = ROOT / 'web/app.js'
proc = subprocess.run(['node', '--check', str(js)], capture_output=True, text=True)
if proc.returncode != 0:
    errors.append(f'app.js syntax: {proc.stderr.strip()}')

appjs = js.read_text()
if "action === 'open'" not in appjs:
    errors.append('app.js does not handle open action')
if 'if (msg.seconds) hideUI()' not in appjs:
    errors.append('countdown still hides the tablet when seconds is 0')
# Unconditional hideUI on countdown is the leftover-match-flag bug.
if re.search(r"action === 'countdown'\) \{\s*hideUI\(\)", appjs):
    errors.append('countdown hides the tablet unconditionally')
if 'openUI' in appjs and 'catch' not in appjs.split('function openUI', 1)[-1].split('function hideMatchChrome', 1)[0]:
    errors.append('openUI is not try/catch wrapped')

if errors:
    print('FAIL')
    for e in errors:
        print(' -', e)
    sys.exit(1)
print('OK hub UI static checks')
