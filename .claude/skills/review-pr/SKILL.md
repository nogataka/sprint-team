---
name: review-pr
description: PRをレビューしてGitHubにコメントを投稿する。reviewerエージェントが検証し、結果に応じてapprove/request-changesを実行する
argument-hint: "[PR番号]"
context: fork
allowed-tools: Bash(gh *), Bash(git *), Bash(jq *), Read, Glob, Grep
---

# PR Review: #$ARGUMENTS

## ステップ 1: PR 情報取得

### PR の概要
!`gh pr view $ARGUMENTS --json number,title,body,author,headRefName,baseRefName,additions,deletions,changedFiles 2>/dev/null || echo "PR 番号を確認してください"`

### 変更差分
!`gh pr diff $ARGUMENTS 2>/dev/null | head -500`

### 変更ファイル一覧
!`gh pr diff $ARGUMENTS --name-only 2>/dev/null`

### 既存のコメント
!`gh pr view $ARGUMENTS --comments 2>/dev/null | tail -50`

---

## ステップ 2: reviewer エージェントにレビューを依頼

reviewer エージェントを起動し、以下を指示する:

> PR #$ARGUMENTS をレビューしてください。
> AGENT.md のレビュー観点（セキュリティ・型安全性・パフォーマンス・エラーハンドリング・ルール準拠）に従い、
> Critical/Major/Minor の分類でフィードバックをまとめてください。

---

## ステップ 3: レビュー結果を GitHub に投稿

reviewer の結果をもとに GitHub にコメントを投稿する:

```bash
# reviewer の出力をそのまま PR コメントとして投稿
gh pr comment $ARGUMENTS --body "[reviewer の出力したレビュー結果]"
```

---

## ステップ 4: 判定に応じた処理

### Critical が 0 件の場合（LGTM）:

```bash
gh pr review $ARGUMENTS --approve --body "LGTM. All checks passed."
```

PR に紐づく Issue がある場合、Issue にコメントを追加:
```bash
# PR body から "Closes #XX" を抽出
ISSUE_NUM=$(gh pr view $ARGUMENTS --json body -q '.body' | grep -oE 'Closes #[0-9]+' | grep -oE '[0-9]+' | head -1)
if [ -n "$ISSUE_NUM" ]; then
  gh issue comment $ISSUE_NUM --body "PR #$ARGUMENTS approved. Ready to merge."
fi
```

### Critical が 1 件以上の場合（Changes Requested）:

```bash
gh pr review $ARGUMENTS --request-changes --body "[Critical な指摘事項のサマリー]"
```
