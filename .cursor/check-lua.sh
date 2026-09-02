#!/usr/bin/env bash
# FiveM-aware Lua validation for cursor_arena.
#
# CitizenFX Lua allows backtick hash-strings (e.g. `s_m_y_marine_01`) that the
# stock Lua 5.4 parser rejects. This script mirrors the sources into a temp dir,
# rewrites those hash-strings to plain string literals, then:
#   1. parse-checks every file with luac5.4 -p   (gating: fails on syntax errors)
#   2. runs luacheck for lint feedback            (informational: never gates)
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/cursor_arena"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mapfile -t FILES < <(cd "$SRC" && find . -name '*.lua' | sort)
echo "==> Parse-checking ${#FILES[@]} Lua files (FiveM-aware)"

fail=0
for rel in "${FILES[@]}"; do
  mkdir -p "$TMP/$(dirname "$rel")"
  # Rewrite `hash` backtick strings to "hash" so the stock parser accepts them.
  sed 's/`\([^`]*\)`/"\1"/g' "$SRC/$rel" > "$TMP/$rel"
  if ! out="$(luac5.4 -p "$TMP/$rel" 2>&1)"; then
    echo "  SYNTAX ERROR: cursor_arena/${rel#./}"
    echo "$out" | sed 's/^/    /'
    fail=$((fail + 1))
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "==> Syntax OK: all ${#FILES[@]} files parse cleanly"
else
  echo "==> Syntax FAILED: $fail file(s) with errors"
fi

if command -v luacheck >/dev/null 2>&1; then
  echo
  echo "==> luacheck lint (informational, non-gating)"
  luacheck --config "$ROOT/.luacheckrc" "$TMP" --exclude-files '' || true
fi

exit "$fail"
