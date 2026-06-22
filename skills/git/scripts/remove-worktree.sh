#!/usr/bin/env bash
# worktree を削除する。失敗したらユーザーに報告して中断する。
set -uo pipefail

target="${1:-}"
[ -z "$target" ] && { echo "usage: remove-worktree.sh <branch|path>" >&2; exit 1; }

# パス解決: 既存ディレクトリならそのまま、そうでなければブランチ名として worktree list から解決
if [ -d "$target" ]; then
  wt_path=$(cd "$target" && pwd)
else
  wt_path=$(git worktree list --porcelain | awk -v b="branch refs/heads/$target" '
    /^worktree /{p=$2} $0==b{print p; exit}')
  [ -z "$wt_path" ] && { echo "worktree not found for branch/path: $target" >&2; exit 1; }
fi

# メインリポジトリ解決（worktree list の先頭がメイン）
main_repo=$(git -C "$wt_path" worktree list --porcelain | awk '/^worktree /{print $2; exit}')

# 未コミット変更チェック
if [ -n "$(git -C "$wt_path" status --short 2>/dev/null)" ]; then
  echo "BLOCKED: 未コミット変更があります。中断しました: $wt_path" >&2
  exit 2
fi

# 削除
if git -C "$main_repo" worktree remove "$wt_path"; then
  echo "removed: $wt_path"
  echo "ブランチとコミットは保持されます（push 未済でもローカルブランチに残る）。"
  exit 0
fi

# 失敗時はユーザーに報告して中断
echo "FAILED: worktree remove に失敗しました: $wt_path" >&2
exit 1
