#!/bin/bash
# SubagentStop Hook: サブエージェント完了時に結果をログに記録する

INPUT=$(cat)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOG_FILE="$PROJECT_DIR/.claude/sprint-log.md"
TODAY=$(date +%Y-%m-%d)
NOW=$(date +%H:%M)

AGENT_TYPE=$(echo "$INPUT" | jq -r '.agent_type // "unknown"' 2>/dev/null)
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // ""' 2>/dev/null)

mkdir -p "$(dirname "$LOG_FILE")"
echo "[$TODAY $NOW] AGENT_STOP $AGENT_TYPE ($AGENT_ID)" >> "$LOG_FILE"

exit 0
