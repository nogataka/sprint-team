#!/bin/bash
# Stop / SessionEnd Hook: セッション終了時にスプリント状態を永続化する

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%H:%M)
LOG_FILE="$PROJECT_DIR/.claude/sprint-log.md"
STATE_FILE="$PROJECT_DIR/.claude/sprint-state.md"

INPUT=$(cat)
STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // "unknown"' 2>/dev/null || echo "unknown")

# セッション終了をログに記録
mkdir -p "$(dirname "$LOG_FILE")"
echo "[$TODAY $NOW] SESSION_END (reason: $STOP_REASON)" >> "$LOG_FILE"

# sprint-state.md の「最終更新」タイムスタンプを更新
if [ -f "$STATE_FILE" ]; then
  # macOS と Linux 両対応の sed
  if sed --version 2>/dev/null | grep -q GNU; then
    sed -i "s/\*最終更新:.*\*/\*最終更新: $TODAY $NOW\*/" "$STATE_FILE"
  else
    sed -i '' "s/\*最終更新:.*\*/\*最終更新: $TODAY $NOW\*/" "$STATE_FILE"
  fi
fi

# 完了理由が end_turn（正常完了）の場合のみ Slack 通知
if [ "$STOP_REASON" = "end_turn" ] && [ -n "$SLACK_WEBHOOK_URL" ]; then
  curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "{\"text\": \":zzz: Claude Code セッションが終了しました ($TODAY $NOW)\"}" \
    > /dev/null 2>&1 &
fi

exit 0
