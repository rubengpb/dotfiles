#!/usr/bin/env bash
# Saves the current GNOME settings into setup/gnome/*.dconf so the next
# bootstrap (or another machine) applies them. Run it after changing settings
# you want to keep, then review with `git diff setup/gnome`.
# Extensions are easiest to configure with Extension Manager:
# https://flathub.org/apps/com.mattjakeman.ExtensionManager
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dconf dump /org/gnome/desktop/ > "$dir/desktop.dconf"
dconf dump /org/gnome/shell/extensions/ > "$dir/extensions.dconf"
dconf dump /org/gnome/settings-daemon/plugins/ > "$dir/settings-daemon.dconf"
git -C "$dir" diff --stat -- .
