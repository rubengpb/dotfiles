# GNOME: extensions and settings (setup/gnome/*.dconf)

if ! have gnome-shell; then warn "not a GNOME session, skipping"; exit 0; fi

shell_version="$(gnome-shell --version | grep -oE '[0-9]+' | head -1)"
ext_dir="$HOME/.local/share/gnome-shell/extensions"

mapfile -t uuids < <(read_list gnome-extensions)
for uuid in "${uuids[@]}"; do
  if [[ -d "$ext_dir/$uuid" || -d "/usr/share/gnome-shell/extensions/$uuid" ]]; then
    ok "$uuid"
    continue
  fi
  url="$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell_version" 2>/dev/null | jq -r '.download_url // empty' || true)"
  if [[ -z "$url" ]]; then
    warn "$uuid: not on extensions.gnome.org for GNOME $shell_version"
    continue
  fi
  run_sh "zip=\"\$(mktemp --suffix=.zip)\" && curl -fsSL -o \"\$zip\" 'https://extensions.gnome.org$url' && gnome-extensions install --force \"\$zip\"; rm -f \"\$zip\""
done

# `gnome-extensions enable` fails for an extension the running shell has not
# loaded yet (Wayland: until the next login), so edit the list directly.
current="$(gsettings get org.gnome.shell enabled-extensions)"
new="$(python3 -I - "$current" "${uuids[@]}" <<'PY'
import ast, sys
current = ast.literal_eval(sys.argv[1].removeprefix("@as "))
added = [u for u in sys.argv[2:] if u not in current]
print(str(current + added) if added else "")
PY
)"
if [[ -n "$new" ]]; then
  run gsettings set org.gnome.shell enabled-extensions "$new"
  warn "new extensions start after logging out and back in"
else
  ok "extensions enabled"
fi
if [[ "$(gsettings get org.gnome.shell disable-user-extensions)" == true ]]; then
  run gsettings set org.gnome.shell disable-user-extensions false
fi

# Settings. dconf load merges into the current values, so keep a full backup
# of what was there before.
backed_up=""
for entry in "${GNOME_DUMPS[@]}"; do
  read -r path name <<<"$entry"
  file="$SETUP/gnome/$name.dconf"
  if [[ ! -f "$file" ]]; then
    warn "$path is not saved yet: run setup/gnome/save.sh on the machine whose settings you want"
    continue
  fi
  if [[ "$(dconf dump "$path")" == "$(cat "$file")" ]]; then
    ok "$path"
    continue
  fi
  if [[ -z "$backed_up" ]]; then
    backed_up="$STATE/dconf-before-$(date +%Y%m%d-%H%M%S).ini"
    run mkdir -p "$STATE"
    run_sh "dconf dump / > '$backed_up'"
    [[ "$DRY_RUN" == 1 ]] || ok "previous settings saved in $backed_up (restore: dconf load / < that file)"
  fi
  run_sh "dconf load '$path' < '$file'"
  [[ "$DRY_RUN" == 1 ]] || ok "$path applied"
done
