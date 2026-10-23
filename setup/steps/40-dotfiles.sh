# link the dotfiles into $HOME with stow, init submodules

if ! have stow; then warn "stow missing (run the dnf step first)"; exit 1; fi

run git -C "$DOTFILES" submodule update --init --recursive

# Apps write their own state next to the files we keep in these folders. When
# a folder does not exist yet, stow links the whole folder to the repo and that
# state (Claude's credentials, downloaded extensions, every tool installed in
# ~/.local/bin) lands inside the repo. Created first, they stay real folders
# with one link per file.
for d in .claude .local/bin .local/share/gnome-shell/extensions; do
  if [[ "$(readlink -f "$HOME/$d")" == "$DOTFILES"/* ]]; then
    warn "~/$d is linked as a whole folder into the repo: apps write their data into the repo"
    warn "fix: move the untracked files of $DOTFILES/$d out, delete the link, re-run this step"
    exit 1
  fi
  [[ -d "$HOME/$d" ]] || run mkdir -p "$HOME/$d"
done

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
