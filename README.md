# dotfiles

This repo contain my own configuration.

# 1. Repo structure

The repo mirrors `$HOME`: `stow .` links every file to the same path under `~`
(e.g. `.config/nvim/` → `~/.config/nvim/`). Folders listed in
`.stow-local-ignore` are not linked.

```
dotfiles/
├── .config/
│   ├── alacritty/        terminal
│   ├── fontconfig/       emoji fallback for the terminal font
│   ├── herdr/            terminal workspace manager for AI agents
│   ├── i3/               i3 window manager
│   ├── nvim/             Neovim (based on kickstart.nvim)
│   ├── ruff/             Python linter
│   ├── tmux/             tmux + TPM (git submodule)
│   ├── tridactyl/        vim keys for Zen Browser
│   └── zathura/          PDF viewer
├── .claude/              Claude Code visual settings (TUI, status line, keys)
├── .local/share/gnome-shell/extensions/
│   └── notification-keys@rgpb/   own GNOME extension: Super+N focuses notifications, Shift+Delete clears the tray
├── .local/bin/tmux-sessionizer   one tmux session per project (prefix f, Alt+1..4)
├── .zshrc  .p10k.zsh     shell and prompt
├── .gitconfig  .npmrc    git and npm
├── wallpapers/           GNOME background (linked as ~/wallpapers)
│
│   not linked into ~ (.stow-local-ignore):
├── setup/                installs and configures a machine (section 2)
├── scripts/              standalone helpers: claude-tui.sh, zen-link.sh
├── zen/                  Zen Browser profile config (see zen/README.md)
└── README.md
```

# 2. Setup structure (loading the config on a new machine)

```
setup/
├── bootstrap.sh          entry point: runs the steps in order
├── check.sh              validates the lists and URLs, installs nothing
├── drift.sh              reports installed tools missing from the lists
├── lib.sh                helpers shared by the scripts
├── steps/                one file per step, run in numeric order
├── packages/             what to install: plain lists, one item per line
└── gnome/                GNOME settings (dconf dumps) + save.sh
```

Every step checks what is already there and only does what is missing, so any
step can be re-run safely.

| Step | File | What it does | Reads |
|---|---|---|---|
| `repos` | `10-repos.sh` | adds third-party dnf repos (Docker; Tailscale, LibreWolf, Sublime and VS Code are extras but their repos are always added) | |
| `dnf` | `20-dnf.sh` | installs dnf packages | `dnf.txt` (+ `dnf-extras.txt`, `manual-extras.txt`) |
| `services` | `25-services.sh` | enables docker (and tailscaled with `--extras`), adds you to the docker group | |
| `flatpak` | `30-flatpak.sh` | installs Flatpak apps from Flathub | `flatpak.txt` (+ `flatpak-extras.txt`) |
| `dotfiles` | `40-dotfiles.sh` | inits git submodules and runs `stow .` | `.stow-local-ignore` |
| `terminal` | `50-terminal.sh` | zsh as login shell, tmux plugins, Nerd Font and emoji font | |
| `user-tools` | `60-user-tools.sh` | Claude Code, opencode, herdr, Zen + Tridactyl (railway with `--extras`); runs `claude-tui.sh` and `zen-link.sh`; pip and npm packages | `pip.txt`, `npm.txt` |
| `languages` | `70-languages.sh` | ghcup (haskell); with `--extras`: asdf (erlang, elixir), opam (ocaml) | `asdf-extras.txt` |
| `gnome` | `80-gnome.sh` | installs and enables GNOME extensions, applies GNOME settings | `gnome-extensions.txt`, `gnome/*.dconf` |
| `home` | `90-home.sh` | creates `~/usrtmp ~/personal ~/work ~/studies`, clones personal repos | `repos.txt` |

Files in `packages/` (the "Reads" column):

- `*.txt`: installed on every machine.
- `*-extras.txt`: occasional tools, only installed with `--extras`: erlang/elixir
  (asdf), OCaml, LaTeX, tailscale, VS Code, extra browsers, railway…
- `manual-extras.txt`: `.rpm` files downloaded by hand; bootstrap only reminds you.
- `drift-ignore.txt`: dnf packages `drift.sh` should not report.

# 3. Load the config

On a new Fedora machine:

```sh
git clone --recurse-submodules https://github.com/helarteDeProgrmar/dotfiles.git ~/dotfiles
cd ~/dotfiles
setup/bootstrap.sh --dry-run    # optional: see what it would do
setup/bootstrap.sh              # add --extras for the occasional tools
```

Without `--extras` you get the daily setup (shell, editors, docker, Claude
Code, Zen, haskell). `--extras` adds what a full clone of a machine needs:
erlang/elixir via asdf, OCaml, LaTeX, tailscale, VS Code, railway and the
occasional apps (see `setup/packages/*-extras.txt`).

Run it as your user, never with `sudo` (it refuses: everything would land in
`/root`). It asks for the sudo password once at the start and keeps it valid
until it ends, so you can leave it running. Only dnf, repos, services, flatpak
and the login shell change use sudo. If a step fails, the others still run and
the summary tells you which ones to re-run.

After the first run:

1. Log out and back in (zsh, docker group, GNOME extensions).
2. `gh auth login`, then `setup/bootstrap.sh home` to clone the personal repos.
3. `sudo tailscale up` (if installed with `--extras`).
4. Open Zen once, close it, then `setup/bootstrap.sh user-tools` (see `zen/README.md`).

# 4. Load the config step by step

Pass step names to run only those. They always run in numeric order, whatever
order you type them in.

```sh
setup/bootstrap.sh --list                 # steps and what they do
setup/bootstrap.sh dnf flatpak            # only these two steps
setup/bootstrap.sh --dry-run gnome        # preview one step
setup/bootstrap.sh --extras dnf flatpak   # steps + occasional tools
```

Common cases:

| I want to… | Run |
|---|---|
| link the dotfiles only | `setup/bootstrap.sh dotfiles` (or `stow .`) |
| install what I just added to a list | `setup/bootstrap.sh dnf` (or `flatpak`, `user-tools`…) |
| apply the saved GNOME settings | `setup/bootstrap.sh gnome` (backup of the old ones in `~/.local/state/dotfiles-setup/`) |
| relink the Zen config | `scripts/zen-link.sh` (`status` to check) |
| merge the Claude Code visual settings | `scripts/claude-tui.sh` |

Some steps need an earlier one to have run at least once:

| Step | Needs |
|---|---|
| `dotfiles` | `dnf` (stow) |
| `terminal` | `dnf` (zsh, tmux), `dotfiles` (TPM submodule) |
| `user-tools` | `dnf` (npm, jq), `dotfiles` (`.npmrc`, `.claude/tui.json`) |
| `gnome` | `dnf` (jq), `dotfiles` (notification-keys extension) |
| `home` | `dnf` (gh) and `gh auth login` |

# Keeping it up to date

| I want to… | Do |
|---|---|
| add a tool | add a line to the right `setup/packages/*.txt`, then `setup/check.sh` |
| check the lists and URLs before committing | `setup/check.sh` (installs nothing) |
| check nothing is missing from the lists | `setup/drift.sh` |
| keep GNOME settings I changed | `setup/gnome/save.sh`, then review `git diff setup/gnome` |

# References

Code configuration in develop from `https://github.com/nvim-lua/kickstart.nvim`
