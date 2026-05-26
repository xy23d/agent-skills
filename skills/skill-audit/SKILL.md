---
name: skill-audit
description: context/log系Markdownをスキャンして、スキル化・CLI化・context化・eval化候補を検出し、日次cronで通知する。
---

# skill-audit

## 概要

`targets.md` に記載された対象ディレクトリ配下の Markdown ファイルをスキャンし、ユーザーの反復行動・反復判断・反復参照コンテキストを検出する。

検出したパターンを以下に分類し、必要に応じてユーザーへ通知する。

- スキル候補
- CLI候補
- eval / check候補
- cron候補
- AGENTS.md / CLAUDE.md 追記候補

目的は「スキルを量産すること」ではなく、ユーザーの行動を観測し、再利用価値のあるものだけを適切な形式に昇格させること。

原則として、このスキルは **候補検出と通知まで** を行う。  
本番の skill / CLI / context / cron を自動作成してはいけない。  
作成する場合も draft までに留め、promotion はユーザー承認後に行う。

---

## 基本方針

分類ルール：

```text
同じ操作手順が繰り返される       → CLI候補
同じ判断基準が繰り返される       → スキル候補
同じミスや漏れが繰り返される     → eval / check候補
同じ周期で確認する必要がある     → cron候補
repo固有の権限・停止条件がある   → AGENTS.md / CLAUDE.md候補
```

優先順位：

1. ユーザーの説明量を減らすもの
2. 手作業・AI作業のミスを減らすもの
3. 判断基準を安定させるもの
4. コンテキスト再注入の精度を上げるもの
5. 周期作業を自動化できるもの

---

## 実行手順

### Step 1 — targets.md を読む

`SKILL.md` と同じディレクトリの `targets.md` を読む。

存在しない場合は、以下を表示して終了する。

```text
targets.md が見つかりません。targets.md.template をコピーして設定してください。
```

補足：

- `include` はデフォルトで `**/*.md` とする。
- `exclude` は必ず適用する。
- ファイル数・サイズ上限を超える場合は、更新日時が新しいものを優先する。
- 読み込み対象は Markdown 全般でよいが、READMEや仕様書のような静的ドキュメントは原則ノイズとして扱う。

---

### Step 2 — Markdownファイルを収集する

`contexts:` に指定された各ディレクトリ配下から、`include` に一致し、`exclude` に一致しない Markdown ファイルを収集する。

対象ファイル例：

- `context-log.md`
- `daily.md`
- `worklog.md`
- `session.md`
- `notes.md`
- `journal.md`
- `meeting.md`
- `*.md`

ただし、以下は原則として除外または低優先度にする。

- README
- CHANGELOG
- LICENSE
- package manager lock相当
- generated docs
- build成果物
- vendor / dependency配下
- 変更履歴が古いファイル
- 256KBを超える長大ファイル

---

### Step 3 — 過去N日分の関連エントリを抽出する

`lookback_days` の範囲で、関連する記述を抽出する。

日付が明示されている場合：

- Markdown見出しの日付
- frontmatterの日付
- 箇条書き内の日付
- ファイル名の日付
- git/file更新日時

を参考にする。

日付が明示されていない場合：

- ファイル更新日時を補助情報として扱う
- ただし、確度は低めに評価する

抽出対象のシグナル：

```text
- 同じ作業を複数回している
- 同じコマンド列・手順が出てくる
- 同じ判断基準やレビュー観点が出てくる
- 同じ失敗・詰まり・手戻りが出てくる
- 同じ情報を何度も探している
- 同じ形式のレポートや出力を作っている
- 同じ周期で確認している
- 「毎回」「また」「前も」「手で」「面倒」「忘れがち」などの表現がある
```

---

### Step 4 — 作業パターンをクラスタリングする

抽出した記述を、意味的に近い作業ごとにまとめる。

クラスタには以下を付与する。

```yaml
name: 作業名
type: skill | cli | context | eval | cron | rules
evidence:
  - file: path/to/file.md
    excerpt: 該当箇所
    date: YYYY-MM-DD or unknown
count: 回数
confidence: low | medium | high
reason: 候補理由
risk: 自動化・形式化する場合のリスク
```

クラスタリング時の注意：

- 同じ単語だけでまとめない。目的・入出力・判断基準が近いものをまとめる。
- 一回しか出ていないものは原則候補にしない。
- ただし、ユーザーが明示的に「毎回困る」「形式化したい」と書いている場合は候補にしてよい。
- 似た既存skill/CLIがある場合は、新規作成ではなく既存資産の更新候補にする。

---

### Step 5 — 既存資産と照合する

`targets.md` の `existing_assets` に指定された場所を確認し、既存の形式化資産と照合する。

照合対象：

- `~/.hermes/skills/`
- `.claude/skills/`
- repo内 `skills/`
- CLI / scripts
- context / memorizer topics
- AGENTS.md
- CLAUDE.md
- eval / check scripts
- cron jobs / scheduled tasks

判定：

```text
未形式化       → 新規候補
一部形式化済み → 既存資産の更新候補
形式化済み     → 通知しない、または「対応不要」に入れる
重複気味       → 統合・prune候補
```

---

### Step 6 — 候補タイプを判定する

#### スキル候補

以下が多いほどスキル候補とする。

- 判断基準がある
- 手順だけでなく「いつ使うか」「いつ止めるか」が重要
- ユーザー固有の好み・運用・評価軸が含まれる
- 次回の説明量を減らせる
- 失敗時の停止条件を書ける
- CLIだけでは解決できない判断がある

例：

```text
- PRレビュー観点
- 副業案件の選別基準
- AIニュースの日次評価軸
- context管理方針
- 英語レッスン運用
```

#### CLI候補

以下が多いほどCLI候補とする。

- 入力と出力が明確
- 手順が機械的
- ファイル操作・API取得・整形・集計が中心
- 手作業だとミスしやすい
- 3回以上再利用見込みがある
- `list` / `check` / `dry-run` を作れる
- 副作用範囲を限定できる

例：

```text
- Markdownログの集計
- 候補一覧の生成
- context packのcompact
- frontmatter検査
- repo横断のAGENTS.md検査
```

#### eval / check候補

以下が多いほど eval / check 候補とする。

- 出力に構造的な要件がある
- 毎回漏れやすい項目がある
- 機械的に検査できる
- 実行前・提出前の品質ゲートにできる
- stop condition として使える

例：

```text
- SKILL.md frontmatter検査
- cronレポート形式検査
- AGENTS.md必須項目検査
- PRレビュー前チェック
```

#### cron候補

以下が多いほど cron 候補とする。

- 定期的に見る価値がある
- ユーザーが毎回依頼する必要がない
- 通知だけで価値がある
- 自動実行の副作用が小さい
- 実行頻度を明確にできる

例：

```text
- skill-audit
- unused-skill audit
- daily research scan
- weekly formalization review
```

#### AGENTS.md 候補

以下が多いほど repo rules 候補とする。

- repo固有の権限境界がある
- 実行してよいコマンド/禁止コマンドがある
- テスト・レビュー・停止条件がある
- MCPや外部SaaS権限を制限したい
- agentに毎回守らせたい作業規約がある

例：

```text
- このrepoではpush禁止
- このrepoではdry-run必須
- テストが落ちたら3回以上試行しない
- 外部API書き込みは禁止
```

---

### Step 7 — スコアリングする

候補ごとにスコアを付ける。

#### 共通スコア

```text
+2 過去30日で2回以上出現
+2 ユーザー固有の運用・判断基準がある
+1 次回の説明量を減らせる
+1 失敗時の停止条件を書ける
+1 既存資産にきれいに接続できる
+1 自動化・形式化しても副作用が小さい
-1 一回限りの可能性が高い
-1 証拠が曖昧
-2 既存資産で十分カバー済み
-2 自動化すると危険・副作用が大きい
-2 README等の静的docs由来で、実作業ログではない
```

#### CLI追加スコア

```text
+2 入出力が明確
+1 dry-run / check / list が作れる
+1 ファイル/API/整形/集計など機械的処理が中心
-2 判断が中心でCLIに向かない
```

#### スキル追加スコア

```text
+2 判断基準・手順・pitfallを書ける
+1 既存skillでは不足している
-2 単なるコマンド列でskillにする必要が薄い
```

`min_score` 以上の候補だけ通知する。  
デフォルトは `4`。

---

### Step 8 — 通知する

候補がある場合、以下の形式で報告する。

```markdown
## skill-audit レポート (YYYY-MM-DD)

### 上位候補

#### 1. {候補名}
- 種別: skill / cli / context / eval / cron / rules
- スコア: {score}
- 根拠: {該当ファイル} で {N} 回
- 理由: {なぜ形式化すべきか}
- 推奨対応: draft / 既存更新 / defer / prune
- 最小実装:
  - {最初に作るべき最小単位}
- リスク:
  - {自動化・形式化の懸念}

### スキル候補
- {作業名}: {該当ファイル} で{N}回 — {理由}

### CLI候補
- {作業名}: {該当ファイル} で{N}回 — {理由}

### eval / check候補
- {作業名}: {該当ファイル} で{N}回 — {理由}

### cron候補
- {作業名}: {該当ファイル} で{N}回 — {理由}

### AGENTS.md / CLAUDE.md候補
- {作業名}: {該当ファイル} で{N}回 — {理由}

### 対応不要・見送り
- {候補名}: {理由}
```

候補がない場合は、以下を1行だけ出力する。

```text
スキル/CLI/context/eval候補なし
```

---

## draft生成について

このスキル単体では、本番資産を自動作成しない。

ユーザーが明示的に許可した場合のみ、以下のような draft を作成してよい。

```text
~/.hermes/factory/drafts/
  skills/
  cli/
  contexts/
  evals/
  rules/
```

draft作成時の原則：

- 本番の `~/.hermes/skills` や repo scripts を直接変更しない
- 既存資産への上書きをしない
- 副作用のあるCLIは作らない
- CLI案はまず `check` / `list` / `dry-run` から始める
- draftには根拠ファイルと採用理由を必ず残す

---

## 停止条件

以下の場合は処理を停止し、理由を表示する。

- `targets.md` が存在しない
- 対象ファイルが0件
- 対象ファイル数が `max_files` を大幅に超え、絞り込み不能
- 対象ファイルの多くが巨大で、要約なしに読むと高コスト
- private / secret / credential らしきファイルが含まれる
- 既存資産との照合ができず、重複判定が困難
- 候補作成が本番ファイル変更を必要とする

---

## セキュリティ・プライバシー注意

以下は読み込み・通知時に注意する。

- API key
- token
- password
- private key
- cookie
- 個人情報
- 顧客情報
- 未公開の事業情報

通知には、秘密情報や長文引用を含めない。  
根拠としてはファイルパス・短い要約・行番号程度に留める。

---

## よくある失敗

### 1. skillを増やしすぎる

目的はskill数を増やすことではない。  
既存skillに統合できるなら、新規作成ではなく更新候補にする。

### 2. CLI化すべきものをskill化する

手順が機械的で入出力が明確なら、skillではなくCLIにする。  
skillは「いつ使うか」「どう判断するか」を書く場所。

### 3. READMEやdocsを実作業ログとして扱う

Markdown全体を読む場合、静的docsが大量に混ざる。  
実作業ログ・日報・session summary・notes を優先し、README等は低優先度にする。

### 4. 自動作成しすぎる

cronで本番skillやCLIを自動生成すると、すぐにゴミが増える。  
原則は `candidate → draft → review → promote → prune`。

### 5. pruneを忘れる

使われないskill/CLI/contextは運用負債になる。  
月次で未使用・重複・古い資産を見直す。

---

## 推奨運用

### daily

```text
Markdownログをスキャン
候補を検出
上位候補だけ通知
```

### weekly

```text
上位3件だけdraft化候補にする
既存skill/CLI/contextへの統合案を出す
```

### monthly

```text
使われていないskill/CLI/contextを検出
統合・削除・compact候補を出す
```

---

## 出力例

```markdown
## skill-audit レポート (2026-05-26)

### 上位候補

#### 1. context-logからCLI候補を抽出する処理
- 種別: cli
- スコア: 7
- 根拠: ~/repos/notes/daily.md, ~/context/agent-ops.md で3回
- 理由: Markdownログを読み、反復作業を抽出する操作が繰り返されている。入出力が明確で、dry-run可能。
- 推奨対応: draft
- 最小実装:
  - `nu audit skills --dry-run`
  - include/exclude glob対応
  - JSON出力
- リスク:
  - README等の静的docsを誤検出する可能性

### スキル候補
- 個人agent運用方針: ~/.hermes/context/agent-ops.md で2回 — 判断基準が繰り返されている

### CLI候補
- Markdownログ監査: ~/repos/nu/notes/daily.md で3回 — 入出力が明確でdry-run可能

### eval / check候補
- SKILL.md品質チェック: skills配下で2回 — frontmatterや停止条件の漏れを機械検査できる

### cron候補
なし

### AGENTS.md / CLAUDE.md候補
- agentの自動作成禁止ルール: AGENTS.md候補 — 本番資産への副作用境界を明文化すべき

### 対応不要・見送り
- README由来のセットアップ手順: 静的docsであり、反復作業ログではないため見送り
```

---

## 最終チェックリスト

- [ ] `targets.md` を読んだ
- [ ] include / exclude globを適用した
- [ ] Markdown全体を読む場合もREADME等の静的docsを低優先度にした
- [ ] ファイルサイズ・件数上限を守った
- [ ] 過去N日分に絞った
- [ ] 候補を skill / cli / eval / cron / rules に分類した
- [ ] 既存資産と照合した
- [ ] スコアリングした
- [ ] 本番資産を自動作成していない
- [ ] 秘密情報を通知に含めていない
- [ ] 候補がない場合は1行だけ出力した
