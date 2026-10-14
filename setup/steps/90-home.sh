# home folders and personal repos (packages/repos.txt)

for d in usrtmp personal work studies; do
  if [[ -d "$HOME/$d" ]]; then ok "~/$d"; else run mkdir -p "$HOME/$d"; fi
done

if ! gh auth status >/dev/null 2>&1; then
  warn "gh is not logged in: run 'gh auth login', then: setup/bootstrap.sh home"
  exit 0
fi

while read -r repo dest; do
  dest="${dest/#\~/$HOME}"
  if [[ -d "$dest/.git" ]]; then ok "$repo"; else run as_owner "${repo%%/*}" git clone "https://github.com/$repo.git" "$dest"; fi
done < <(read_list repos)
