# tools installed per user: CLIs, Zen, pip and npm packages

zshrc_before="$(zshrc_snapshot)"

# $1 = command that proves it is installed, $2 = installer URL, then the
# command that runs the installer from stdin (see run_installer in lib.sh).
install_tool() {
  local cmd="$1"
  shift
  if have "$cmd"; then ok "$cmd"; return; fi
  log "installing $cmd"
  run_installer "$@"
  if [[ "$DRY_RUN" != 1 ]] && ! have "$cmd"; then
    warn "$cmd: the installer finished but $cmd is not in PATH"
    return 1
  fi
}

install_tool claude   https://claude.ai/install.sh bash
install_tool opencode https://opencode.ai/install bash -s -- --no-modify-path
install_tool herdr    https://herdr.dev/install.sh sh
install_tool zen      https://updates.zen-browser.app/install.sh bash

# Occasional CLIs: only with --extras.
if [[ "$EXTRAS" == 1 ]]; then
  # The installer always rewrites the shell rc of $SHELL; with sh it skips that
  # (.zshrc already loads ~/.railway/env).
  install_tool railway  https://railway.com/install.sh env SHELL=/bin/sh sh -s -- --yes
fi

# Tridactyl reads tridactylrc through its native messenger (see zen/README.md).
if [[ -x "$HOME/.local/share/tridactyl/native_main" ]]; then
  ok "tridactyl native messenger"
else
  run_installer https://raw.githubusercontent.com/tridactyl/native_messenger/master/installers/install.sh sh -s
fi

check_zshrc_untouched "$zshrc_before"

# Config that lives outside stow's reach.
if have claude; then run "$DOTFILES/scripts/claude-tui.sh"; fi
if have zen; then run "$DOTFILES/scripts/zen-link.sh" || warn "zen-link failed: open Zen once, close it, re-run this step"; fi

mapfile -t wanted < <(packages pip)
missing=()
for p in "${wanted[@]}"; do
  python3 -m pip show "$p" >/dev/null 2>&1 || missing+=("$p")
done
if ((${#missing[@]})); then
  run python3 -m pip install --user "${missing[@]}"
else
  ok "pip: all ${#wanted[@]} packages installed"
fi

mapfile -t wanted < <(packages npm)
missing=()
for p in "${wanted[@]}"; do
  npm ls -g --depth=0 "$p" >/dev/null 2>&1 || missing+=("$p")
done
if ((${#missing[@]})); then
  run npm install -g "${missing[@]}"
else
  ok "npm: all ${#wanted[@]} packages installed"
fi
