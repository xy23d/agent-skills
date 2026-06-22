#!/bin/bash
# Usage: archive.sh [days]
# last_loaded（なければ updated、なければ mtime）が days 日より古いトピックを
# archive/ に退避し、index.md を再生成する
set -euo pipefail

DAYS="${1:-30}"
DIR="./memory/contexts"
if [ ! -d "$DIR" ]; then
  echo "コンテキストディレクトリがありません: $DIR" >&2
  exit 1
fi

CUTOFF=$(date -d "-$DAYS days" +%s)
ARCHIVE="$DIR/archive"
mkdir -p "$ARCHIVE"
moved=0

INDEX="$DIR/index.md"
[ -f "$INDEX" ] || { echo "index がありません: $INDEX" >&2; exit 1; }

# index.md の各行（topic / updated / last_loaded）だけで退避対象を判定する。
while IFS=$'\t' read -r topic updated last_loaded; do
  [ -z "$topic" ] && continue
  ref="$last_loaded"
  { [ -z "$ref" ] || [ "$ref" = "-" ]; } && ref="$updated"
  f="$DIR/$topic.md"
  if [ "$ref" != "-" ] && [ -n "$ref" ]; then
    ts=$(date -d "$ref" +%s 2>/dev/null) || ts=$(stat -c %Y "$f" 2>/dev/null || echo 0)
  else
    ts=$(stat -c %Y "$f" 2>/dev/null || echo 0)
  fi
  if [ "$ts" -lt "$CUTOFF" ]; then
    mv "$f" "$ARCHIVE/"
    [ -d "$DIR/$topic" ] && mv "$DIR/$topic" "$ARCHIVE/"
    echo "archived: $topic"
    moved=$((moved+1))
  fi
done < <(tail -n +3 "$INDEX" | awk -F'|' '{gsub(/^ +| +$/,"",$2);gsub(/^ +| +$/,"",$3);gsub(/^ +| +$/,"",$4); print $2"\t"$3"\t"$4}')

bash "$(dirname "$0")/rebuild-index.sh"
echo "退避: ${moved}件 → $ARCHIVE/"
