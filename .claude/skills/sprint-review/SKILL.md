---
name: sprint-review
description: スプリントレビューを実行する。GitHub Issues から完了機能サマリー・未完了分析・レポート生成・Slack通知を自動化する
context: fork
allowed-tools: Read, Write, Edit, Bash(gh *), Bash(git *), Bash(cat *), Bash(date *), Bash(curl -X POST *), Bash(mkdir *), Bash(jq *)
---

# Sprint Review

## ステップ 1: GitHub Issues からスプリント情報を収集

### 現スプリントのマイルストーン名
!`cat .claude/sprint-state.md 2>/dev/null | grep 'Sprint番号' | grep -o 'Sprint [0-9]*' || echo "Sprint 不明"`

### 完了した Issue（closed）
!`gh issue list --milestone "$(cat .claude/sprint-state.md 2>/dev/null | grep 'Sprint番号' | grep -o 'Sprint [0-9]*')" --state closed --json number,title,closedAt,labels 2>/dev/null || echo "完了 Issue なし"`

### 未完了の Issue（open）
!`gh issue list --milestone "$(cat .claude/sprint-state.md 2>/dev/null | grep 'Sprint番号' | grep -o 'Sprint [0-9]*')" --state open --json number,title,labels 2>/dev/null || echo "未完了 Issue なし"`

### 進捗サマリー
!`echo "Closed: $(gh issue list --milestone "$(cat .claude/sprint-state.md 2>/dev/null | grep 'Sprint番号' | grep -o 'Sprint [0-9]*')" --state closed --json number 2>/dev/null | jq length) / Total: $(gh issue list --milestone "$(cat .claude/sprint-state.md 2>/dev/null | grep 'Sprint番号' | grep -o 'Sprint [0-9]*')" --state all --json number 2>/dev/null | jq length)" 2>/dev/null || echo "集計失敗"`

### マージ済み PR（2週間以内）
!`gh pr list --state merged --json number,title,mergedAt --limit 20 2>/dev/null`

---

## ステップ 2: product-owner エージェントに未完了タスク整理を依頼

product-owner エージェントを起動し、以下を指示する:

> 上記の未完了 Issue を確認し、以下をまとめてください:
> - 各 Issue の持ち越し判定（次スプリントに持ち越すか、バックログに戻すか）
> - 持ち越し理由
> - バックログ優先順位の再評価

---

## ステップ 3: reporter エージェントにレポート生成を依頼

reporter エージェントを起動し、以下を指示する:

> 上記データからスプリントレビューレポートを生成してください。
> AGENT.md のフォーマットに従い、`docs/sprint-reviews/sprint-N.md` として保存してください。

```bash
mkdir -p docs/sprint-reviews
```

---

## ステップ 4: scrum-master エージェントに sprint-state.md 再生成と通知を依頼

scrum-master エージェントを起動し、以下を指示する:

> 1. 未完了 Issue のマイルストーンを次スプリントに移動してください:
>    ```bash
>    gh issue edit <number> --milestone "Sprint N+1"
>    ```
> 2. sprint-state.md を次スプリントのテンプレートとして再生成してください
> 3. スプリントレビュー完了の Slack 通知を送信してください（Velocity・完了率・主要完了機能を含む）

---

## ステップ 5: git commit

```bash
SPRINT=$(cat .claude/sprint-state.md 2>/dev/null | grep 'Sprint番号' | grep -o '[0-9]*' | head -1 || echo "N")
git add docs/sprint-reviews/ .claude/sprint-state.md .claude/sprint-log.md
git commit -m "docs: Sprint $SPRINT review report" 2>/dev/null || echo "コミットするファイルがありません"
```
