#!/bin/bash
# Usage: mark-merged.sh <merged_into> <old_topic...>
# 旧トピックのフロントマターに merged_into を付与し index を再生成する。
set -euo pipefail

DIR="./memory/contexts"
merged="${1:?Usage: mark-merged.sh <merged_into> <old_topic...>}"
shift

for old in "$@"; do
  f="$DIR/$old.md"
  [ -f "$f" ] || { echo "not found: $old" >&2; continue; }
  if grep -q '^merged_into:' "$f"; then
    sed -i "s/^merged_into:.*/merged_into: $merged/" "$f"
  else
    sed -i "0,/^---$/{s/^---$/---\nmerged_into: $merged/}" "$f"
  fi
done

bash "$(dirname "$0")/rebuild-index.sh"
echo "merged_into=$merged を設定: $*"
