# language toolchains: ghcup (haskell); with --extras: asdf (erlang/elixir), opam (ocaml)

zshrc_before="$(zshrc_snapshot)"

# asdf (packages/asdf-extras.txt, with --extras): pinned to the 0.14 shell
# version that .zshrc sources (asdf.sh). Without entries to install, asdf
# itself is not cloned either.
# Read the whole list first: in a `while read` loop, asdf install would eat
# the remaining lines from stdin and only the first entry would be installed.
mapfile -t entries < <(packages asdf)
if ((${#entries[@]})) && [[ ! -f "$HOME/.asdf/asdf.sh" ]]; then
  run git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0
fi
if ((${#entries[@]})) && [[ -f "$HOME/.asdf/asdf.sh" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.asdf/asdf.sh"
  for entry in "${entries[@]}"; do
    read -r plugin version <<<"$entry"
    asdf plugin list 2>/dev/null | grep -qx "$plugin" || run asdf plugin add "$plugin"
    if asdf list "$plugin" 2>/dev/null | tr -d ' *' | grep -qx "$version"; then
      ok "$plugin $version"
    else
      log "building $plugin $version (erlang takes a while)"
      run asdf install "$plugin" "$version"
    fi
  done
fi

# ghcup: non-interactive mode does not touch the shell rc unless asked to.
if [[ -x "$HOME/.ghcup/bin/ghcup" ]]; then
  ok ghcup
else
  run_installer https://get-ghcup.haskell.org env BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh
fi

# opam comes from dnf-extras.txt; .zshrc already loads opam-init when present.
if have opam; then
  if [[ -d "$HOME/.opam" ]]; then ok opam; else run opam init -y --no-setup; fi
fi

check_zshrc_untouched "$zshrc_before"
