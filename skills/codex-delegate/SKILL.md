---
name: codex-delegate
description: Codexにコード実装を委譲するスキル。`/codex-delegate worktree_path` の形式で呼ぶ。実装タスクが生じたときにCodexへ渡すために使う。実装方法を自分で考え始めたらこのスキルを使うサイン。
---

# codex-delegate

実装内容の詳細（コード・ファイル構造）は考えない。**何をすべきか**だけをCodexに伝え、実装はCodexに任せる。

## 使い方

```
/codex-delegate <worktree_path>
```

## Codexに渡すべき情報

- **何を実装するか**（エンドポイント名・機能の概要）
- **参照すべき既存コード**（似た実装があればそのパスと何を参考にするか）

## Codexに渡してはいけない情報

- 具体的なコード（Codexが書く）
- ファイルパスの列挙（Codexが判断する）
- 実装の手順（Codexが考える）

## 実行コマンド

複雑な指示をプロンプト直書きするとstdin読み込みでハングするため、指示ファイルに書いてから渡す。

### 追加資料の選定

委譲先に追加の参照資料を渡したい場合は、`amuro` スキルを使って現在のタスクに関連するガイドライン（実装/テスト設計指針など）を選定する（全件を無条件には選ばない）。amuro が自分の doc 位置を解決するので、参照先パスをこのスキル側にハードコードしない。選定したファイルの絶対パスを1行1件で `/tmp/codex-inputs/<task>-context.txt` に書き、実行スクリプトの第4引数に渡す。委譲先には選定済み資料だけが明示される。

コード実装でない委譲や、関連する資料が無い場合（設定ファイルの機械的変更・非Railsのスキーマ編集など）は選定ファイルを作らず、従来どおり第3引数までで実行する。

実行スクリプト（`scripts/codex-exec.sh`）は、スキル起動時に示されるベースディレクトリ（"Base directory for this skill: ..."）を使って実行する。

指示ファイルは使い捨てのため、スキルディレクトリ内ではなく `/tmp/codex-inputs/` に作成する。

```bash
mkdir -p /tmp/codex-inputs
bash {BASE_DIR}/scripts/codex-exec.sh <worktree_path> <task>.md /tmp/codex-inputs

# 追加資料を選定した場合
bash {BASE_DIR}/scripts/codex-exec.sh <worktree_path> <task>.md /tmp/codex-inputs /tmp/codex-inputs/<task>-context.txt
```

バックグラウンドで複数worktreeを並列実行する場合は `run_in_background: true` で Bash を呼ぶ。

## 指示ファイルのテンプレート

`inputs/_template.md`（スキル同梱）を参照し、`/tmp/codex-inputs/<task>.md` にコピーして使う。

## 失敗時の扱い

- `codex exec` が非0終了した場合・ハングした場合は、独自のワークアラウンドを探さず、ログと状況をユーザーに報告して判断を仰ぐ。
- 同じ指示での自動リトライはしない（指示を変えずに再実行しても結果は変わらない）。

## 例

```bash
bash {BASE_DIR}/scripts/codex-exec.sh /path/to/worktree <task>.md /tmp/codex-inputs
```
