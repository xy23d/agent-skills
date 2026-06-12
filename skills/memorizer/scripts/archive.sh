#!/bin/bash
# Usage: archive.sh [days] [contexts_dir]
# last_loaded（なければ updated、なければ mtime）が days 日より古いトピックを
# archive/ に退避し、index.md を再生成する
set -euo pipefail

DAYS="${1:-30}"
DIR="${2:-./memory/contexts}"
if [ ! -d "$DIR" ]; then
  echo "コンテキストディレクトリがありません: $DIR" >&2
  exit 1
fi

CUTOFF=$(date -d "-$DAYS days" +%s)
ARCHIVE="$DIR/archive"
mkdir -p "$ARCHIVE"
moved=0

for f in "$DIR"/*.md; do
  base=$(basename "$f")
  [ "$base" = "index.md" ] && continue
  ref=$(awk -F': *' '/^last_loaded:/{print $2; exit}' "$f")
  [ -z "$ref" ] && ref=$(awk -F': *' '/^updated:/{print $2; exit}' "$f")
  if [ -n "$ref" ]; then
    ts=$(date -d "$ref" +%s 2>/dev/null) || ts=$(stat -c %Y "$f")
  else
    ts=$(stat -c %Y "$f")
  fi
  if [ "$ts" -lt "$CUTOFF" ]; then
    topic="${base%.md}"
    mv "$f" "$ARCHIVE/"
    [ -d "$DIR/$topic" ] && mv "$DIR/$topic" "$ARCHIVE/"
    echo "archived: $topic"
    moved=$((moved+1))
  fi
done

bash "$(dirname "$0")/rebuild-index.sh" "$DIR"
echo "退避: ${moved}件 → $ARCHIVE/"
