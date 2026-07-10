---
name: gh
description: >
  GitHub PRの未解決レビューコメント一覧表示とDraft PR作成を行うスキル。
  レビューコメント一覧はread-onlyで、resolve等の操作はしない。
  `/gh pr <number>` でresolve済みを除いたopenなレビューコメントを一覧表示する。
  `/gh pr <pr_url>` または `/gh pr <number> <owner/repo>` でカレント外リポジトリも指定できる。
  PRを作成するときは `gh pr create` を直接叩かず `/gh create` を使う。PRはDraftで作成される。
  PRレビュー対応時に「未解決コメントだけ確認したい」場面で使うこと。
---

# gh: PR レビューコメント操作

## `/gh pr <number>`

指定したPR番号のresolve済みを除いたレビューコメントを一覧表示する。

スクリプトは `scripts/pr-comments.sh` に同梱済み。スキル起動時に示されるベースディレクトリ（"Base directory for this skill: ..."）を使って実行する。

```bash
bash {BASE_DIR}/scripts/pr-comments.sh <number|pr_url> [owner/repo]
```

カレントリポジトリ以外のPRは、PR URL を渡すか第2引数に `owner/repo` を指定する。どちらも無ければカレントリポジトリにフォールバックする。

### 出力フォーマット

```
[1] path/to/file.ts (line 42)
@author: コメント本文
---
[2] ...
```

resolve済みスレッドは表示しない。スレッドが0件の場合は「未解決コメントなし」と表示する。

`gh repo view` が失敗する場合（リモートなし等）はユーザーに手動入力を求める。

## `/gh create <worktree_path>`

指定したworktreeのカレントブランチからDraft PRを作成する。

スクリプトは `scripts/pr-create.sh` に同梱済み。スキル起動時に示されるベースディレクトリ（"Base directory for this skill: ..."）を使って実行する。

```bash
bash {BASE_DIR}/scripts/pr-create.sh <worktree_path> <title> <body_file> [base]
```

`title` は引数で渡す。`body` はLLMが一時ファイルに書き出し、そのファイルパスを `body_file` として渡す。

このサブコマンドは常にDraft PRを作成する。ready PRは作成しない。

`base` は任意。省略時は `gh pr create` の既定に従い、baseリポジトリのデフォルトブランチが使われる。

push 前に同じ head ブランチの merged 済み PR があるか確認し、見つかった場合は push も PR 作成も行わずエラーで停止する。エラーには検知した PR 番号と「このブランチは既に merged 済み。新しいブランチを切って、そのブランチで同じコマンドを再実行する」という次アクションが表示される。新しい変更を出す場合は、現在の作業内容を新ブランチへ移してから同じ `/gh create` コマンドを再実行する。merged PR 確認のための `gh` 照会自体が失敗した場合は、確認不能だけを理由には停止せず、従来どおり push と Draft PR 作成へ進む。

複数のGitHubアカウントで `gh auth` している環境では、`owner-account-map` に `owner account` 形式で対応を書くと、origin の owner に応じて PR 作成時だけ指定アカウントへ切り替える。例: `my-org my-github-login`。`#` で始まる行はコメント。未指定の owner は切り替えず、現在の `gh auth` 状態のまま実行する。実ファイルはマシン固有情報としてGit追跡外で、復元用テンプレートは `owner-account-map.template`。
