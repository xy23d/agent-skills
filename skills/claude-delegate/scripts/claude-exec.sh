#!/bin/bash
# Usage: claude-exec.sh <worktree> <task_file> [inputs_dir] [selected_context_file]
# ファンネル（実装委譲）の実行エンジン（claude 版）。codex-exec.sh の claude 置き換え。
#
# 重要:
#   - --agent を付けず「素の claude -p」で起動する。通常作業用の Edit/Write ガードは
#     .claude/agents/main.md の frontmatter にあり、エージェント指定なしなら発火しない。
#     これによりファンネルは worktree のコードを直接編集できる。
#   - cd はしない。作業対象 worktree は --add-dir で渡し、プロンプトで作業ルートを明示する。
#     cwd は呼び出し元（プロジェクトルート）のままなので、git 操作が cwd 側リポジトリに
#     当たらないよう、プロンプトで `git -C <worktree>` を強制する。
set -euo pipefail

WORKTREE="${1:-}"
TASK="${2:-}"
INPUTS_DIR="${3:-}"
SELECTED_CONTEXT_FILE="${4:-}"

if [ -z "$WORKTREE" ] || [ -z "$TASK" ]; then
  echo "Usage: claude-exec.sh <worktree> <task_file> [inputs_dir] [selected_context_file]"
  exit 1
fi

TASK_PATH="$TASK"
if [ -n "$INPUTS_DIR" ]; then
  TASK_PATH="$INPUTS_DIR/$TASK"
fi

ADD_DIR_ARGS=(--add-dir "$WORKTREE")
if [ -n "$INPUTS_DIR" ]; then
  ADD_DIR_ARGS+=(--add-dir "$INPUTS_DIR")
fi

CONTEXT_PROMPT=""
if [ -n "$SELECTED_CONTEXT_FILE" ] && [ -f "$SELECTED_CONTEXT_FILE" ]; then
  while IFS= read -r context_path || [ -n "$context_path" ]; do
    context_path="$(printf '%s' "$context_path" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')"
    if [ -z "$context_path" ] || [[ "$context_path" == \#* ]]; then
      continue
    fi
    if [ ! -f "$context_path" ] || [[ "${context_path,,}" != *.md && "${context_path,,}" != *.markdown ]]; then
      printf 'warning: selected delegate context is not a Markdown file: %s\n' "$context_path" >&2
      continue
    fi
    context_path="$(readlink -f "$context_path")"
    CONTEXT_PROMPT+=$'\n- '"$context_path"
    ADD_DIR_ARGS+=(--add-dir "$(dirname "$context_path")")
  done < "$SELECTED_CONTEXT_FILE"
fi

if [ -n "$CONTEXT_PROMPT" ]; then
  CONTEXT_PROMPT=$'\n現在のタスクに適用する追加資料は次のとおりです。これらだけを読んでルールを適用し、最終報告に「適用した追加資料」としてファイルパスを明記してください。'"$CONTEXT_PROMPT"
fi

claude -p "作業対象のリポジトリは ${WORKTREE} です。${TASK_PATH} を読み、${WORKTREE} 内のファイルに対して対応してください。git 操作はすべて 'git -C ${WORKTREE} ...' で行い、それ以外のリポジトリやディレクトリには触れないこと。${CONTEXT_PROMPT}" \
  "${ADD_DIR_ARGS[@]}" \
  --dangerously-skip-permissions
