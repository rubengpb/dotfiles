# link the dotfiles into $HOME with stow, init submodules

if ! have stow; then warn "stow missing (run the dnf step first)"; exit 1; fi

run git -C "$DOTFILES" submodule update --init --recursive

# A dry run first: stow aborts on conflicts (a real file where a link should go)
# and the user has to decide what to keep.
conflicts="$(cd "$DOTFILES" && stow -n -v . 2>&1 | grep -iE 'conflict|existing target' || true)"
if [[ -n "$conflicts" ]]; then
  warn "stow found files in \$HOME that are not links to the dotfiles:"
  printf '        %s\n' "$conflicts" >&2
  warn "move or delete them, then re-run: setup/bootstrap.sh dotfiles"
  exit 1
fi
run bash -c "cd '$DOTFILES' && stow ."
ok "dotfiles linked"
