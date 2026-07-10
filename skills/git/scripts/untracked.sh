#!/usr/bin/env bash
# Usage: untracked.sh [dir]
# Lists git-untracked files and directories, including ignored entries.
set -uo pipefail

DIR="${1:-.}"

if [ ! -d "$DIR" ]; then
  echo "directory not found: $DIR" >&2
  exit 1
fi

if ! git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "not a git repository: $DIR" >&2
  exit 1
fi

git -C "$DIR" ls-files --others --ignored --exclude-standard --directory
