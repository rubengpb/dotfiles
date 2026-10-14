# tools installed per user: CLIs, Zen, pip and npm packages

zshrc_before="$(zshrc_snapshot)"

# $1 = command that proves it is installed, $2 = install snippet
install_tool() {
  if have "$1"; then ok "$1"; else log "installing $1"; run_sh "$2"; fi
}

install_tool claude   'curl -fsSL https://claude.ai/install.sh | bash'
install_tool opencode 'curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path'
# The installer always rewrites the shell rc of $SHELL; with sh it skips that
# (.zshrc already loads ~/.railway/env).
install_tool railway  'curl -fsSL https://railway.com/install.sh | SHELL=/bin/sh sh -s -- --yes'
install_tool herdr    'curl -fsSL https://herdr.dev/install.sh | sh'
install_tool zen      'bash <(curl -fsSL https://updates.zen-browser.app/install.sh)'

# Tridactyl reads tridactylrc through its native messenger (see zen/README.md).
if [[ -x "$HOME/.local/share/tridactyl/native_main" ]]; then
  ok "tridactyl native messenger"
else
  run_sh 'tmp="$(mktemp)" && curl -fsSL https://raw.githubusercontent.com/tridactyl/native_messenger/master/installers/install.sh -o "$tmp" && sh "$tmp"; rm -f "$tmp"'
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
