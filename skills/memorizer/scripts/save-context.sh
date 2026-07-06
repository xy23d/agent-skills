#!/bin/bash
# Usage: save-context.sh <topic> <body_file>
# body_file の内容を ./memory/contexts/<topic>.md に保存し index を再生成する。
set -euo pipefail

DIR="./memory/contexts"
today=$(date +%F)
topic="${1:?Usage: save-context.sh <topic> <body_file>}"
body="${2:?Usage: save-context.sh <topic> <body_file>}"
[ -f "$body" ] || { echo "本文ファイルがありません: $body" >&2; exit 1; }

mkdir -p "$DIR"
cp "$body" "$DIR/$topic.md"

# save も last_loaded を今日の日付で更新する（保存＝その内容を扱った扱い）
f="$DIR/$topic.md"
if grep -q '^last_loaded:' "$f"; then
  sed -i "s/^last_loaded:.*/last_loaded: $today/" "$f"
else
  sed -i "0,/^---$/{s/^---$/---\nlast_loaded: $today/}" "$f"
fi

bash "$(dirname "$0")/rebuild-index.sh"
echo "保存: $DIR/$topic.md"
