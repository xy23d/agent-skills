#!/bin/bash
# Usage: codex-exec.sh <worktree> <task_file> [inputs_dir]
set -e

WORKTREE="$1"
TASK="$2"
INPUTS_DIR="$3"

if [ -z "$WORKTREE" ] || [ -z "$TASK" ]; then
  echo "Usage: codex-exec.sh <worktree> <task_file> [inputs_dir]"
  exit 1
fi

ADD_DIR_ARG=""
if [ -n "$INPUTS_DIR" ]; then
  ADD_DIR_ARG="--add-dir $INPUTS_DIR"
fi

codex exec -C "$WORKTREE" \
  $ADD_DIR_ARG \
  --dangerously-bypass-approvals-and-sandbox \
  "${TASK} を読んで対応してください。"
