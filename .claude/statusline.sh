#!/usr/bin/env bash
# Claude Code status line: model · effort │ dir (branch) │ context usage
input=$(cat)
[ -n "$CLAUDE_STATUSLINE_DUMP" ] && printf "%s" "$input" > "$CLAUDE_STATUSLINE_DUMP"
j() { jq -r "$1 // empty" <<<"$input"; }

model=$(j '.model.display_name')
model_id=$(j '.model.id')
dir=$(j '.workspace.current_dir')
[ -z "$dir" ] && dir=$(j '.cwd')

effort=$(j '.effort.level // .effort')
if [ -z "$effort" ] && [ -f ~/.claude/settings.json ]; then
  effort=$(jq -r --arg m "$model_id" '.modelSettings[$m].effortLevel // .effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi

[ -n "$dir" ] && branch=$(git -C "$dir" branch --show-current 2>/dev/null)
short_dir=${dir/#$HOME/\~}

pct=$(j '.context_window.used_percentage')
size=$(j '.context_window.context_window_size')
used=$(jq -r '((.context_window.current_usage // {}) | ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))) // 0' <<<"$input")
if [ -z "$pct" ] && [ -n "$size" ] && [ "$size" -gt 0 ] 2>/dev/null; then
  pct=$(( used * 100 / size ))
fi

# Usage bar: bar <percent> [width]
bar() {
  local p=$1 w=${2:-10} f i b=""
  [ "$p" -gt 100 ] && p=100
  f=$(( (p * w + 50) / 100 ))
  for ((i = 0; i < w; i++)); do [ "$i" -lt "$f" ] && b+="█" || b+="░"; done
  printf '%s' "$b"
}

k() { [ -n "$1" ] && [ "$1" -gt 0 ] 2>/dev/null && echo "$(( $1 / 1000 ))k"; }

dim=$'\e[2m'; rst=$'\e[0m'; cyan=$'\e[36m'; mag=$'\e[35m'; blue=$'\e[34m'
out="${cyan}${model}${rst}"
[ -n "$effort" ] && out+=" ${dim}·${rst} ${mag}${effort}${rst}"
out+=" ${dim}│${rst} ${blue}${short_dir}${rst}"
[ -n "$branch" ] && out+=" ${dim}(${branch})${rst}"
if [ -n "$pct" ]; then
  p=${pct%.*}
  if [ "$p" -lt 50 ]; then c=$'\e[32m'; elif [ "$p" -lt 80 ]; then c=$'\e[33m'; else c=$'\e[31m'; fi
  ctx="ctx ${p}%"
  u=$(k "$used"); s=$(k "$size")
  [ -n "$u" ] && [ -n "$s" ] && ctx+=" ${u}/${s}"
  out+=" ${dim}│${rst} ${c}${ctx}${rst}"
fi
# Rate limits: 5h session window and 7-day weekly window
rl() {
  local pct reset p c left
  pct=$(j ".rate_limits.$1.used_percentage")
  [ -z "$pct" ] && return
  reset=$(j ".rate_limits.$1.resets_at")
  p=${pct%.*}
  if [ "$p" -lt 50 ]; then c=$'\e[32m'; elif [ "$p" -lt 80 ]; then c=$'\e[33m'; else c=$'\e[31m'; fi
  left=""
  if [ -n "$reset" ]; then
    local secs=$(( reset - $(date +%s) ))
    if [ "$secs" -gt 86400 ]; then left=" $(( secs / 86400 ))d$(( secs % 86400 / 3600 ))h"
    elif [ "$secs" -gt 0 ]; then left=" $(( secs / 3600 ))h$(( secs % 3600 / 60 ))m"; fi
  fi
  printf ' %s│%s %s%s %s %s%%%s%s%s' "$dim" "$rst" "$c" "$2" "$(bar "$p" 8)" "$p" "$rst" "$dim" "$left$rst"
}
out+=$(rl five_hour 5h)
out+=$(rl seven_day 7d)
# Per-model weekly limit (Fable). Not in the status line JSON, so read it from the
# account usage endpoint (same one /usage uses), cached to avoid hitting the API on every refresh.
usage_cache=${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage.json
usage_ttl=120
refresh_usage() {
  local tok tmp
  tok=$(jq -r '.claudeAiOauth.accessToken // empty' ~/.claude/.credentials.json 2>/dev/null)
  [ -z "$tok" ] && return
  tmp=$(mktemp)
  if curl -sf -m 5 https://api.anthropic.com/api/oauth/usage \
       -H "Authorization: Bearer $tok" -H "anthropic-beta: oauth-2025-04-20" >"$tmp" \
     && jq -e .limits "$tmp" >/dev/null 2>&1; then
    mkdir -p "${usage_cache%/*}" && mv "$tmp" "$usage_cache"
  else
    rm -f "$tmp"
  fi
}
age=$(( $(date +%s) - $(stat -c %Y "$usage_cache" 2>/dev/null || echo 0) ))
[ "$age" -gt "$usage_ttl" ] && (refresh_usage &) >/dev/null 2>&1
if [ -f "$usage_cache" ]; then
  read -r fpct freset < <(jq -r '.limits[]? | select(.kind == "weekly_scoped" and (.scope.model.display_name // "" | test("fable"; "i"))) | "\(.percent) \(.resets_at)"' "$usage_cache" | head -1)
  if [ -n "$fpct" ]; then
    orange=$'\e[38;5;208m'
    fleft=""
    fsecs=$(( $(date -d "$freset" +%s 2>/dev/null || echo 0) - $(date +%s) ))
    if [ "$fsecs" -gt 86400 ]; then fleft=" $(( fsecs / 86400 ))d$(( fsecs % 86400 / 3600 ))h"
    elif [ "$fsecs" -gt 0 ]; then fleft=" $(( fsecs / 3600 ))h$(( fsecs % 3600 / 60 ))m"; fi
    out+=" ${dim}│${rst} ${orange}fable $(bar "${fpct%.*}" 8) ${fpct%.*}%${rst}${dim}${fleft}${rst}"
  fi
fi

printf '%s' "$out"
