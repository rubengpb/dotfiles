# Helpers shared by bootstrap.sh, drift.sh and every step. Sourced, never run.

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP="$DOTFILES/setup"
STATE="$HOME/.local/state/dotfiles-setup"
DRY_RUN="${DRY_RUN:-0}"
EXTRAS="${EXTRAS:-0}"

# Tools installed by curl scripts land outside the default PATH of a fresh shell.
export PATH="$HOME/.local/bin:$HOME/.opencode/bin:$HOME/.railway/bin:$HOME/.ghcup/bin:$HOME/.node/bin:$PATH"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m  %s\n' "$*"; }
warn() { printf '    \033[1;33m!!\033[0m  %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

# Runs a command; with DRY_RUN=1 only prints it.
run() {
  if [[ "$DRY_RUN" == 1 ]]; then printf '    +   %s\n' "$*"; else "$@"; fi
}

# Same for a snippet that needs a shell (pipes, redirections, <(...)).
run_sh() {
  if [[ "$DRY_RUN" == 1 ]]; then printf '    +   %s\n' "$1"; else bash -c "$1"; fi
}

# GNOME settings kept in setup/gnome/<file>.dconf: "dconf-path file". save.sh
# writes them, the gnome step applies them, drift.sh compares them.
GNOME_DUMPS=(
  "/org/gnome/desktop/ desktop"
  "/org/gnome/mutter/ mutter"                     # fixed number of workspaces
  "/org/gnome/shell/app-switcher/ app-switcher"   # Alt+Tab: current workspace only
  "/org/gnome/shell/keybindings/ shell-keybindings"  # Super+c screenshot, Super+a free
  "/org/gnome/shell/extensions/ extensions"
  "/org/gnome/settings-daemon/plugins/ settings-daemon"
  "/org/gnome/system/ system"                     # location services
)

# Entries of setup/packages/<name>.txt without comments or blank lines.
# Lines may carry extra fields (e.g. "erlang 27.3.4.3"); callers split them.
read_list() {
  local file="$SETUP/packages/$1.txt"
  [[ -f "$file" ]] || return 0
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$file"
}

# read_list <name>, plus <name>-extras when running with --extras.
packages() {
  read_list "$1"
  if [[ "$EXTRAS" == 1 ]]; then read_list "$1-extras"; fi
}

# Runs a command as the GitHub account that owns $1 when that account is
# logged in to gh: with several accounts, the active one may not see another
# owner's private repos. git uses it too, through the gh credential helper.
as_owner() {
  local owner="$1" token
  shift
  token="$(gh auth token --user "$owner" 2>/dev/null || true)"
  if [[ -n "$token" ]]; then GH_TOKEN="$token" "$@"; else "$@"; fi
}

# Installers that "add themselves to your shell" write through the ~/.zshrc
# symlink into this repo. Take a snapshot before them, check it after.
zshrc_snapshot() { sha1sum "$DOTFILES/.zshrc" 2>/dev/null; }
check_zshrc_untouched() {
  if [[ "$(zshrc_snapshot)" != "$1" ]]; then
    warn "an installer modified .zshrc (in the repo): review 'git diff .zshrc'"
  fi
}
