# third-party dnf repositories

# $1 = file it creates in /etc/yum.repos.d, $2 = URL of the vendor's .repo file
add_repo() {
  if [[ -f "/etc/yum.repos.d/$1" ]]; then ok "$1"; return; fi
  run sudo dnf config-manager addrepo --from-repofile="$2"
}

add_repo docker-ce.repo    https://download.docker.com/linux/fedora/docker-ce.repo
add_repo tailscale.repo    https://pkgs.tailscale.com/stable/fedora/tailscale.repo
add_repo librewolf.repo    https://repo.librewolf.net/librewolf.repo
add_repo sublime-text.repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo

# Microsoft publishes no .repo file for VS Code: written as in its docs.
if [[ -f /etc/yum.repos.d/vscode.repo ]]; then
  ok vscode.repo
else
  run sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  run_sh 'printf "%s\n" "[code]" "name=Visual Studio Code" "baseurl=https://packages.microsoft.com/yumrepos/vscode" "enabled=1" "autorefresh=1" "type=rpm-md" "gpgcheck=1" "gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null'
fi
