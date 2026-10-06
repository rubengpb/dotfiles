#!/usr/bin/env bash
# Claude Code status line: model · effort │ dir (branch) │ context usage
input=$(cat)
j() { jq -r "$1 // empty" <<<"$input"; }

model=$(j '.model.display_name')
model_id=$(j '.model.id')
dir=$(j '.workspace.current_dir')
[ -z "$dir" ] && dir=$(j '.cwd')

effort=$(j '.effort.level // .effort')
if [ -z "$effort" ] && [ -f ~/.claude/settings.json ]; then
  effort=$(jq -r --arg m "$model_id" '.modelSettings[$m].effortLevel // .effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
fi

branch=$(git -C "$dir" branch --show-current 2>/dev/null)
short_dir=${dir/#$HOME/\~}

pct=$(j '.context_window.used_percentage')
size=$(j '.context_window.context_window_size')
used=$(jq -r '((.context_window.current_usage // {}) | ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))) // 0' <<<"$input")
if [ -z "$pct" ] && [ -n "$size" ] && [ "$size" -gt 0 ] 2>/dev/null; then
  pct=$(( used * 100 / size ))
fi

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
printf '%s' "$out"
