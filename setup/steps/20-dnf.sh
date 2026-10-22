# dnf packages (packages/dnf.txt)

mapfile -t wanted < <(packages dnf)
missing=()
for p in "${wanted[@]}"; do
  # --whatprovides: Fedora renames some packages and keeps the old name as an
  # alias (nodejs is installed as nodejs22); plain rpm -q would miss them.
  rpm -q --whatprovides "$p" >/dev/null 2>&1 || missing+=("$p")
done

if ((${#missing[@]})); then
  log "installing ${#missing[@]} of ${#wanted[@]}: ${missing[*]}"
  run sudo dnf install -y "${missing[@]}"
else
  ok "all ${#wanted[@]} packages installed"
fi

if [[ "$EXTRAS" == 1 ]]; then
  while read -r p; do
    rpm -q "$p" >/dev/null 2>&1 && ok "$p" || warn "$p must be installed by hand ($(grep -m1 "^$p " "$SETUP/packages/manual-extras.txt" | sed 's/^[^#]*# *//'))"
  done < <(read_list manual-extras)
fi
