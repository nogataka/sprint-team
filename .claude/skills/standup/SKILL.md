---
name: standup
description: デイリースタンドアップレポートを生成してSlackに投稿する。GitHub Issues から進捗を取得する
context: fork
allowed-tools: Read, Write, Edit, Bash(cat *), Bash(git log *), Bash(gh *), Bash(date *), Bash(curl -X POST *), Bash(jq *)
---

# Daily Standup

## 今日の日付
!`date '+%Y-%m-%d (%a)'`

## ステップ 1: GitHub Issues から進捗を取得

### 現スプリントのマイルストーン名を取得
!`SPRINT=$(cat .claude/sprint-state.md 2>/dev/null | grep 'Sprint番号' | grep -o 'Sprint [0-9]*'); if [ -z "$SPRINT" ]; then SPRINT=$(gh api repos/{owner}/{repo}/milestones --jq 'sort_by(.due_on) | reverse | .[0].title' 2>/dev/null); fi; echo "${SPRINT:-Sprint 不明}"`

### スプリントバックログ（open）
!`SPRINT=$(cat .claude/sprint-state.md 2>/dev/null | grep 'Sprint番号' | grep -o 'Sprint [0-9]*' || gh api repos/{owner}/{repo}/milestones --jq 'sort_by(.due_on) | reverse | .[0].title' 2>/dev/null); gh issue list --milestone "$SPRINT" --state open --json number,title,labels 2>/dev/null || echo "取得失敗"`

### スプリントバックログ（closed = 完了済み）
!`SPRINT=$(cat .claude/sprint-state.md 2>/dev/null | grep 'Sprint番号' | grep -o 'Sprint [0-9]*' || gh api repos/{owner}/{repo}/milestones --jq 'sort_by(.due_on) | reverse | .[0].title' 2>/dev/null); gh issue list --milestone "$SPRINT" --state closed --json number,title,closedAt 2>/dev/null || echo "完了 Issue なし"`

### 直近のコミット（昨日以降）
!`git log --oneline --since="yesterday" 2>/dev/null | head -10 || echo "コミットなし"`

### レビュー待ち PR
!`gh pr list --state open --json number,title,reviewDecision,createdAt --limit 10 2>/dev/null || echo "PR なし"`

---

## ステップ 2: scrum-master エージェントにスタンドアップ整理を依頼

scrum-master エージェントを起動し、以下を指示する:

> 上記データから以下の情報を整理してください:
> - **Done:** 昨日完了したこと（closed Issue、マージ済み PR、コミットから）
> - **Today:** 今日やること（open Issue から優先度順に）
> - **Blockers:** 障害・ブロッカー（レビュー待ち PR、依存関係など）
> - **Sprint 進捗:** closed / total Issue 数とパーセンテージ
>
> Slack 向けスタンドアップメッセージを AGENT.md のフォーマットで生成してください。
> $SLACK_WEBHOOK_URL が設定されていれば送信、未設定ならメッセージのみ出力してください。

---

## ステップ 3: sprint-log.md に記録

```bash
echo "[$(date '+%Y-%m-%d %H:%M')] standup completed" >> .claude/sprint-log.md
```
