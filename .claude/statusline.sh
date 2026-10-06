#!/usr/bin/env bash
# Claude Code status line: model · effort │ dir (branch) │ context usage
input=$(cat)
[ -n "$CLAUDE_STATUSLINE_DUMP" ] && printf "%s" "$input" > "$CLAUDE_STATUSLINE_DUMP"
# Extract every field in a single jq call (each extra jq fork costs ~5ms).
eval "$(jq -r '
  def n: . // "" | tostring;
  @sh "model=\(.model.display_name | n)",
  @sh "model_id=\(.model.id | n)",
  @sh "dir=\(.workspace.current_dir // .cwd | n)",
  @sh "effort=\((.effort | objects | .level) // (.effort | strings) | n)",
  @sh "pct=\(.context_window.used_percentage | n)",
  @sh "size=\(.context_window.context_window_size | n)",
  @sh "used=\((.context_window.current_usage // {}) | (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))",
  @sh "rl5_pct=\(.rate_limits.five_hour.used_percentage | n) rl5_reset=\(.rate_limits.five_hour.resets_at | n)",
  @sh "rl7_pct=\(.rate_limits.seven_day.used_percentage | n) rl7_reset=\(.rate_limits.seven_day.resets_at | n)"
' <<<"$input")"
printf -v now '%(%s)T' -1

if [ -z "$effort" ] && [ -f ~/.claude/settings.json ]; then
  effort=$(jq -r --arg m "$model_id" '.modelSettings[$m].effortLevel // .effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi

[ -n "$dir" ] && branch=$(git -C "$dir" branch --show-current 2>/dev/null)
short_dir=${dir/#$HOME/\~}

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
# rl <label> <percent> <reset epoch>
rl() {
  local pct=$2 reset=$3 p c left
  [ -z "$pct" ] && return
  p=${pct%.*}
  if [ "$p" -lt 50 ]; then c=$'\e[32m'; elif [ "$p" -lt 80 ]; then c=$'\e[33m'; else c=$'\e[31m'; fi
  left=""
  if [ -n "$reset" ]; then
    local secs=$(( ${reset%.*} - now ))
    if [ "$secs" -gt 86400 ]; then left=" $(( secs / 86400 ))d$(( secs % 86400 / 3600 ))h"
    elif [ "$secs" -gt 0 ]; then left=" $(( secs / 3600 ))h$(( secs % 3600 / 60 ))m"; fi
  fi
  printf ' %s│%s %s%s %s %s%%%s%s%s' "$dim" "$rst" "$c" "$1" "$(bar "$p" 8)" "$p" "$rst" "$dim" "$left$rst"
}
out+=$(rl 5h "$rl5_pct" "$rl5_reset")
out+=$(rl 7d "$rl7_pct" "$rl7_reset")
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
age=$(( now - $(stat -c %Y "$usage_cache" 2>/dev/null || echo 0) ))
[ "$age" -gt "$usage_ttl" ] && (refresh_usage &) >/dev/null 2>&1
if [ -f "$usage_cache" ]; then
  # resets_at is ISO 8601 with fractional seconds and offset; convert to epoch in jq
  read -r fpct freset < <(jq -r '
    def epoch: capture("^(?<d>[0-9-]+T[0-9:]+)(\\.[0-9]+)?(?<z>Z|(?<s>[+-])(?<h>[0-9]{2}):?(?<m>[0-9]{2}))?$")
      | ((.d + "Z") | fromdateiso8601)
        - (if .s then ((.h | tonumber) * 3600 + (.m | tonumber) * 60) * (if .s == "+" then 1 else -1 end) else 0 end);
    first(.limits[]? | select(.kind == "weekly_scoped" and (.scope.model.display_name // "" | test("fable"; "i"))))
    | "\(.percent) \(.resets_at | try epoch catch 0)"' "$usage_cache")
  if [ -n "$fpct" ]; then
    orange=$'\e[38;5;208m'
    fleft=""
    fsecs=$(( ${freset:-0} - now ))
    if [ "$fsecs" -gt 86400 ]; then fleft=" $(( fsecs / 86400 ))d$(( fsecs % 86400 / 3600 ))h"
    elif [ "$fsecs" -gt 0 ]; then fleft=" $(( fsecs / 3600 ))h$(( fsecs % 3600 / 60 ))m"; fi
    out+=" ${dim}│${rst} ${orange}fable $(bar "${fpct%.*}" 8) ${fpct%.*}%${rst}${dim}${fleft}${rst}"
  fi
fi

printf '%s' "$out"
