#!/bin/bash
# Usage: claude-exec.sh <worktree> <task_file> [inputs_dir]
# ファンネル（実装委譲）の実行エンジン（claude 版）。codex-exec.sh の claude 置き換え。
#
# 重要:
#   - --agent を付けず「素の claude -p」で起動する。通常作業用の Edit/Write ガードは
#     .claude/agents/main.md の frontmatter にあり、エージェント指定なしなら発火しない。
#     これによりファンネルは worktree のコードを直接編集できる。
#   - cd はしない。作業対象 worktree は --add-dir で渡し、プロンプトで作業ルートを明示する。
#     cwd は呼び出し元（プロジェクトルート）のままなので、git 操作が cwd 側リポジトリに
#     当たらないよう、プロンプトで `git -C <worktree>` を強制する。
set -e

WORKTREE="$1"
TASK="$2"
INPUTS_DIR="$3"

if [ -z "$WORKTREE" ] || [ -z "$TASK" ]; then
  echo "Usage: claude-exec.sh <worktree> <task_file> [inputs_dir]"
  exit 1
fi

TASK_PATH="$TASK"
if [ -n "$INPUTS_DIR" ]; then
  TASK_PATH="$INPUTS_DIR/$TASK"
fi

claude -p "作業対象のリポジトリは ${WORKTREE} です。${TASK_PATH} を読み、${WORKTREE} 内のファイルに対して対応してください。git 操作はすべて 'git -C ${WORKTREE} ...' で行い、それ以外のリポジトリやディレクトリには触れないこと。" \
  --add-dir "$WORKTREE" \
  ${INPUTS_DIR:+--add-dir "$INPUTS_DIR"} \
  --dangerously-skip-permissions
