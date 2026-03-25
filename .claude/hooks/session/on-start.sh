#!/bin/bash
# SessionStart Hook: セッション開始時にスタンドアップコンテキストを収集する
# 毎朝の /standup スキルが使用するデータを準備する

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TODAY=$(date +%Y-%m-%d)
YESTERDAY=$(date -d yesterday +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null || date +%Y-%m-%d)
LOG_FILE="$PROJECT_DIR/.claude/sprint-log.md"

# スタンドアップ用コンテキストを /tmp に書き出す
{
  echo "## Standup Context ($TODAY)"
  echo "Generated at: $(date)"
  echo ""

  echo "### Yesterday's commits"
  git -C "$PROJECT_DIR" log \
    --since="${YESTERDAY} 00:00" \
    --until="${TODAY} 00:00" \
    --oneline \
    --author-date-relative \
    2>/dev/null | head -15 || echo "（コミットなし）"
  echo ""

  echo "### Merged PRs (since yesterday)"
  gh pr list --state merged \
    --search "merged:>=${YESTERDAY}" \
    --json number,title \
    2>/dev/null | jq -r '.[] | "- PR #\(.number): \(.title)"' || echo "（PRなし）"
  echo ""

  echo "### Open PRs (needs review)"
  gh pr list --state open \
    --json number,title,reviewDecision,createdAt \
    2>/dev/null | jq -r '.[] | "- PR #\(.number): \(.title) [\(.reviewDecision // "REVIEW_REQUIRED")]"' || echo "（PRなし）"
  echo ""

  echo "### Sprint State"
  cat "$PROJECT_DIR/.claude/sprint-state.md" 2>/dev/null || echo "（sprint-state.md が見つかりません）"

} > /tmp/standup-context.md 2>&1

# セッション開始をスプリントログに記録
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$TODAY $(date +%H:%M)] SESSION_START" >> "$LOG_FILE"

# Claudeへのフィードバック（transcript に表示される）
jq -n '{
  transcript: "✅ SessionStart: スタンドアップコンテキストを収集しました (/tmp/standup-context.md)。/standup で今日のスタンドアップを開始できます。"
}'

exit 0
