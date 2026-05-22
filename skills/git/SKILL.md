---
name: git
description: >
  複数のgit worktreeを一括操作するスキル。worktreeの状態確認や特定コミットの検索で複数回コマンドを叩いているときに使う。
  `/git worktrees [dir]` で全worktreeのブランチ・ahead/behind・未追跡ファイルを一括表示。
  `/git find <hash> [dir]` で特定コミットが各worktreeに含まれるか検索。
  `/git rebase <parent> [child]` でrebase（コンフリクト時のルールあり）。
  以下のときに必ず使うこと：
  「worktreeの状態を確認したい」「各ブランチのリモートとの差分を見たい」→ `/git worktrees`
  「このコミットがどのブランチに入っているか調べたい」→ `/git find`
  「rebaseして」→ `/git rebase`
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
2. コンフリクト発生時は **HEAD（親ブランチ）を優先** する
   - 既存ファイルの変更が競合した場合 → HEADの内容を採用
   - 子ブランチ固有の追加（新規ファイル、親に存在しないメソッド）のみ incoming から取り込む
   - 判断基準：「この変更は親ブランチにすでにあるか？」→ あればHEAD、なければ取り込む
3. `git add <file> && git rebase --continue` で続行

### worktreeの場所

ブランチ名からworktreeパスを解決する：`rails-worktrees/<branch-name>/`
