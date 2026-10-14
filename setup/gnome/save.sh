#!/usr/bin/env bash
# Saves the current GNOME settings into setup/gnome/*.dconf so the next
# bootstrap (or another machine) applies them. Run it after changing settings
# you want to keep, then review with `git diff setup/gnome`.
# Which parts of GNOME are saved: GNOME_DUMPS in setup/lib.sh.
# Extensions are easiest to configure with Extension Manager:
# https://flathub.org/apps/com.mattjakeman.ExtensionManager
set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"
for entry in "${GNOME_DUMPS[@]}"; do
  read -r path name <<<"$entry"
  dconf dump "$path" > "$SETUP/gnome/$name.dconf"
done
git -C "$SETUP" status --short -- gnome
