# zsh as login shell, tmux plugins, fonts

zsh_path="$(command -v zsh || true)"
if [[ -z "$zsh_path" ]]; then
  warn "zsh missing (run the dnf step first)"
elif [[ "$(readlink -f "$(getent passwd "$USER" | cut -d: -f7)")" == "$(readlink -f "$zsh_path")" ]]; then
  ok "login shell is zsh"
else
  run sudo usermod -s "$zsh_path" "$USER"
fi

tpm="$DOTFILES/.config/tmux/plugins/tpm"
if [[ -x "$tpm/bin/install_plugins" ]]; then
  # Only installs plugins that are missing.
  run_sh "'$tpm/bin/install_plugins' >/dev/null"
  ok "tmux plugins"
else
  warn "tpm submodule missing (run the dotfiles step first)"
fi

fonts="$HOME/.local/share/fonts"
if compgen -G "$fonts/0xProtoNerdFont*.ttf" >/dev/null; then
  ok "0xProto Nerd Font"
else
  run mkdir -p "$fonts"
  run_sh "curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/0xProto.tar.xz | tar -xJ -C '$fonts' --wildcards '*.ttf'"
  fonts_changed=1
fi

# Alacritty cannot draw the COLRv1 emoji font Fedora ships: use the CBDT build
# (.config/fontconfig/fonts.conf rejects the COLRv1 one).
if [[ -f "$fonts/NotoColorEmoji-CBDT.ttf" ]]; then
  ok "Noto Color Emoji (CBDT)"
else
  run curl -fsSL -o "$fonts/NotoColorEmoji-CBDT.ttf" https://github.com/googlefonts/noto-emoji/raw/main/2D/fonts/NotoColorEmoji.ttf
  fonts_changed=1
fi

if [[ -n "${fonts_changed:-}" ]]; then run fc-cache -f "$fonts"; fi
