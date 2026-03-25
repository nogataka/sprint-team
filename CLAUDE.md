# AI開発組織 - 組織憲法

## プロジェクト概要

プロジェクトの概要・ドメイン知識は `.claude/rules/domain/` 以下を参照。

## 現在のスプリント状態

@.claude/sprint-state.md

---

## バックログ管理

**GitHub Issues が唯一の正（Source of Truth）。** sprint-state.md はスナップショットに過ぎない。

| 層 | 保存先 | 操作 |
|---|--------|------|
| プロダクトバックログ | GitHub Issues（ラベル: `backlog` / `ready`） | `gh issue create`, `gh issue edit --add-label ready` |
| スプリントバックログ | GitHub Issues（マイルストーン: `Sprint N`） | `gh issue edit --milestone "Sprint N"` |
| タスク（実装単位） | 各 Issue 内の `- [ ]` チェックリスト | `gh issue edit --body` で追記 |

- Issue を作成したら `backlog` ラベルを付与する
- リファインメント（AC 定義）が完了した Issue は `ready` ラベルに変更する
- `/sprint-plan` でスプリントに投入する Issue にマイルストーンを設定する
- planner がタスク分解した結果は Issue body のチェックリストに書き込む
- タスク完了時は Issue のチェックボックスを更新する（`- [ ]` → `- [x]`）

---

## スプリントライフサイクル

スプリントは2週間サイクル。各イベントは対応するスキルで自動化されている。

| タイミング | スキル | 実行内容 |
|-----------|--------|----------|
| Day 1 | `/sprint-plan N "ゴール"` | `ready` Issue 選定 → タスク分解 → マイルストーン設定 → sprint-state.md 生成 |
| 毎朝 | `/standup` | Issues 進捗取得 → Done/Today/Blockers 整理 → Slack 通知 |
| 随時 | `/implement <issue番号>` | 計画 → ブランチ作成 → 実装 → レビュー → テスト → PR 作成 |
| 随時 | `/review-pr <PR番号>` | diff 分析 → Critical/Major/Minor 判定 → GitHub コメント → approve or request-changes |
| 随時 | `/daily-report` | コミット・PR・Issue 集計 → Slack 通知 |
| 最終日 | `/sprint-review` | 完了率集計 → レポート生成 → 未完了 Issue を次スプリントに移動 |
| 最終日 | `/retro` | KPT 整理 → CLAUDE.md ルール追記 → git commit |

---

## エージェント起動ルール

タスクの性質に応じて以下のエージェントに委任する。

### 判断基準

```
ユーザーの指示を受け取ったら:

1. スラッシュコマンドで指定されている場合
   → そのスキルを実行する（スキルが内部でエージェントを起動する）

2. Issue 番号が指定されている場合
   → /implement <issue番号> を実行する

3. 自由形式の実装依頼の場合
   → planner に計画を依頼 → 計画に基づき実装エージェントに委任

4. レビュー依頼の場合
   → reviewer に委任（PR がある場合は /review-pr）

5. 進捗確認・報告の場合
   → scrum-master または reporter に委任
```

### エージェント一覧と起動順序

| エージェント | 役割 | いつ起動するか |
|------------|------|--------------|
| planner | 要件分析・タスク分解・設計 | 実装の最初に必ず起動する |
| product-owner | バックログ管理・優先順位付け | `/sprint-plan` 内で起動する |
| backend-dev | DB・API 実装 | planner の計画に DB/API タスクがある場合 |
| frontend-dev | UI 実装 | planner の計画に UI タスクがある場合 |
| reviewer | コードレビュー・セキュリティ監査 | 実装完了後、PR 作成前に必ず起動する |
| tester | テスト設計・実装・実行 | reviewer の後に起動する |
| scrum-master | 進行管理・Slack 通知 | スプリントイベント時に起動する |
| reporter | ドキュメント・レポート生成 | スプリントレビュー・日次レポート時に起動する |

### 起動順序の制約

```
planner → backend-dev → frontend-dev → reviewer → tester
                                          ↑
                              Critical あり → 実装に差し戻し
```

- **planner は常に最初。** 計画なしに実装しない
- **reviewer は実装後・PR 前に必ず通す。** reviewer を飛ばして PR を作成しない
- **backend-dev → frontend-dev の順序。** API が先、UI が後（API に依存するため）
- **Critical 指摘がある場合は差し戻し。** 修正後に再レビュー

---

## ビルド・テストコマンド

```bash
pnpm install          # 依存関係インストール
pnpm dev              # 開発サーバー起動
pnpm build            # プロダクションビルド
pnpm test             # 全テスト実行
pnpm test:unit        # ユニットテストのみ
pnpm test:e2e         # E2Eテスト
pnpm lint             # ESLint実行
pnpm typecheck        # TypeScript型チェック
pnpm db:migrate       # Supabaseマイグレーション実行
pnpm db:seed          # シードデータ投入
```

---

## アーキテクチャルール

@.claude/rules/architecture.md

## コーディング規約

@.claude/rules/code-style.md

## テスト戦略

@.claude/rules/testing.md

## セキュリティルール

@.claude/rules/security.md

## ドメイン知識

@.claude/rules/domain/project.md

---

## 鉄則（レトロで積み上がるルール）

> このセクションは `/retro` スキル実行時に自動更新される。
> 更新日を必ず記録すること。

### 常に守るルール

- `main` ブランチへの直接 push は**絶対禁止**
- PR は必ず reviewer エージェントの確認を経てから作成する
- `.env` / `.env.local` は絶対に読み書きしない（Supabase の anon key も含む）
- Supabase のマイグレーションは必ず `db:backup` 後に実行する
- Stripe の Webhook シークレットをコードに直書きしない
- `rm -rf` は PreToolUse フックでブロックされる（回避しない）
- 外部 API レスポンスは必ず Zod でバリデーションする
- GitHub Issues が正。sprint-state.md を直接手動編集しない

### スプリントで学んだルール

<!-- /retro 実行時にここに追記される -->
<!-- 例: [Sprint 1] Supabase RLS ポリシーは実装前に必ず設計する -->
