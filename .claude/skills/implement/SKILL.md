---
name: implement
description: GitHub IssueまたはタスクをPlanning→実装→Review→Test→PRの全サイクルで自動実行する
argument-hint: "[issue番号またはタスク説明]"
context: fork
allowed-tools: Read, Glob, Grep, Edit, Write, Bash(git *), Bash(gh *), Bash(pnpm *), Bash(npx *), Bash(jq *)
---

# Implement: $ARGUMENTS

## ステップ 0: Issue 確認と前提チェック

```bash
gh auth status 2>&1 || echo "ERROR: gh CLI が未認証です"
```

```bash
gh issue view $ARGUMENTS --json number,title,body,labels,milestone 2>/dev/null || echo "Issue 番号ではなくタスク説明として処理します: $ARGUMENTS"
```

!`gh issue view $ARGUMENTS --json number,title,body,labels 2>/dev/null || echo "タスク: $ARGUMENTS"`

---

## ステップ 1: planner エージェントに実装計画を依頼

planner エージェントを起動し、以下を指示する:

> Issue #$ARGUMENTS の実装計画を立ててください。
> AGENT.md の出力フォーマットに従い、「実装計画」と「Issue タスクリスト」の両方を出力してください。

---

## ステップ 2: タスクリストを Issue に書き込む

planner の出力した「Issue タスクリスト」を GitHub Issue の body に追記する。

```bash
ISSUE_NUM=$ARGUMENTS
CURRENT_BODY=$(gh issue view $ISSUE_NUM --json body -q '.body')

# planner が出力したタスクリストを TASK_LIST に設定
TASK_LIST="
## タスク

- [ ] ...
"

# Issue body にタスクリストを追記（既にタスクセクションがある場合はスキップ）
if echo "$CURRENT_BODY" | grep -q "## タスク"; then
  echo "タスクリストは既に存在します。スキップします。"
else
  gh issue edit $ISSUE_NUM --body "${CURRENT_BODY}

${TASK_LIST}"
fi
```

---

## ステップ 3: ブランチ作成

```bash
# Issue タイトルからブランチ名を生成
ISSUE_TITLE=$(gh issue view $ARGUMENTS --json title -q '.title' 2>/dev/null || echo "$ARGUMENTS")
BRANCH_NAME="feature/$(echo "$ISSUE_TITLE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-50)"
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout -b "feature/issue-$ARGUMENTS"
```

---

## ステップ 4: 実装（planner の計画に基づきエージェントに委任）

planner の計画を確認し、タスクリストの順序に従って実装エージェントを起動する:

- **DB / API タスク** → backend-dev エージェントに指示:
  > Issue #$ARGUMENTS のタスクリストのうち、DB/API タスクを実装してください。[具体的なタスク内容を記載]

- **UI タスク** → frontend-dev エージェントに指示:
  > Issue #$ARGUMENTS のタスクリストのうち、UI タスクを実装してください。[具体的なタスク内容を記載]

- **両方必要な場合** → backend-dev → frontend-dev の順序で実装

**各タスク完了時に Issue のチェックボックスを更新する:**

```bash
# Issue body を取得し、完了タスクのチェックボックスを更新
BODY=$(gh issue view $ISSUE_NUM --json body -q '.body')
UPDATED_BODY=$(echo "$BODY" | sed 's/- \[ \] DB: \[完了したタスク\]/- [x] DB: [完了したタスク]/')
gh issue edit $ISSUE_NUM --body "$UPDATED_BODY"
```

---

## ステップ 5: reviewer エージェントにコードレビューを依頼

reviewer エージェントを起動し、以下を指示する:

> 現在のブランチの変更差分をレビューしてください。
> `git diff main...HEAD` の結果を確認し、Critical/Major/Minor の分類でフィードバックしてください。

```bash
git diff main...HEAD --stat
```

**Critical な問題がある場合:** 実装エージェントに修正を依頼し、再レビューを実施する。

---

## ステップ 6: tester エージェントにテスト作成・実行を依頼

tester エージェントを起動し、以下を指示する:

> Issue #$ARGUMENTS の実装に対応するテストを作成・実行してください。
> ユニットテスト・統合テスト（必要な場合は E2E テスト）を含めてください。

```bash
pnpm test 2>&1 | tail -30
```

**テストが失敗した場合:** 実装エージェントに修正を依頼し、再テストする。

---

## ステップ 7: ビルド確認と PR 作成

```bash
pnpm typecheck && pnpm lint 2>&1 | tail -10
```

ビルドが通ったら PR を作成する:

```bash
ISSUE_NUM=$ARGUMENTS
ISSUE_TITLE=$(gh issue view $ISSUE_NUM --json title -q '.title' 2>/dev/null || echo "$ARGUMENTS")

gh pr create \
  --title "feat: $ISSUE_TITLE" \
  --body "## Summary
Closes #$ISSUE_NUM

## Changes
[実装内容の要約]

## Review Notes
[reviewer の指摘事項と対応を記載]

## Test
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] E2E tests pass (if applicable)
- [ ] TypeScript errors: 0
- [ ] ESLint errors: 0" \
  --draft
```

---

## ステップ 8: Issue にコメントで進捗を記録

```bash
gh issue comment $ISSUE_NUM --body "Implementation complete. PR created: $(gh pr list --head $(git branch --show-current) --json url -q '.[0].url')"
```
