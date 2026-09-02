#!/usr/bin/env bash
# Idempotent Cloud Agent setup for the cursor_arena FiveM resource.
# Installs the Lua toolchain used to validate/lint the resource's Lua sources.
# The NUI web UI is pure static HTML/CSS/JS and is served by the "arena-nui"
# terminal with Python's stdlib http.server (no extra deps required).
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "==> Installing system packages (lua5.4, luarocks, build tools)"
sudo apt-get update -y
sudo apt-get install -y --no-install-recommends \
  lua5.4 liblua5.4-dev luarocks build-essential

echo "==> Installing luacheck (Lua linter)"
if ! command -v luacheck >/dev/null 2>&1; then
  sudo luarocks install luacheck
else
  echo "luacheck already present: $(luacheck --version | head -1)"
fi

echo "==> Toolchain versions"
lua5.4 -v
luac5.4 -v
luacheck --version | head -1
python3 --version

echo "==> Setup complete"
