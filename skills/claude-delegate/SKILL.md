---
name: claude-delegate
description: claudeにコード実装を委譲するスキル。`/claude-delegate worktree_path` の形式で呼ぶ。実装タスクが生じたとき、実装方法を自分で考え始めたらこのスキルを使うサイン。
---

# claude-delegate

実装内容の詳細（コード・ファイル構造）は考えない。**何をすべきか**だけを伝え、実装は委譲先の claude に任せる。

## 使い方

```
/claude-delegate <worktree_path>
```

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

委譲先に追加の参照資料を渡したい場合は、スキル直下の `.delegate-context` に指定されたカタログを基に、現在のタスクに関連する資料を選定する（全件を無条件には選ばない）。選定したファイルの絶対パスを1行1件で `/tmp/claude-inputs/<task>-context.txt` に書き、実行スクリプトの第4引数に渡す。委譲先には選定済み資料だけが明示される。

カタログの形式やパスの解決方法は資料側の取り決めに従う（このスキルは関与しない）。候補がない、または適用対象がない場合は選定ファイルを作らず、従来どおり第3引数までで実行する。

実行スクリプト（`scripts/claude-exec.sh`）は、スキル起動時に示されるベースディレクトリ（"Base directory for this skill: ..."）を使って実行する。

指示ファイルは使い捨てのため、スキルディレクトリ内ではなく `/tmp/claude-inputs/` に作成する。

```bash
mkdir -p /tmp/claude-inputs
bash {BASE_DIR}/scripts/claude-exec.sh <worktree_path> <task>.md /tmp/claude-inputs

# 追加資料を選定した場合
bash {BASE_DIR}/scripts/claude-exec.sh <worktree_path> <task>.md /tmp/claude-inputs /tmp/claude-inputs/<task>-context.txt
```

バックグラウンドで複数worktreeを並列実行する場合は `run_in_background: true` で Bash を呼ぶ。

## 指示ファイルのテンプレート

`inputs/_template.md`（スキル同梱）を参照し、`/tmp/claude-inputs/<task>.md` にコピーして使う。


## 失敗時の扱い

- `claude -p` が非0終了した場合・ハングした場合は、独自のワークアラウンドを探さず、ログと状況をユーザーに報告して判断を仰ぐ。
- 同じ指示での自動リトライはしない（指示を変えずに再実行しても結果は変わらない）。

## 例

```bash
bash {BASE_DIR}/scripts/claude-exec.sh /path/to/worktree <task>.md /tmp/claude-inputs
```
