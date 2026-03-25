#!/bin/bash
# PostToolUse Hook: Bash 実行後にイベントを sprint-log.md に記録する

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.claude/sprint-log.md"
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%H:%M)

# gh コマンドを検知してログに記録
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Issue がクローズされた場合
if echo "$COMMAND" | grep -qE 'gh\s+issue\s+(close|edit.*--state\s+closed)'; then
  ISSUE_NUM=$(echo "$COMMAND" | grep -oE '#?[0-9]+' | head -1 | tr -d '#')
  if [ -n "$ISSUE_NUM" ]; then
    echo "[$TODAY $NOW] ISSUE_CLOSED #$ISSUE_NUM" >> "$LOG_FILE"
  fi
fi

# PR がマージされた場合
if echo "$COMMAND" | grep -qE 'gh\s+pr\s+merge'; then
  PR_NUM=$(echo "$COMMAND" | grep -oE '#?[0-9]+' | head -1 | tr -d '#')
  if [ -n "$PR_NUM" ]; then
    echo "[$TODAY $NOW] PR_MERGED #$PR_NUM" >> "$LOG_FILE"
  fi
fi

# pnpm test の結果を記録
if echo "$COMMAND" | grep -qE 'pnpm\s+test'; then
  EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_result.exit_code // 0' 2>/dev/null)
  if [ "$EXIT_CODE" = "0" ]; then
    echo "[$TODAY $NOW] TEST_PASSED (cmd: $COMMAND)" >> "$LOG_FILE"
  else
    echo "[$TODAY $NOW] TEST_FAILED (cmd: $COMMAND)" >> "$LOG_FILE"
  fi
fi

exit 0
