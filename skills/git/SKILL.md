---
name: git
description: >
  複数のgit worktreeを一括操作するスキル。worktreeの状態確認や特定コミットの検索で複数回コマンドを叩いているときに使う。
  `/git worktrees [dir]` で全worktreeのブランチ・ahead/behind・未追跡ファイルを一括表示。
  `/git find <hash> [dir]` で特定コミットが各worktreeに含まれるか検索。
  `/git rebase <parent> [child]` でrebase（コンフリクト時のルールあり）。
  `/git remove-worktree <branch|path>` でworktreeを削除（失敗時は自己判断で突破せずユーザー報告）。
  以下のときに必ず使うこと：
  「worktreeの状態を確認したい」「各ブランチのリモートとの差分を見たい」→ `/git worktrees`
  「このコミットがどのブランチに入っているか調べたい」→ `/git find`
  「rebaseして」→ `/git rebase`
  「worktreeを削除して」→ `/git remove-worktree`
---

# git: worktree一括操作

スクリプトは `scripts/` に同梱済み。スキル起動時に示されるベースディレクトリ（"Base directory for this skill: ..."）を使って実行する。

## `/git worktrees [dir]`

```bash
bash <base_dir>/scripts/worktrees.sh [dir]
```

- `dir` 省略時はカレントディレクトリ
- clean（ahead:0 behind:0 untracked:0）は `✓` で表示、それ以外は詳細を表示

## `/git find <hash> [dir]`

```bash
bash <base_dir>/scripts/find-commit.sh <hash> [dir]
```

- `hash` は前方一致（短縮形OK）
- `dir` 省略時はカレントディレクトリ
- 結果は `FOUND` / `none` で各worktreeごとに表示

## `/git rebase <parent> [child]`

`child` を `parent` にrebaseする。`child` 省略時はカレントブランチ。

### 手順

1. 子ブランチのworktreeで `git rebase <parent>` を実行
2. コンフリクト発生時は `git rebase --abort` して**ユーザーに報告して終了**する
   - コンフリクトしたファイル一覧と概要を報告する
   - 自己判断での解決をしない

### worktreeの場所

ブランチ名からworktreeパスを解決する：

```bash
git worktree list --porcelain | grep -B2 "branch refs/heads/<branch-name>" | head -1
```

## `/git remove-worktree <branch|path>`

```bash
bash <base_dir>/scripts/remove-worktree.sh <branch|path>
```

- `branch` 指定時は worktree パスを自動解決
- 失敗したらユーザーに報告し、作業を中断する
