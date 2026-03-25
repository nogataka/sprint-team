---
name: daily-report
description: 日次レポートを生成してSlackに投稿する。コミット・PR・Issue・進捗を集計して可視化する
context: fork
allowed-tools: Read, Write, Edit, Bash(cat *), Bash(git *), Bash(gh *), Bash(date *), Bash(curl -X POST *)
---

# Daily Report

## 本日の日付
!`date '+%Y-%m-%d (%A)'`

## 本日のコミット
!`git log --oneline --since="today 00:00" 2>/dev/null || echo "コミットなし"`

## マージ済みPR（本日）
!`gh pr list --state merged --json number,title,mergedAt --limit 10 2>/dev/null`

## オープンPR（レビュー待ち）
!`gh pr list --state open --json number,title,reviewDecision,createdAt 2>/dev/null`

## クローズされたIssue（本日）
!`gh issue list --state closed --json number,title,closedAt --limit 10 2>/dev/null`

## スプリント進捗
!`cat .claude/sprint-state.md 2>/dev/null`

## スプリントログ（本日分）
!`grep "$(date +%Y-%m-%d)" .claude/sprint-log.md 2>/dev/null || echo "本日のログなし"`

---

## reporter エージェントに依頼

reporter エージェントに以下を依頼してください：

1. 上記データから日次レポートを生成する
2. 以下フォーマットで Slack に投稿する：

```
:bar_chart: *Daily Report - [日付]*

*:white_check_mark: 本日の完了*
• [コミット・マージ済みPR]

*:eyes: レビュー待ち* ([件数]件)
• PR #XX - [タイトル]（[経過時間]）

*:dart: Sprint進捗*
[X]/[全タスク] タスク完了 ([%]) | 残り[N]日

*:link: 詳細*
[gh コマンドで生成した URL]
```

3. `docs/daily-reports/YYYY-MM-DD.md` として保存する
