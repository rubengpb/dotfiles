#!/usr/bin/env bash
# Checks that everything setup/ refers to still exists, without installing
# anything: package names, Flatpak IDs, GNOME extensions, pip/npm packages,
# asdf versions, repos and installer URLs. Run it before committing a change
# to setup/; exit code 1 when something is wrong.
#
#   setup/check.sh

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
EXTRAS=1   # extras must be valid too

errors=0
fail() { warn "$*"; errors=$((errors + 1)); }

# section "title" ... passed "summary": "ok" only when the section found nothing.
section() { log "$1"; section_errors=$errors; }
passed() { if ((errors == section_errors)); then ok "$1"; fi; }

# 200 when the URL answers, else the HTTP code (000 = no answer).
http_code() { curl -fsSL -o /dev/null -w '%{http_code}' --max-time 20 "$1" 2>/dev/null || true; }

section "scripts: syntax"
for f in "$SETUP"/*.sh "$SETUP"/steps/*.sh "$SETUP"/gnome/*.sh "$DOTFILES"/scripts/*.sh; do
  bash -n "$f" 2>/dev/null || fail "syntax error in ${f#"$DOTFILES"/}"
done
passed "syntax"

section "lists: no entry in two lists"
dupes="$(for l in dnf dnf-extras manual-extras drift-ignore; do read_list "$l" | awk '{ print $1 }'; done | sort | uniq -d)"
for d in $dupes; do fail "$d is in more than one packages/dnf*.txt list"; done
passed "no duplicates"

section "dnf: packages exist in the configured repos"
# Only reads metadata: skipping the repo signature check avoids an invisible
# "import this key?" prompt that would hang a non-root dnf.
dnfq() { timeout 120 dnf repoquery --setopt='*.repo_gpgcheck=0' "$@" </dev/null 2>/dev/null; }
mapfile -t wanted < <(packages dnf)
found="$(dnfq --qf '%{name}\n' "${wanted[@]}" | sort -u)"
for p in "${wanted[@]}"; do
  grep -qxF "$p" <<<"$found" && continue
  # Renamed packages keep the old name as a "provides" (nodejs -> nodejs22).
  [[ -n "$(dnfq --qf '%{name}\n' --whatprovides "$p")" ]] && continue
  if rpm -q "$p" >/dev/null 2>&1; then
    fail "dnf: $p is installed here but no configured repo has it (repo missing? setup/bootstrap.sh repos)"
  else
    fail "dnf: $p not found (typo?)"
  fi
done
passed "${#wanted[@]} checked"

if have flatpak; then
  section "flatpak: apps exist on Flathub"
  remote="$(flatpak remotes --columns=name,url | awk '$2 ~ /dl\.flathub\.org/ { print $1; exit }')"
  if [[ -z "$remote" ]]; then
    warn "no Flathub remote configured, skipping"
  else
    available="$(flatpak remote-ls --app --columns=application "$remote" 2>/dev/null)"
    mapfile -t wanted < <(packages flatpak)
    for app in "${wanted[@]}"; do
      grep -qxF "$app" <<<"$available" || fail "flatpak: $app not on Flathub"
    done
    passed "${#wanted[@]} checked"
  fi
fi

if have gnome-shell; then
  shell_version="$(gnome-shell --version | grep -oE '[0-9]+' | head -1)"
  section "GNOME extensions: available for GNOME $shell_version"
  mapfile -t uuids < <(read_list gnome-extensions)
  for uuid in "${uuids[@]}"; do
    local_meta="$DOTFILES/.local/share/gnome-shell/extensions/$uuid/metadata.json"
    if [[ -f "$local_meta" ]]; then
      jq -e --arg v "$shell_version" '."shell-version" | index($v)' "$local_meta" >/dev/null ||
        fail "$uuid (in this repo): metadata.json does not list GNOME $shell_version"
    elif [[ "$(http_code "https://extensions.gnome.org/extension-info/?uuid=$uuid&shell_version=$shell_version")" != 200 ]]; then
      fail "$uuid: not on extensions.gnome.org for GNOME $shell_version"
    fi
  done
  passed "${#uuids[@]} checked"
fi

section "pip / npm: packages exist"
while read -r p; do
  [[ "$(http_code "https://pypi.org/pypi/$p/json")" == 200 ]] || fail "pip: $p not on PyPI"
done < <(read_list pip)
while read -r p; do
  [[ "$(http_code "https://registry.npmjs.org/$p")" == 200 ]] || fail "npm: $p not on the npm registry"
done < <(read_list npm)
passed "checked"

if [[ -f "$HOME/.asdf/asdf.sh" ]]; then
  section "asdf: versions exist"
  # shellcheck source=/dev/null
  source "$HOME/.asdf/asdf.sh"
  while read -r plugin version; do
    if ! asdf plugin list 2>/dev/null | grep -qx "$plugin"; then
      warn "asdf: plugin $plugin not added here, cannot check $version"
    # Captured first: grep -q closing the pipe early would fail it under pipefail.
    elif ! grep -qxF "$version" <<<"$(asdf list all "$plugin" 2>/dev/null)"; then
      fail "asdf: $plugin $version does not exist"
    fi
  done < <(read_list asdf)
  passed "checked"
fi

section "repos: personal repos exist"
if gh auth status >/dev/null 2>&1; then
  while read -r repo _; do
    as_owner "${repo%%/*}" gh repo view "$repo" --json name >/dev/null 2>&1 || fail "repo $repo not found"
  done < <(read_list repos)
  passed "checked"
else
  warn "gh is not logged in, skipping"
fi

section "installers: URLs used by the steps answer"
# Every literal https URL in the steps; the ones built from variables are skipped.
urls="$(grep -ohE "https://[^ '\"<>|)]+" "$SETUP"/steps/*.sh | grep -v '\$' | sort -u)"
while read -r u; do
  code="$(http_code "$u")"
  [[ "$code" == 200 ]] || fail "$u answers $code"
done <<<"$urls"
passed "$(wc -l <<<"$urls") URLs checked"

echo
if ((errors)); then
  warn "$errors problem(s) found"
  exit 1
fi
log "all good"
