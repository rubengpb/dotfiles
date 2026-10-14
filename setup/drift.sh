#!/usr/bin/env bash
# Shows what this machine has that setup/packages/ does not know about, so the
# lists keep matching the tools you really use. Read-only: changes nothing.
#
#   setup/drift.sh
#
# For each finding: add it to the right list, uninstall it, or (dnf only) add
# it to packages/drift-ignore.txt to stop being told about it.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

drift=0

# $1 = title, stdin = one finding per line (nothing printed if empty).
report() {
  local items
  items="$(cat)"
  [[ -n "$items" ]] || return 0
  drift=1
  log "$1"
  sed 's/^/    /' <<<"$items"
}

# Lines of $1 that are not in $2 (both newline-separated).
not_in() { grep -vxFf <(printf '%s\n' "$2") <<<"$1" || true; }

# --- dnf ----------------------------------------------------------------------
# Packages with reason "User" from every transaction except the ones that built
# the Fedora image, still installed, kernels aside.
ids="$(dnf history list 2>/dev/null | awk 'NR > 1 && !($2 == "dnf5" && $3 == "--config") { print $1 }')"
# shellcheck disable=SC2086
user_pkgs="$(dnf history info $ids 2>/dev/null |
  awk '$1 == "Install" && $3 == "User" { print $2 }' |
  sed -E 's/\.[^.]+$//; s/-[^-]+-[^-]+$//' | sort -u |
  grep -vE '^kernel' |
  while read -r p; do rpm -q "$p" >/dev/null 2>&1 && echo "$p"; done)"
known="$(EXTRAS=1 packages dnf; read_list manual-extras | awk '{ print $1 }'; read_list drift-ignore)"
not_in "$user_pkgs" "$known" | report "dnf: installed by you, not in packages/dnf*.txt"

missing="$(packages dnf | while read -r p; do rpm -q "$p" >/dev/null 2>&1 || echo "$p"; done)"
report "dnf: in packages/dnf.txt but not installed here (setup/bootstrap.sh dnf)" <<<"$missing"

# --- flatpak ------------------------------------------------------------------
apps="$(flatpak list --app --columns=application 2>/dev/null | sort -u)"
not_in "$apps" "$(EXTRAS=1 packages flatpak)" | report "flatpak: installed, not in packages/flatpak*.txt"

# --- pip / npm ----------------------------------------------------------------
pips="$(python3 -m pip list --user --not-required --format=freeze 2>/dev/null | cut -d= -f1 | tr 'A-Z' 'a-z')"
not_in "$pips" "$(read_list pip | tr 'A-Z' 'a-z')" | report "pip --user: installed, not in packages/pip.txt"

if have npm; then
  npms="$(npm ls -g --depth=0 --json 2>/dev/null | jq -r '.dependencies // {} | keys[]')"
  not_in "$npms" "$(read_list npm)" | report "npm -g: installed, not in packages/npm.txt"
fi

# --- GNOME --------------------------------------------------------------------
if have gnome-shell; then
  enabled="$(gsettings get org.gnome.shell enabled-extensions | sed -E "s/^@as //; s/[][',]//g" | tr ' ' '\n' | sed '/^$/d')"
  not_in "$enabled" "$(read_list gnome-extensions)" | report "GNOME extensions: enabled, not in packages/gnome-extensions.txt"

  changed=""
  for pair in /org/gnome/desktop/:desktop /org/gnome/shell/extensions/:extensions /org/gnome/settings-daemon/plugins/:settings-daemon; do
    [[ "$(dconf dump "${pair%%:*}")" == "$(cat "$SETUP/gnome/${pair#*:}.dconf")" ]] || changed+="${pair%%:*}"$'\n'
  done
  report "GNOME settings changed since the last setup/gnome/save.sh" <<<"${changed%$'\n'}"
fi

if ((drift)); then exit 1; fi
log "no drift: the lists match this machine"
