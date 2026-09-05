#!/usr/bin/env python3
"""Static checks: tablet Join / Create / Code must reach the server."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

def read(rel):
    return (ROOT / rel).read_text()

ui = read('client/ui.lua')
nui_fn = ui.split('local function nuiCall', 1)[-1].split('RegisterNUICallback', 1)[0]
if 'pcall' in nui_fn:
    errors.append('nuiCall still pcalls yielding callback.await (Join hangs)')
if "RegisterNUICallback('joinLobby'" not in ui:
    errors.append('missing joinLobby NUI callback')
if "RegisterNUICallback('createPrivate'" not in ui:
    errors.append('missing createPrivate NUI callback')
if 'nuiCall' not in ui:
    errors.append('missing nuiCall helper')

main = read('server/main.lua')
for name in ('joinLobby', 'createPrivate', 'joinByCode'):
    if f"cursor_arena:{name}" not in main:
        errors.append(f'server missing {name} callback')
if 'AdmitFromTablet' not in main:
    errors.append('join callbacks do not admit the player from the tablet')

state = read('server/00_state.lua')
if 'function Arena.AdmitFromTablet' not in state:
    errors.append('00_state missing AdmitFromTablet')

js = read('web/app.js')
if 'function joinSelected' not in js:
    errors.append('app.js missing joinSelected')
if "nui('joinLobby'" not in js:
    errors.append('app.js joinSelected does not call joinLobby')
if 'toast((res && res.message)' not in js:
    errors.append('failed joins do not show a tablet toast')
if 'Arena server did not answer' not in js:
    errors.append('nui fetch has no timeout / abort fallback')
if "joinCta.disabled = !lobby || !state.pick.weaponId" in js:
    errors.append('Join arena is still disabled when no weapon is pre-picked')

html = read('web/index.html')
if 'id="tabletToast"' not in html:
    errors.append('index.html missing tabletToast')
if 'id="btnJoinArena"' not in html or 'id="btnCreatePrivate"' not in html:
    errors.append('missing start-match buttons')

proc = subprocess.run(['node', '--check', str(ROOT / 'web/app.js')], capture_output=True, text=True)
if proc.returncode != 0:
    errors.append(f'app.js syntax: {proc.stderr.strip()}')

if errors:
    print('FAIL')
    for e in errors:
        print(' -', e)
    sys.exit(1)
print('OK join-button static checks')
