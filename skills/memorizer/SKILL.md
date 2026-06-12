---
name: memorizer
description: >
  コンテキスト管理スキル。作業コンテキストをトピック別ファイルに保存・ロード・一覧表示する。
  `/memorizer new <topic>` で空トピック作成、`/memorizer save [topic]` で保存、
  `/memorizer load <topic...>` でロード、`/memorizer list` で一覧、`/memorizer compact` で類似トピック統合、
  `/memorizer archive [days]` で未参照トピックをアーカイブに退避。
---

# Memorizer: コンテキスト管理

## パス定義

- コンテキストルート: `./memory/contexts/`（カレントディレクトリ基準。auto memory の `~/.claude/projects/` 配下ではない）

## 最優先ルール

### ルール更新の扱い

- ユーザーからロード中のコンテキストに関するルール変更を指示された場合、そのコンテキストファイル（`memory/contexts/{topic}.md`）を更新する。
- 再発防止・手順・ルールは、毎回ロードされるサマリー（`{topic}.md`）に書く。
- `context-log.md` は経緯・背景の記録であり、明示的に読まない限りロードされない。重要ルールを `context-log.md` のみに置かない。

## 設計原則

**1トピック = 1つの具体的な問題・機能・目的**

トピックは最小単位で管理し、必要なものを組み合わせてロードする。
コードのモジュールと同じ考え方。

```text
✗ auth                     ← 広すぎ
✓ auth-jwt-refresh         ← リフレッシュトークン設計
✓ auth-provider-selection  ← プロバイダー比較・選定
✓ auth-session-storage     ← セッション保存方式
```

## データ構造

```text
./memory/contexts/
  index.md            — 全トピックの1行サマリー（list用インデックス）
  {topic}.md          — 現在の状態サマリー（上書き、常に小さく保つ）
  {topic}/
    context-log.md    — 経緯・背景・過去判断の記録（明示時のみ読む）
```

### index.md のフォーマット

```markdown
| topic | updated | summary |
|-------|---------|---------|
| {topic} | {date} | {現在の状態の1行目} |
```

### {topic}.md のフォーマット

```markdown
---
topic: {topic}
updated: {date}
depends_on:
  - {topic-a}
  - {topic-b}
---

## 現在の状態
（1〜3行）

## 有効なルール・制約
- ...

## 決定事項
- ...

## 次のアクション
- ...
```

`depends_on` は省略可。依存トピックのロード時にそのコンテキストも合わせて読み込まれる。

**サイズルール:** 各セクション最大5項目。完結した決定・古い経緯は `context-log.md` に移して、サマリーから削除する。ただし、現在も有効なルール・制約は `context-log.md` のみに移さない。

### context-log.md のフォーマット

```markdown
## {date} {タイトル}
{調査・決定の内容}
→ {結果・理由・影響}
```

## context-log に記録する基準

**記録する（プロジェクト内側にしか存在しない情報）:**
- このプロジェクト固有の制約（予算・チーム・既存インフラ）
- 選択肢を比較してXを除外した理由
- 試して失敗したこと・その原因
- ステークホルダーの意思決定とその背景
- プロジェクト内で発見した仕様・挙動の特殊性
- 再発防止に必要な「過去に起きた失敗」と原因

**記録しない（プロジェクト外側にある再検索可能な情報）:**
- 公開ドキュメントに書いてある情報（インストール方法・APIの使い方）
- 一般的なベストプラクティス
- Stack Overflow等で再現できるエラーの解決策

---

## `/memorizer`（引数なし）— 初期化

### Step 1 — index.md の確認

`memory/contexts/index.md` を Read する。

### Step 2 — 宣言

`index.md` が存在してトピックがある場合、一覧を表示する：

```text
利用可能なコンテキスト:
- {topic} ({updated}) {summary}
```

`index.md` が存在しない、またはトピックがない場合は「コンテキストなし」と表示する。

---

## `/memorizer new <topic>` — 空トピック作成

### Step 1 — 重複チェック

`memory/contexts/{topic}.md` が既に存在する場合は「コンテキスト `{topic}` は既に存在します」と報告して終了。

### Step 2 — ファイル作成

以下の内容で `memory/contexts/{topic}.md` を作成する：

```markdown
---
topic: {topic}
updated: {date}
---

## 現在の状態


## 有効なルール・制約


## 決定事項


## 次のアクション

```

### Step 3 — index.md 再生成

```bash
bash {BASE_DIR}/scripts/rebuild-index.sh
```

完了を報告する。

---

## `/memorizer save [topic]` — 保存

### Step 1 — トピック決定

`topic` が指定されていない場合、会話の内容からトピック名を推定する（英小文字・ハイフン区切り、例: `auth-refactor`）。
既存トピックへの追記か新規作成かを判断する。

### Step 2 — サマリー上書き

現在の作業内容を要約して `memory/contexts/{topic}.md` を上書きする。

- 現在も有効なルール・制約は `## 有効なルール・制約` に残す。
- 完結した決定・古い経緯は `context-log.md` に移す。
- サマリーは小さく保つが、再発防止に必要なルールを削らない。

### Step 3 — index.md 再生成

```bash
bash {BASE_DIR}/scripts/rebuild-index.sh
```

updated・summary は各 `{topic}.md` から機械的に導出される（summary は `現在の状態` の最初の非空行）。

### Step 4 — context-log 更新

`memory/contexts/{topic}/context-log.md` を以下のルールで更新する：

- 今回の会話で「記録する基準」に該当する内容があれば追記する
- 解決済み・無効になったエントリは削除する
- 現在も有効なルール・制約を context-log のみに移さない
- 該当する内容がなければスキップする

完了を報告する。

---

## `/memorizer load <topic...>` — ロード

複数トピックを同時にロードできる。

```text
/memorizer load ckeditor-html-embed ckeditor-license
```

### Step 1 — ファイル確認

指定された各トピックについて `memory/contexts/{topic}.md` が存在するか確認する。
存在しない場合は `memory/contexts/archive/` を確認し、あればユーザーに復元を確認のうえ `{topic}.md`（と `{topic}/`）を `memory/contexts/` 直下に戻してからロードする。
アーカイブにもなければ「コンテキスト `{topic}` が見つかりません」と報告してスキップ。

### Step 2 — 依存関係の解決

各トピックの `depends_on` を確認し、依存トピックを再帰的にロード対象に追加する。
循環依存が検出された場合は警告して該当ループをスキップする。
ロード順は依存先 → 依存元の順（依存トピックを先に読む）。

### Step 3 — ロードと表示

解決済みの全トピックの `{topic}.md` を Read し、参照記録を更新する：

```bash
bash {BASE_DIR}/scripts/touch-loaded.sh <topic...>
```

`{topic}/context-log.md` はこの時点では読まない（ユーザーが必要と判断したタイミングで読む）。

ただし、フロントマターに `merged_from` がある場合は、列挙された旧トピックの `{old-topic}/context-log.md` も context-log として扱う（ユーザーが context-log を要求したタイミングで読む）。

全トピックの内容をまとめて3〜5行で要約して表示する。ロードしたトピック一覧も表示する。

---

## `/memorizer list` — 一覧表示

`memory/contexts/index.md` を Read して以下の形式で表示する：

```text
{topic} ({updated}) {summary}
```

`index.md` が存在しない場合は「インデックスがありません。`/memorizer save` で作成してください。」と表示する。

---

## `/memorizer archive [days]` — 未参照トピックの退避

`last_loaded`（なければ `updated`、なければファイル更新日時）が `days` 日（デフォルト30）より古いトピックを `archive/` に退避し、index.md を再生成する。

```bash
bash {BASE_DIR}/scripts/archive.sh [days]
```

退避結果（件数・トピック名）を報告する。退避されたトピックは `/memorizer load` で復元できる。

---

## `/memorizer compact` — 類似トピック統合

### Step 1 — 全トピックのロード

`memory/contexts/index.md` を Read し、全トピックの `{topic}.md` を Read する。

### Step 2 — 類似検出

内容・テーマが重複または類似しているトピック群を特定し、マージグループを決定する。

### Step 3 — 統合実行

各グループについて以下を行う：

1. 旧トピックの `{topic}.md` の内容を統合して新 `{merged-topic}.md` を作成。フロントマターに `merged_from` を記録する：
   ```yaml
   merged_from:
     - {topic-a}
     - {topic-b}
   ```
2. 旧トピックのファイル・ディレクトリは削除せず残す（context-logの参照先として保持）。旧 `{topic}.md` のフロントマターに `merged_into: {merged-topic}` を追記する（index再生成時の除外マーカー）
3. `index.md` を再生成する：`bash {BASE_DIR}/scripts/rebuild-index.sh`

### Step 4 — 報告

統合したグループ数と新トピック名の一覧を表示する。