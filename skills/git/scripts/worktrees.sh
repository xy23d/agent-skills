#!/usr/bin/env bash
# Usage: worktrees.sh [dir]
# Shows branch, ahead/behind, untracked count for all git subdirs in dir.

DIR="${1:-.}"

for d in "$DIR"/*/; do
  [ -e "$d/.git" ] || continue
  branch=$(git -C "$d" branch --show-current 2>/dev/null)
  [ -z "$branch" ] && continue

  ahead=$(git -C "$d" log --oneline "origin/$branch..HEAD" 2>/dev/null | wc -l | tr -d ' ')
  behind=$(git -C "$d" log --oneline "HEAD..origin/$branch" 2>/dev/null | wc -l | tr -d ' ')
  untracked=$(git -C "$d" status --short 2>/dev/null | grep -c '^??' || true)

  name=$(basename "$d")
  if [ "$ahead" = "0" ] && [ "$behind" = "0" ] && [ "$untracked" = "0" ]; then
    echo "✓  $name  ($branch)"
  else
    echo "   $name  ($branch)  ahead:$ahead behind:$behind untracked:$untracked"
  fi
done
