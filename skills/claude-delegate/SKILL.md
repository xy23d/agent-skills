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

委譲コマンドを実行する前に、スキル直下の `.delegate-context` を確認する。設定が存在する場合は次を行う。

1. `scripts/gen-delegate-index.sh` を実行し、各資料ディレクトリ直下の `index.md`（ファイル名＋1行要約）を最新化する。
2. 各ディレクトリの `index.md` を読み、**要約だけ**を見て現在のタスクに適用すべき資料を選定する。資料本体（各 `.md`）は読まない。全件を無条件に選ばない。
3. 選定したファイルの絶対パスを1行1件で `/tmp/claude-inputs/<task>-context.txt` に書く（候補の絶対パス一覧は `scripts/list-delegate-context.sh` で確認できる）。
4. 実行スクリプトの第4引数にそのファイルを渡す。委譲先には選定済み資料だけが明示される。

候補がない、または適用対象がない場合は選定ファイルを作らず、従来どおり第3引数までで実行する。`.delegate-context` の空行、行頭が `#` のコメント、不存在ディレクトリは候補から除外される。相対パスはスキルディレクトリ基準で解決される。資料の追加・更新後は手順1で index を再生成して鮮度を保つ。この仕組みはコンテキスト資料の選定であり、`depends_on` の依存関係解決には使用しない。

```bash
bash {BASE_DIR}/scripts/gen-delegate-index.sh
```

スクリプトは `scripts/claude-exec.sh` に同梱済み。スキル起動時に示されるベースディレクトリ（"Base directory for this skill: ..."）を使って実行する。

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
