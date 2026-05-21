#!/usr/bin/env bash
# Usage: find-commit.sh <hash-prefix> [dir]
# Searches for a commit (prefix match) across all git subdirs in dir.

HASH="$1"
DIR="${2:-.}"

if [ -z "$HASH" ]; then
  echo "Usage: find-commit.sh <hash-prefix> [dir]" >&2
  exit 1
fi

for d in "$DIR"/*/; do
  [ -e "$d/.git" ] || continue
  name=$(basename "$d")
  result=$(git -C "$d" log --oneline 2>/dev/null | grep "^$HASH" | head -1)
  if [ -n "$result" ]; then
    echo "FOUND  $name: $result"
  else
    echo "none   $name"
  fi
done
