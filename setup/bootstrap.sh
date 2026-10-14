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

if [[ "$DRY_RUN" != 1 ]]; then
  sudo -v || exit 1
fi

failed=()
for f in "$steps_dir"/*.sh; do
  name="$(step_name "$f")"
  if ((${#wanted[@]})) && [[ " ${wanted[*]} " != *" $name "* ]]; then continue; fi
  log "$name — $(sed -n '1s/^# //p' "$f")"
  # Each step runs in its own subshell: a failure stops that step, not the rest.
  ( set -euo pipefail; source "$f" ) || failed+=("$name")
done

echo
if ((${#failed[@]})); then
  warn "failed steps: ${failed[*]} (re-run with: setup/bootstrap.sh ${failed[*]})"
  exit 1
fi
if [[ "$DRY_RUN" == 1 ]]; then log "done (dry run: nothing changed)"; else log "done"; fi
