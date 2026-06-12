#!/bin/bash
# Usage: touch-loaded.sh <topic...>
# ロードされたトピックの last_loaded をフロントマターに記録する（archive退避の判断材料）
set -euo pipefail

DIR="./memory/contexts"
TODAY=$(date +%F)

for topic in "$@"; do
  f="$DIR/$topic.md"
  if [ ! -f "$f" ]; then
    echo "skip: $topic (not found)" >&2
    continue
  fi
  if grep -q '^last_loaded:' "$f"; then
    sed -i "s/^last_loaded:.*/last_loaded: $TODAY/" "$f"
  else
    sed -i "0,/^---$/{s/^---$/---\nlast_loaded: $TODAY/}" "$f"
  fi
done
