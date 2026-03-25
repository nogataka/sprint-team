---
name: retro
description: スプリントレトロスペクティブを実行する。KPT整理→改善アクション→CLAUDE.md/rules/agentsへの自動フィードバックで組織を進化させる
context: fork
allowed-tools: Read, Write, Edit, Bash(cat *), Bash(git *), Bash(date *), Bash(grep *)
---

# Sprint Retrospective

> このスキルの最重要ポイント：レトロの学びを CLAUDE.md・rules・agents に自動反映し、組織を自律進化させること。

## データ収集

### スプリントレビューレポート
!`cat docs/sprint-reviews/*.md 2>/dev/null | tail -100 || echo "sprint-review を先に実行してください"`

### スプリントログ（エージェント活動記録）
!`cat .claude/sprint-log.md 2>/dev/null`

### 今スプリントの変更一覧
!`git log --oneline --since="2 weeks ago" 2>/dev/null`

### 現在のルール
!`cat .claude/rules/code-style.md 2>/dev/null | head -30`

---

## ステップ 1: scrum-master エージェントに KPT 整理を依頼

scrum-master エージェントに以下を依頼してください：
「上記データをもとに今スプリントの KPT（Keep/Problem/Try）を整理してください。Problem と Try には具体的な改善ファイルへの対応付けも含めてください。」

---

## ステップ 2: Try アクションを適切なファイルに反映

scrum-master の KPT 結果をもとに、以下の分類で各ファイルを更新してください：

### コーディングルールの改善
**対象:** `.claude/rules/code-style.md` / `.claude/rules/testing.md` / `.claude/rules/security.md`
例: 「Supabase RLS ポリシーは実装前に設計する」→ `.claude/rules/security.md` に追記

### エージェント動作の改善
**対象:** `.claude/agents/[agent-name]/AGENT.md`
例: 「reviewer が RLS チェックを見落とした」→ `.claude/agents/reviewer/AGENT.md` のチェックリストに追加

### Hook の改善
**対象:** `.claude/hooks/` 以下のシェルスクリプト
例: 「マイグレーション前のバックアップを自動化」→ `pre-tool/auto-backup.sh` を追加

### CLAUDE.md の鉄則更新
**最重要:** `CLAUDE.md` の「スプリントで学んだルール」セクションに今スプリントの教訓を追記

```markdown
<!-- CLAUDE.md の「スプリントで学んだルール」に追記するフォーマット -->
- [Sprint N - YYYY-MM-DD] [学んだルール]
```

---

## ステップ 3: 次スプリントの改善事項を sprint-state.md に記録

`.claude/sprint-state.md` に「次スプリントの改善アクション」セクションを追加してください。

---

## ステップ 4: 変更を git commit

```bash
TODAY=$(date +%Y-%m-%d)
SPRINT=$(grep 'Sprint番号' .claude/sprint-state.md | grep -o '[0-9]*' | head -1)

git add \
  CLAUDE.md \
  .claude/rules/ \
  .claude/agents/ \
  .claude/hooks/ \
  .claude/sprint-state.md \
  .claude/sprint-log.md

git commit -m "chore: apply retro learnings from Sprint ${SPRINT} ($TODAY)" 2>/dev/null || echo "変更なし"
```

---

## ステップ 5: reporter エージェントに議事録保存を依頼

reporter エージェントに以下を依頼してください：
「今スプリントのレトロ議事録を `docs/sprint-reviews/sprint-N-retro.md` として保存し、Slack に完了通知を送信してください。」

---

## 完了確認

以下を確認してください：
- [ ] CLAUDE.md の「スプリントで学んだルール」が更新された
- [ ] 関連する rules/*.md が更新された（あれば）
- [ ] 関連する agents/*.md が更新された（あれば）
- [ ] git commit が完了した
- [ ] 次スプリントの sprint-state.md テンプレートが準備できた
