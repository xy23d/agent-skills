#!/bin/bash
# Usage: list-delegate-context.sh
# このスクリプトが属するスキル直下の .delegate-context に列挙された
# ディレクトリ配下の Markdown を候補として出力する。
set -euo pipefail

SKILL_ROOT="$(dirname "$(dirname "$(readlink -f "$0")")")"
CONTEXT_FILE="$SKILL_ROOT/.delegate-context"

if [ ! -f "$CONTEXT_FILE" ]; then
  exit 0
fi

while IFS= read -r line || [ -n "$line" ]; do
  path="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  if [ -z "$path" ] || [[ "$path" == \#* ]]; then
    continue
  fi

  if [[ "$path" != /* ]]; then
    path="$SKILL_ROOT/$path"
  fi

  if [ ! -d "$path" ]; then
    printf 'warning: delegate context directory not found: %s\n' "$path" >&2
    continue
  fi

  resolved_path="$(readlink -f "$path")"
  find "$resolved_path" -type f \( -iname '*.md' -o -iname '*.markdown' \) ! -name 'index.md' -print
done < "$CONTEXT_FILE" | LC_ALL=C sort -u
