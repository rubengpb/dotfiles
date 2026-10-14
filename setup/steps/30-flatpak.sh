# Flatpak apps from Flathub (packages/flatpak.txt)

# Fedora may name the Flathub remote "flathub" or "flathub-1": look it up by URL.
remote="$(flatpak remotes --columns=name,url | awk '$2 ~ /dl\.flathub\.org/ { print $1; exit }')"
if [[ -z "$remote" ]]; then
  run flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  remote=flathub
fi

mapfile -t wanted < <(packages flatpak)
missing=()
for app in "${wanted[@]}"; do
  flatpak info "$app" >/dev/null 2>&1 || missing+=("$app")
done

if ((${#missing[@]})); then
  log "installing from $remote: ${missing[*]}"
  run flatpak install -y --noninteractive "$remote" "${missing[@]}"
else
  ok "all ${#wanted[@]} apps installed"
fi
