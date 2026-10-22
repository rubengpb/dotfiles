#!/usr/bin/env bash
# Link the Zen config kept in dotfiles/zen into the active Zen profile and install.
# Works on any machine: the profile folder (random name) is read from profiles.ini
# and the install folder from the profile's compatibility.ini.
#
#   zen-link.sh [link]   symlink every managed file and apply keymap.json (idempotent, default)
#   zen-link.sh status   show the state of every managed file
#
# Overrides: ZEN_HOME (default ~/.config/zen, then ~/.zen), ZEN_PROFILE and
# ZEN_INSTALL (absolute paths).

set -euo pipefail
# die() inside $(find_zen_home) must stop the script, not just that subshell.
shopt -s inherit_errexit

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/zen"

# Paths relative to both repo_dir and the profile. Never add whole folders:
# Zen writes generated files into chrome/ and they must not land in the repo.
profile_files=(
  "user.js"
  "chrome/userChrome.css"
  "chrome/userContent.css"
)

# Paths relative to both repo_dir and the install folder (next to the zen binary).
# Reinstalling Zen wipes the install folder: run this script again afterwards.
install_files=(
  "distribution/policies.json"
)

die() { echo "zen-link: $*" >&2; exit 1; }

find_zen_home() {
  if [[ -n "${ZEN_HOME:-}" ]]; then echo "$ZEN_HOME"; return; fi
  for d in "$HOME/.config/zen" "$HOME/.zen"; do
    [[ -f "$d/profiles.ini" ]] && { echo "$d"; return; }
  done
  die "no profiles.ini found; open Zen once to create a profile"
}

# The profile bound to this install ([Install*] Default=) wins; then the
# profile marked Default=1; then the first profile.
find_profile() {
  if [[ -n "${ZEN_PROFILE:-}" ]]; then echo "$ZEN_PROFILE"; return; fi
  local home ini rel
  home="$(find_zen_home)"
  ini="$home/profiles.ini"
  rel="$(awk -F= '
    /^\[/ { sec=$0; next }
    sec ~ /^\[Install/ && $1=="Default" && !inst { inst=$2 }
    sec ~ /^\[Profile/ && $1=="Path" { path[sec]=$2; if (!first) first=$2 }
    sec ~ /^\[Profile/ && $1=="Default" && $2=="1" { def=sec }
    END {
      if (inst) print inst
      else if (def && path[def]) print path[def]
      else print first
    }' "$ini")"
  [[ -n "$rel" ]] || die "no profile listed in $ini"
  [[ "$rel" == /* ]] && echo "$rel" || echo "$home/$rel"
}

# Zen records the folder it last ran from in the profile.
find_install() {
  if [[ -n "${ZEN_INSTALL:-}" ]]; then echo "$ZEN_INSTALL"; return; fi
  local ini dir
  ini="$1/compatibility.ini"
  [[ -f "$ini" ]] || die "no compatibility.ini in $1; open Zen once"
  dir="$(awk -F= '$1=="LastPlatformDir" { print $2; exit }' "$ini")"
  [[ -x "$dir/zen" ]] || die "install folder not found: $dir"
  echo "$dir"
}

zen_running() { pgrep -x zen >/dev/null 2>&1; }

link_one() {
  local src="$1" dst="$2" label="$3" backup
  [[ -f "$src" ]] || die "missing in repo: $src"
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "  ok      $label"
    return
  fi
  if [[ -e "$dst" || -L "$dst" ]]; then
    backup="$dst.pre-dotfiles.$(date +%Y%m%d%H%M%S)"
    mv "$dst" "$backup"
    echo "  backup  $label -> $(basename "$backup")"
  fi
  ln -s "$src" "$dst"
  echo "  linked  $label"
}

status_one() {
  local src="$1" dst="$2" label="$3"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    echo "  linked   $label"
  elif [[ -e "$dst" ]]; then
    echo "  LOCAL    $label (regular file, not from dotfiles)"
  else
    echo "  missing  $label"
  fi
}

# Runs $1 (link_one or status_one) over every managed file.
each_file() {
  local action="$1" profile install
  profile="$(find_profile)"
  [[ -d "$profile" ]] || die "profile folder not found: $profile"
  install="$(find_install "$profile")"
  echo "profile: $profile"
  for f in "${profile_files[@]}"; do "$action" "$repo_dir/$f" "$profile/$f" "$f"; done
  echo "install: $install"
  for f in "${install_files[@]}"; do "$action" "$repo_dir/$f" "$install/$f" "$f"; done
}

# Zen owns zen-keyboard-shortcuts.json and rewrites it, so it cannot be a symlink:
# the overrides in keymap.json are merged into it instead (only with Zen closed).
apply_keymap() {
  local profile="$1" target="$1/zen-keyboard-shortcuts.json"
  if zen_running; then
    echo "keymap: skipped, Zen is running (close it and run again)"
    return
  fi
  [[ -f "$target" ]] || { echo "keymap: skipped, open Zen once first"; return; }
  python3 -I - "$repo_dir/keymap.json" "$target" <<'PY'
import json, os, sys

overrides = {k: v for k, v in json.load(open(sys.argv[1])).items() if not k.startswith("_")}
path = sys.argv[2]
data = json.load(open(path))
by_id = {s.get("id"): s for s in data["shortcuts"]}
changed = []
for sid, spec in overrides.items():
    s = by_id.get(sid)
    if s is None:
        print(f"  unknown  {sid} (not in this Zen version)")
        continue
    if spec is None:
        new = dict(s, disabled=True)
    else:
        *mods, key = spec.split("+")
        unknown = set(mods) - {"accel", "alt", "shift"}
        if unknown:
            sys.exit(f"keymap: bad modifiers {unknown} in {sid}")
        new = dict(s, disabled=False,
                   key="" if key.startswith("VK_") else key.lower(),
                   keycode=key if key.startswith("VK_") else None,
                   modifiers={"control": False, "meta": False,
                              "accel": "accel" in mods, "alt": "alt" in mods,
                              "shift": "shift" in mods})
    if new != s:
        s.clear(); s.update(new); changed.append(sid)
    print(f"  {'set' if sid in changed else 'ok '}      {sid} = {spec}")
if changed:
    tmp = path + ".tmp"
    with open(tmp, "w") as f:
        json.dump(data, f)
    os.replace(tmp, path)
PY
}

check_native() {
  if [[ -x "$HOME/.local/share/tridactyl/native_main" && -f "$HOME/.mozilla/native-messaging-hosts/tridactyl.json" ]]; then
    echo "tridactyl native messenger: installed"
  else
    echo "tridactyl native messenger: MISSING (see zen/README.md)"
  fi
}

case "${1:-link}" in
  link)
    each_file link_one
    echo "keymap:"
    apply_keymap "$(find_profile)"
    check_native
    zen_running && echo "Zen is running: restart it to load the changes." || true
    ;;
  status)
    each_file status_one
    check_native
    ;;
  *) die "usage: $(basename "$0") [link|status]" ;;
esac
