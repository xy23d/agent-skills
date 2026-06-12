---
name: gh
description: >
  GitHub PRの未解決レビューコメントを一覧表示するスキル（read-only、resolve等の操作はしない）。
  `/gh pr <number>` でresolve済みを除いたopenなレビューコメントを一覧表示する。
  PRレビュー対応時に「未解決コメントだけ確認したい」場面で使うこと。
---

# gh: PR レビューコメント操作

## `/gh pr <number>`

指定したPR番号のresolve済みを除いたレビューコメントを一覧表示する。

スクリプトは `scripts/pr-comments.sh` に同梱済み。スキル起動時に示されるベースディレクトリ（"Base directory for this skill: ..."）を使って実行する。

```bash
bash {BASE_DIR}/scripts/pr-comments.sh <number>
```

### 出力フォーマット

```
[1] path/to/file.ts (line 42)
@author: コメント本文
---
[2] ...
```

resolve済みスレッドは表示しない。スレッドが0件の場合は「未解決コメントなし」と表示する。

`gh repo view` が失敗する場合（リモートなし等）はユーザーに手動入力を求める。
