#!/usr/bin/env bash
# Sets up this Fedora machine from the dotfiles. Safe to re-run: every step
# checks what is already there and only does what is missing.
#
#   setup/bootstrap.sh [options] [step...]
#
#   (no step)    run every step in order
#   step...      run only those steps, e.g. "dnf gnome" (see --list)
#   --extras     also install the occasional tools (packages/*-extras.txt)
#   --dry-run    print what would be done, change nothing
#   --list       list the steps

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

steps_dir="$SETUP/steps"

step_name() { basename "$1" .sh | sed 's/^[0-9]*-//'; }

usage() { sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

wanted=()
for arg in "$@"; do
  case "$arg" in
    --extras) export EXTRAS=1 ;;
    --dry-run) export DRY_RUN=1 ;;
    --list)
      for f in "$steps_dir"/*.sh; do
        printf '  %-12s %s\n' "$(step_name "$f")" "$(sed -n '1s/^# //p' "$f")"
      done
      exit 0 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; usage; exit 2 ;;
    *) wanted+=("$arg") ;;
  esac
done

for w in "${wanted[@]}"; do
  [[ -n "$(ls "$steps_dir"/[0-9]*-"$w".sh 2>/dev/null)" ]] || { echo "unknown step: $w (see --list)" >&2; exit 2; }
done

# Run as root, stow, fonts and every per-user tool would land in /root.
if [[ "$EUID" -eq 0 ]]; then
  echo "run setup/bootstrap.sh as your user, not with sudo: it asks for sudo itself, only where needed" >&2
  exit 1
fi

if [[ "$DRY_RUN" != 1 ]]; then
  log "sudo password (asked once, kept valid until bootstrap ends)"
  sudo -v || exit 1
  # sudo forgets the password 5 minutes after its last use: refresh it every
  # minute while this script lives, so long steps never ask again.
  ( while kill -0 "$$" 2>/dev/null; do sudo -n -v 2>/dev/null; sleep 60; done ) &
  sudo_keepalive=$!
  trap 'kill "$sudo_keepalive" 2>/dev/null' EXIT
fi

failed=()
for f in "$steps_dir"/*.sh; do
  name="$(step_name "$f")"
  if ((${#wanted[@]})) && [[ " ${wanted[*]} " != *" $name "* ]]; then continue; fi
  log "$name — $(sed -n '1s/^# //p' "$f")"
  # Each step runs in its own bash process: a failure stops that step, not the
  # rest. Not a ( subshell ) under ||: bash ignores set -e inside those.
  bash -c 'set -euo pipefail; source "$0"; source "$1"' "$SETUP/lib.sh" "$f" || failed+=("$name")
done

echo
if ((${#failed[@]})); then
  rerun="setup/bootstrap.sh"
  if [[ "$EXTRAS" == 1 ]]; then rerun+=" --extras"; fi
  warn "failed steps: ${failed[*]} (re-run with: $rerun ${failed[*]})"
  exit 1
fi
if [[ "$DRY_RUN" == 1 ]]; then log "done (dry run: nothing changed)"; else log "done"; fi
