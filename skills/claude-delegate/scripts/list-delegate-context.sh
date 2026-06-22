#!/bin/bash
# Usage: list-delegate-context.sh [project_path]
# .delegate-context に列挙されたディレクトリ配下の Markdown を候補として出力する。
set -euo pipefail

PROJECT_PATH="${1:-$PWD}"
PROJECT_ROOT="$(git -C "$PROJECT_PATH" rev-parse --show-toplevel 2>/dev/null || true)"

if [ -z "$PROJECT_ROOT" ] || [ ! -f "$PROJECT_ROOT/.delegate-context" ]; then
  exit 0
fi

while IFS= read -r line || [ -n "$line" ]; do
  path="$(printf '%s' "$line" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
  if [ -z "$path" ] || [[ "$path" == \#* ]]; then
    continue
  fi

  if [[ "$path" != /* ]]; then
    path="$PROJECT_ROOT/$path"
  fi

  if [ ! -d "$path" ]; then
    printf 'warning: delegate context directory not found: %s\n' "$path" >&2
    continue
  fi

  resolved_path="$(readlink -f "$path")"
  find "$resolved_path" -type f \( -iname '*.md' -o -iname '*.markdown' \) -print
done < "$PROJECT_ROOT/.delegate-context" | LC_ALL=C sort -u
