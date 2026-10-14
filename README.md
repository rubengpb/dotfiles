# dotfiles

This repo contain my own configuration.

# New machine (Fedora)

```sh
git clone --recurse-submodules https://github.com/helarteDeProgrmar/dotfiles.git ~/dotfiles
cd ~/dotfiles
setup/bootstrap.sh
```

`setup/bootstrap.sh` installs every tool, links the dotfiles with `stow` and
applies the GNOME settings. It only does what is missing, so it is safe to re-run.

- `setup/bootstrap.sh --dry-run`: show what it would do, change nothing
- `setup/bootstrap.sh --extras`: also install the occasional tools (`*-extras.txt`)
- `setup/bootstrap.sh --list`: list the steps; run some with `setup/bootstrap.sh dnf gnome`

After the first run:

1. Log out and back in (zsh, docker group, GNOME extensions).
2. `gh auth login`, then `setup/bootstrap.sh home` to clone the personal repos.
3. `sudo tailscale up`.
4. Open Zen once, close it, then `setup/bootstrap.sh user-tools` (see `zen/README.md`).

# Keeping it up to date

| I want to… | Do |
|---|---|
| add a tool | add a line to the right `setup/packages/*.txt` |
| check nothing is missing from the lists | `setup/drift.sh` |
| keep GNOME settings I changed | `setup/gnome/save.sh`, then review `git diff setup/gnome` |

Tools with their own installer (Claude Code, opencode, railway, herdr, Zen) live
in `setup/steps/60-user-tools.sh`; language toolchains in `70-languages.sh`.

# References

Code configuration in develop from `https://github.com/nvim-lua/kickstart.nvim`
