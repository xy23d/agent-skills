---
name: delegate
description: >
  ファンネル（委譲先バックエンド）にコード実装を委譲するスキル。`/delegate worktree_path` の形式で呼ぶ。
  実装タスクが生じたとき、実装方法を自分で考え始めたらこのスキルを使うサイン。
  デフォルトの委譲先はCodex。rate-limit等で使えないときはclaudeバックエンドに切り替える。
---

# delegate

実装内容の詳細（コード・ファイル構造）は考えない。**何をすべきか**だけを伝え、実装は委譲先に任せる。

## 使い方

```
/delegate <worktree_path>
```

## バックエンド

実行スクリプトはバックエンドごとに分かれており、引数インターフェースは共通（`<worktree> <task_file> [inputs_dir] [selected_context_file]`）。切り替えは実行するスクリプトの差し替えだけで行う。

- デフォルト: `scripts/codex-exec.sh`（Codex）
- 切替先: `scripts/claude-exec.sh`（claude -p）

rate-limit 等でデフォルトが使えない場合、自動でフォールバックせず、切替先での実行をユーザーに提案して承認を得てから実行する。

## 渡すべき情報

- **何を実装するか**（エンドポイント名・機能の概要）
- **参照すべき既存コード**（似た実装があればそのパスと何を参考にするか）

## 渡してはいけない情報

- 具体的なコード（委譲先が書く）
- ファイルパスの列挙（委譲先が判断する）
- 実装の手順（委譲先が考える）

## 実行コマンド

複雑な指示をプロンプト直書きするとstdin読み込みでハングするため、指示ファイルに書いてから渡す。

### 追加資料の選定

委譲先に追加の参照資料を渡したい場合は、`amuro` スキルを使って現在のタスクに関連するガイドライン（実装/テスト設計指針など）を選定する（全件を無条件には選ばない）。amuro が自分の doc 位置を解決するので、参照先パスをこのスキル側にハードコードしない。選定したファイルの絶対パスを1行1件で `/tmp/delegate-inputs/<task>-context.txt` に書き、実行スクリプトの第4引数に渡す。委譲先には選定済み資料だけが明示される。

コード実装でない委譲や、関連する資料が無い場合（設定ファイルの機械的変更・非Railsのスキーマ編集など）は選定ファイルを作らず、従来どおり第3引数までで実行する。

実行スクリプトは、スキル起動時に示されるベースディレクトリ（"Base directory for this skill: ..."）を使って実行する。

指示ファイルは使い捨てのため、スキルディレクトリ内ではなく `/tmp/delegate-inputs/` に作成する。

```bash
mkdir -p /tmp/delegate-inputs
bash {BASE_DIR}/scripts/codex-exec.sh <worktree_path> <task>.md /tmp/delegate-inputs

# 追加資料を選定した場合
bash {BASE_DIR}/scripts/codex-exec.sh <worktree_path> <task>.md /tmp/delegate-inputs /tmp/delegate-inputs/<task>-context.txt
```

バックグラウンドで複数worktreeを並列実行する場合は `run_in_background: true` で Bash を呼ぶ。

## 指示ファイルのテンプレート

`inputs/_template.md`（スキル同梱）を参照し、`/tmp/delegate-inputs/<task>.md` にコピーして使う。

## 失敗時の扱い

- 委譲先コマンド（`codex exec` / `claude -p`）が非0終了した場合・ハングした場合は、独自のワークアラウンドを探さず、ログと状況をユーザーに報告して判断を仰ぐ。
- 同じ指示での自動リトライはしない（指示を変えずに再実行しても結果は変わらない）。

## 例

```bash
bash {BASE_DIR}/scripts/codex-exec.sh /path/to/worktree <task>.md /tmp/delegate-inputs
```
