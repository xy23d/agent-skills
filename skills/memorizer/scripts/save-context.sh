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
f="$DIR/$topic.md"

# フロントマターを save が所有する。本文にフロントマターが無くても必ず健全化するため、
# 先頭が --- でなければ topic/updated/last_loaded ブロックを合成して前置する。
# （save 経由で新規作成したトピックが -/- のまま固定化する不具合の根本対策）
if [ "$(head -n1 "$f")" != "---" ]; then
  tmp=$(mktemp)
  {
    printf -- '---\ntopic: %s\nupdated: %s\nlast_loaded: %s\n---\n\n' "$topic" "$today" "$today"
    cat "$f"
  } > "$tmp"
  mv "$tmp" "$f"
else
  # 既存フロントマターは updated / last_loaded を当日に更新（無ければ挿入）。
  # save = その内容を今日扱った、とみなす。
  if grep -q '^updated:' "$f"; then
    sed -i "s/^updated:.*/updated: $today/" "$f"
  else
    sed -i "0,/^---$/{s/^---$/---\nupdated: $today/}" "$f"
  fi
  if grep -q '^last_loaded:' "$f"; then
    sed -i "s/^last_loaded:.*/last_loaded: $today/" "$f"
  else
    sed -i "0,/^---$/{s/^---$/---\nlast_loaded: $today/}" "$f"
  fi
fi

bash "$(dirname "$0")/rebuild-index.sh"
echo "保存: $DIR/$topic.md"
