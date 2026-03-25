---
name: sprint-plan
description: スプリント計画を実行する。GitHub Issues からバックログ整理→タスク分解→マイルストーン設定→sprint-state.md生成を自動化する
argument-hint: "[sprint-number] [sprint-goal]"
context: fork
allowed-tools: Read, Bash(gh *), Bash(git *), Bash(cat *), Bash(date *), Bash(jq *), Write, Edit
---

# Sprint Planning: $ARGUMENTS

## ステップ 0: 前提チェック

```bash
gh auth status 2>&1 || echo "ERROR: gh CLI が未認証です。'gh auth login' を実行してください。"
```

!`gh auth status 2>&1 | head -3 || echo "gh CLI 未認証"`

---

## ステップ 1: 現状把握

### ready ラベル付き Issue（スプリント投入可能なバックログ）
!`gh issue list --label "ready" --state open --json number,title,labels,body --limit 30 2>/dev/null || echo "Issue なし"`

### 前スプリントの完了状況
!`gh issue list --state closed --json number,title,closedAt --limit 10 2>/dev/null || echo "完了 Issue なし"`

### 最新のコミット（直近1週間）
!`git log --oneline --since="1 week ago" 2>/dev/null | head -20 || echo "git 履歴なし"`

---

## ステップ 2: product-owner エージェントにバックログ優先順位付けを依頼

product-owner エージェントを起動し、以下を指示する:

> 上記の ready ラベル付き Issue を、スプリントゴール「$ARGUMENTS」に沿って MoSCoW で優先順位付けしてください。
> 合計 20〜30pt 程度のスプリントバックログ候補を選定してください。
> 出力は AGENT.md の出力フォーマットに従ってください。

---

## ステップ 3: planner エージェントにタスク分解を依頼

product-owner の選定結果をもとに、planner エージェントを起動し、以下を指示する:

> 選定された各 Issue について、実装計画とタスク分解を作成してください。
> タスク分解は AGENT.md の「Issue タスクリスト」形式で出力してください。

---

## ステップ 4: planner の出力を GitHub Issues に書き込む

planner が出力したタスクリストを、各 Issue の body に追記する。

```bash
# Issue ごとに実行（planner の出力から Issue 番号とタスクリストを取得）
ISSUE_NUM=XX
CURRENT_BODY=$(gh issue view $ISSUE_NUM --json body -q '.body')
TASK_LIST="
## タスク

- [ ] DB: ...（backend-dev, Xpt）
- [ ] API: ...（backend-dev, Xpt）
- [ ] UI: ...（frontend-dev, Xpt）
- [ ] Test: ...（tester, Xpt）
"
gh issue edit $ISSUE_NUM --body "${CURRENT_BODY}${TASK_LIST}"
```

**各 Issue に対してこの操作を繰り返す。**

---

## ステップ 5: マイルストーン作成と Issue への設定

```bash
# スプリント番号と期間を設定
SPRINT_NUM=N
START_DATE=$(date +%Y-%m-%d)
END_DATE=$(date -v+14d +%Y-%m-%d 2>/dev/null || date -d "+14 days" +%Y-%m-%d)

# マイルストーン作成
gh api repos/{owner}/{repo}/milestones --method POST \
  -f title="Sprint $SPRINT_NUM" \
  -f due_on="${END_DATE}T23:59:59Z" \
  -f description="Goal: $ARGUMENTS" 2>/dev/null || echo "マイルストーンが既に存在するか、作成に失敗しました"

# 選定した各 Issue にマイルストーンを設定
gh issue edit $ISSUE_NUM --milestone "Sprint $SPRINT_NUM"
```

**選定した全 Issue に対して `gh issue edit --milestone` を実行する。**

---

## ステップ 6: sprint-state.md をスナップショットとして生成

GitHub Issues の現在の状態から sprint-state.md を生成する。

```bash
# スプリントバックログを取得
gh issue list --milestone "Sprint $SPRINT_NUM" --state all --json number,title,state,labels
```

取得結果をもとに `.claude/sprint-state.md` を以下のフォーマットで書き込む:

```markdown
# Sprint State

> このファイルは GitHub Issues から生成されるスナップショットです。
> 正（Source of Truth）は GitHub Issues のマイルストーン「Sprint N」です。
> 再生成: `gh issue list --milestone "Sprint N" --state all --json number,title,state`

## 現在のスプリント

- **Sprint番号:** Sprint [N]
- **期間:** [開始日] 〜 [終了日]（2週間）
- **ゴール:** [goal]
- **開始日:** [YYYY-MM-DD]
- **終了日:** [YYYY-MM-DD]

## スプリントバックログ

| # | Issue | 状態 |
|---|-------|------|
| 1 | #XX [タイトル] | open |
...

## 進捗

- 完了: 0 / [全Issue数]（0%）

---
*最終更新: [YYYY-MM-DD HH:MM]*
*生成元: gh issue list --milestone "Sprint [N]"*
```

---

## ステップ 7: scrum-master エージェントに Slack 通知を依頼

scrum-master エージェントを起動し、以下を指示する:

> Sprint Planning が完了しました。以下の内容で Slack 通知を送信してください:
> - スプリント番号とゴール
> - 選定された Issue の一覧
> - 期間

$SLACK_WEBHOOK_URL が未設定の場合はスキップしてください。
