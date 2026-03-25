# ユーザーガイド

このガイドでは、Claude Code AI Sprint Team の導入から、スプリントを1周回すまでの手順を解説します。

---

## 目次

1. [前提条件](#1-前提条件)
2. [導入手順](#2-導入手順)
3. [プロジェクトに合わせたカスタマイズ](#3-プロジェクトに合わせたカスタマイズ)
4. [スプリントの流れ](#4-スプリントの流れ)
5. [各スキルの詳細な使い方](#5-各スキルの詳細な使い方)
6. [バックログ管理の運用ルール](#6-バックログ管理の運用ルール)
7. [Hook の仕組みと動作](#7-hookの仕組みと動作)
8. [エージェントの役割と起動順序](#8-エージェントの役割と起動順序)
9. [よくある質問](#9-よくある質問)

---

## 1. 前提条件

以下のツールが必要です。

| ツール | 用途 | インストール確認 |
|--------|------|----------------|
| Claude Code | AI エージェントの実行環境 | `claude --version` |
| GitHub CLI | Issue・PR・マイルストーンの操作 | `gh auth status` |
| Git | バージョン管理 | `git --version` |
| Node.js + pnpm | ビルド・テスト（プロジェクトによる） | `pnpm --version` |
| jq | Hook 内の JSON パース | `jq --version` |

**Claude Code のインストール方法:**

```bash
npm install -g @anthropic-ai/claude-code
```

**GitHub CLI の認証:**

```bash
gh auth login
# → GitHub.com → HTTPS → ブラウザで認証
```

---

## 2. 導入手順

### 新規プロジェクトに導入する場合

```bash
# テンプレートをクローン
git clone https://github.com/your-org/sprint-team.git my-project
cd my-project

# 不要なテンプレートの git 履歴を削除して新しいリポジトリとして初期化
rm -rf .git
git init
git add .
git commit -m "init: AI Sprint Team テンプレートから開始"

# GitHub にリポジトリを作成してプッシュ
gh repo create my-project --private --source=. --push
```

### 既存プロジェクトに導入する場合

```bash
cd /path/to/your-existing-project

# テンプレートから必要なファイルをコピー
cp -r /path/to/sprint-team/.claude/ .claude/
cp /path/to/sprint-team/CLAUDE.md CLAUDE.md

# docs ディレクトリもコピー（任意）
cp -r /path/to/sprint-team/docs/ docs/

# Hook スクリプトに実行権限を付与
chmod +x .claude/hooks/**/*.sh
```

### 導入後の確認

```bash
# GitHub CLI が認証済みか確認
gh auth status

# ファイルが正しく配置されているか確認
ls .claude/agents/     # → 8個のディレクトリが見える
ls .claude/skills/     # → 7個のディレクトリが見える
ls .claude/hooks/      # → pre-tool/, post-tool/, session/, subagent/ が見える

# Claude Code を起動
claude
```

起動すると SessionStart Hook が動作し、「スタンドアップコンテキストを収集しました」というメッセージが表示されます。これが表示されれば正常に動作しています。

---

## 3. プロジェクトに合わせたカスタマイズ

導入後、以下のファイルを自分のプロジェクトに合わせて編集してください。

### 必須: ドメイン知識（`.claude/rules/domain/`）

このファイルがプロジェクト固有の情報源になります。以下を記述してください:

```markdown
# ドメイン知識

## ビジネスモデル
[サービスの概要、収益モデル]

## ドメイン用語
| 日本語 | コード内の用語 | 説明 |
|-------|--------------|------|
| 注文 | order | ユーザーが商品を購入する行為 |

## DB スキーマ（主要テーブル）
[テーブル定義。エージェントが実装時に参照します]

## 外部サービス連携
[Stripe, SendGrid, AWS S3 など]
```

### 必須: CLAUDE.md のビルドコマンド

`CLAUDE.md` 内の「ビルド・テストコマンド」セクションを編集してください:

```markdown
## ビルド・テストコマンド

pnpm install          # 依存関係インストール
pnpm dev              # 開発サーバー起動
pnpm build            # プロダクションビルド
pnpm test             # 全テスト実行
pnpm lint             # リンター実行
pnpm typecheck        # 型チェック
```

### 推奨: アーキテクチャルール（`.claude/rules/architecture.md`）

ディレクトリ構成と依存関係のルールを記述すると、エージェントが正しい場所にファイルを作成します。

### 推奨: コーディング規約（`.claude/rules/code-style.md`）

命名規則、インポート順序、エラーハンドリングパターンなどを記述すると、エージェントがそれに従ってコードを書きます。

### 任意: Slack 通知

```bash
# シェルの設定ファイル（.bashrc, .zshrc 等）に追加
export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T.../B.../xxx
```

設定すると `/standup`, `/sprint-review`, `/retro` の結果が Slack に自動投稿されます。未設定でも全機能は動作します。

---

## 4. スプリントの流れ

2週間を1スプリントとして、以下のサイクルを繰り返します。

### Day 1: スプリント計画

```
/sprint-plan 1 "ユーザー認証機能の実装"
```

**何が起きるか:**

1. `ready` ラベルの付いた Issue を GitHub から取得
2. product-owner エージェントが優先順位を付ける（MoSCoW 法）
3. planner エージェントが各 Issue をタスクに分解する
4. タスクリストが Issue の body に書き込まれる
5. マイルストーン `Sprint 1` が作成され、選定 Issue に設定される
6. `sprint-state.md` がスナップショットとして生成される

**事前準備:** Issue に `ready` ラベルを付けておいてください。ラベルがない Issue はスプリント候補に含まれません。

### Day 1〜最終日: 実装

```
/implement 42
```

**何が起きるか:**

1. planner が Issue を読んで実装計画を立てる（タスクリストがなければ作成）
2. feature ブランチが自動作成される
3. backend-dev / frontend-dev が計画に沿って実装する
4. 完了したタスクの Issue チェックボックスが更新される
5. reviewer がコードレビューを実施する（Critical があれば差し戻し）
6. tester がテストを作成・実行する
7. Draft PR が作成される（`Closes #42` で Issue と紐付け）

### 毎朝: スタンドアップ

```
/standup
```

**何が起きるか:**

1. GitHub Issues からスプリントの進捗を取得
2. scrum-master が Done / Today / Blockers を整理
3. Slack に通知（設定時）

### 随時: PR レビュー

```
/review-pr 15
```

**何が起きるか:**

1. PR の diff を取得
2. reviewer がセキュリティ・型安全性・パフォーマンス・コーディング規約の観点でレビュー
3. GitHub に Critical / Major / Minor のコメントを投稿
4. Critical が 0 件なら approve、1 件以上なら request-changes

### 最終日: スプリントレビュー

```
/sprint-review
```

**何が起きるか:**

1. マイルストーンの完了率を集計
2. reporter がレビューレポートを `docs/sprint-reviews/sprint-N.md` に保存
3. 未完了 Issue を次スプリントのマイルストーンに移動
4. sprint-state.md を次スプリント用に再生成

### 最終日: レトロスペクティブ

```
/retro
```

**何が起きるか:**

1. スプリントログ・変更履歴を収集
2. scrum-master が KPT（Keep / Problem / Try）を整理
3. Try アクションを以下に自動反映:
   - `CLAUDE.md` の「スプリントで学んだルール」
   - `.claude/rules/*.md`（コーディング規約など）
   - `.claude/agents/*.md`（エージェントの動作改善）
4. git commit で変更を保存

---

## 5. 各スキルの詳細な使い方

### /sprint-plan

**構文:** `/sprint-plan <スプリント番号> "<スプリントゴール>"`

**例:**
```
/sprint-plan 1 "MVP リリース: ユーザー登録と商品一覧"
/sprint-plan 2 "決済機能と注文管理"
```

**前提条件:**
- GitHub に `ready` ラベル付きの Issue が存在すること
- `gh auth status` が認証済みであること

**出力:**
- GitHub Issues にタスクリストが追記される
- マイルストーン `Sprint N` が作成される
- `.claude/sprint-state.md` が生成される

---

### /implement

**構文:** `/implement <Issue番号>`

**例:**
```
/implement 42
/implement 7
```

**前提条件:**
- 指定した Issue が GitHub に存在すること
- `main` ブランチが最新であること

**出力:**
- feature ブランチが作成される
- コードが実装される
- テストが作成・実行される
- Draft PR が作成される

**注意点:**
- 実装中にレビューで Critical 指摘があった場合は自動で修正・再レビューされます
- テストが失敗した場合も自動で修正・再実行されます

---

### /standup

**構文:** `/standup`（引数なし）

**前提条件:**
- `sprint-state.md` が存在するか、GitHub にマイルストーンが設定済みであること

**出力:**
- Done / Today / Blockers の整理結果
- Slack 通知（`SLACK_WEBHOOK_URL` 設定時）
- sprint-log.md にスタンドアップ完了を記録

---

### /review-pr

**構文:** `/review-pr <PR番号>`

**例:**
```
/review-pr 15
```

**出力:**
- GitHub PR にレビューコメントが投稿される
- Critical 0 件 → approve
- Critical 1 件以上 → request-changes

---

### /sprint-review

**構文:** `/sprint-review`（引数なし）

**出力:**
- `docs/sprint-reviews/sprint-N.md` にレポートが保存される
- 未完了 Issue が次スプリントのマイルストーンに移動される
- sprint-state.md が再生成される

---

### /retro

**構文:** `/retro`（引数なし）

**前提条件:**
- `/sprint-review` を先に実行しておくこと（レビューレポートを参照するため）

**出力:**
- CLAUDE.md にルールが追記される
- 必要に応じて rules/*.md, agents/*.md が更新される
- git commit が作成される

---

### /daily-report

**構文:** `/daily-report`（引数なし）

**出力:**
- 本日のコミット・PR・Issue の集計
- `docs/daily-reports/YYYY-MM-DD.md` にレポートが保存される
- Slack 通知（`SLACK_WEBHOOK_URL` 設定時）

---

## 6. バックログ管理の運用ルール

### Issue のライフサイクル

```
Issue 作成（backlog ラベル）
  ↓
リファインメント（AC 定義、ready ラベルに変更）
  ↓
/sprint-plan でスプリントに投入（マイルストーン設定）
  ↓
/implement で planner がタスク分解（Issue body にチェックリスト追記）
  ↓
実装中（チェックボックスが順次更新される）
  ↓
PR マージ → Issue 自動クローズ（Closes #N）
```

### Issue の書き方

Issue を作成する際は、以下の構造で書くとエージェントが正確に理解できます:

```markdown
## 概要
ユーザーがクレジットカードで商品を購入できるようにする。

## 受け入れ基準
- [ ] ユーザーがカート画面から「購入する」ボタンを押せる
- [ ] Stripe Checkout でカード情報を入力できる
- [ ] 決済成功後に注文確認画面が表示される
- [ ] 決済失敗時にエラーメッセージが表示される

## 補足
- Stripe Test Mode で開発する
- 対応通貨は JPY のみ
```

`## タスク` セクションは planner が自動で追記するため、手動で書く必要はありません。

### ラベルの付け方

```bash
# Issue 作成時に backlog ラベルを付ける
gh issue create --title "決済機能の実装" --body "..." --label "backlog,enhancement"

# リファインメント後に ready に変更
gh issue edit 42 --remove-label "backlog" --add-label "ready"
```

---

## 7. Hook の仕組みと動作

Hook は `.claude/settings.json` で定義されており、Claude Code がツールを使うたびに自動で実行されます。ユーザーが意識する必要はありませんが、以下の動作をバックグラウンドで行っています。

### block-dangerous.sh（安全ガード）

以下のコマンドを自動でブロックします:

| ブロック対象 | 理由 |
|------------|------|
| `rm -rf` | 再帰的な全削除を防止 |
| `git push --force` | リモートの履歴破壊を防止 |
| `git push origin main` | main への直接プッシュを防止（PR 経由を強制） |
| `.env` ファイルの読み書き | シークレット漏洩を防止 |
| `sudo` | 権限昇格を防止 |
| 本番 DB への直接アクセス | 本番データの誤操作を防止 |

### auto-quality.sh（自動品質チェック）

TypeScript/TSX ファイルを編集すると自動で実行されます:

1. ESLint で自動修正可能なエラーを修正
2. Prettier でコードフォーマット

`node_modules` が存在しない場合はスキップされます。

### update-progress.sh（進捗記録）

`gh issue close` や `gh pr merge` を実行すると、`.claude/sprint-log.md` にイベントが自動記録されます。

### on-start.sh / on-stop.sh（セッション管理）

- **開始時:** 昨日のコミット、PR 状況を `/tmp/standup-context.md` に収集
- **終了時:** sprint-state.md のタイムスタンプ更新、Slack 通知（設定時）

---

## 8. エージェントの役割と起動順序

### 起動順序のルール

```
planner（必ず最初）
  ↓
backend-dev（DB/API タスクがある場合）
  ↓
frontend-dev（UI タスクがある場合）
  ↓
reviewer（実装後、PR 前に必ず）
  ↓ Critical あり → backend-dev / frontend-dev に差し戻し
tester（reviewer 通過後）
```

- **planner を飛ばさない。** 計画なしに実装を始めると手戻りが発生します
- **reviewer を飛ばさない。** PR 作成前に必ずレビューを通します
- **backend → frontend の順。** API が先、UI が後（UI は API に依存するため）

### エージェントの設定を変更したい場合

各エージェントの振る舞いは `.claude/agents/[name]/AGENT.md` で定義されています。

**よくあるカスタマイズ例:**

- reviewer のチェック項目を追加したい → `reviewer/AGENT.md` のチェックリストに項目を追記
- planner のタスク分解の粒度を変えたい → `planner/AGENT.md` の出力フォーマットを調整
- tester のカバレッジ基準を変えたい → `tester/AGENT.md` の完了条件を編集

---

## 9. よくある質問

### Q: スプリントの途中で Issue を追加したい

`ready` ラベルを付けた Issue を作成し、マイルストーンを手動で設定してください:

```bash
gh issue create --title "緊急バグ修正" --label "bug,ready" --milestone "Sprint 1"
```

### Q: Issue のタスクリストを手動で修正したい

GitHub の Web UI で Issue の body を直接編集できます。planner が書いたタスクリストのフォーマット（`- [ ] カテゴリ: 内容（担当, ポイント）`）を維持してください。

### Q: スプリントの期間を変えたい

デフォルトは2週間です。`/sprint-plan` スキルの `date -v+14d` の部分を変更してください（例: 1週間なら `+7d`）。

### Q: 複数人で同じリポジトリを使える？

はい。各自の Claude Code セッションから同じリポジトリに対してスキルを実行できます。ただしマイルストーンや Issue の競合に注意してください。

### Q: pnpm 以外のパッケージマネージャーを使いたい

`CLAUDE.md` のビルドコマンドと、`.claude/hooks/post-tool/auto-quality.sh` 内の `npx` コマンドを変更してください。

### Q: Hook を無効にしたい

`.claude/settings.json` の `hooks` セクションから該当する Hook のエントリを削除してください。
