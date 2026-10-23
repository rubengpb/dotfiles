#!/usr/bin/env bash
# Merge the versioned visual TUI settings (~/.claude/tui.json) into ~/.claude/settings.json.
# Personal settings (hooks, permissions, etc.) are left untouched.
set -euo pipefail
settings=~/.claude/settings.json
tui=~/.claude/tui.json
[ -f "$settings" ] || echo '{}' >"$settings"
tmp=$(mktemp)
jq -s '.[0] * .[1]' "$settings" "$tui" >"$tmp"
# Already merged: leave settings and the backup of the pre-merge file alone.
if [ "$(jq -S . "$tmp")" = "$(jq -S . "$settings")" ]; then
  rm -f "$tmp"
  echo "$settings already has $tui"
  exit 0
fi
# -p: settings.json is private (600), so is its backup.
cp -p "$settings" "$settings.bak"
mv "$tmp" "$settings"
echo "Merged $tui into $settings (backup: $settings.bak)"
