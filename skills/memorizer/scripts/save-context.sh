#!/bin/bash
# Usage: save-context.sh <topic> <body_file>
# body_file の内容を ./memory/contexts/<topic>.md に保存し index を再生成する。
set -euo pipefail

DIR="./memory/contexts"
topic="${1:?Usage: save-context.sh <topic> <body_file>}"
body="${2:?Usage: save-context.sh <topic> <body_file>}"
[ -f "$body" ] || { echo "本文ファイルがありません: $body" >&2; exit 1; }

mkdir -p "$DIR"
cp "$body" "$DIR/$topic.md"

bash "$(dirname "$0")/rebuild-index.sh"
echo "保存: $DIR/$topic.md"
