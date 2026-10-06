#!/usr/bin/env bash
# Merge the versioned visual TUI settings (~/.claude/tui.json) into ~/.claude/settings.json.
# Personal settings (hooks, permissions, etc.) are left untouched.
set -euo pipefail
settings=~/.claude/settings.json
tui=~/.claude/tui.json
[ -f "$settings" ] || echo '{}' >"$settings"
cp "$settings" "$settings.bak"
tmp=$(mktemp)
jq -s '.[0] * .[1]' "$settings" "$tui" >"$tmp" && mv "$tmp" "$settings"
echo "Merged $tui into $settings (backup: $settings.bak)"
