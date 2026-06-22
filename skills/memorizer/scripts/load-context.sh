#!/bin/bash
# Usage: load-context.sh <topic...>
# 指定トピックと depends_on を再帰解決し、存在するものを last_loaded 更新して
# 読むべき .md のパスを依存順（依存先 → 依存元）に出力する。
# 見つからないトピックは MISSING:<topic> を出力する。
set -euo pipefail

DIR="./memory/contexts"
today=$(date +%F)

declare -A seen
order=()

resolve() {
  local t="$1"
  [ -n "${seen[$t]:-}" ] && return
  seen[$t]=1
  local f="$DIR/$t.md"
  if [ ! -f "$f" ]; then
    echo "MISSING:$t"
    return
  fi
  local dep
  for dep in $(awk '
    /^depends_on:/{f=1;next}
    f && /^[^[:space:]-]/{f=0}
    f && /^[[:space:]]*-[[:space:]]/{sub(/^[[:space:]]*-[[:space:]]*/,"");print}
  ' "$f"); do
    resolve "$dep"
  done
  order+=("$t")
}

for t in "$@"; do
  resolve "$t"
done

for t in "${order[@]}"; do
  f="$DIR/$t.md"
  if grep -q '^last_loaded:' "$f"; then
    sed -i "s/^last_loaded:.*/last_loaded: $today/" "$f"
  else
    sed -i "0,/^---$/{s/^---$/---\nlast_loaded: $today/}" "$f"
  fi
  echo "$f"
done
