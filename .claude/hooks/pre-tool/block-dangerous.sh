#!/bin/bash
# PreToolUse Hook: 危険なコマンドをブロックする（Bash ツール対象）

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Bash 以外はスルー
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# ===== ブロックルール =====

# 1. rm -rf の禁止
if echo "$COMMAND" | grep -qE 'rm\s+-[a-zA-Z]*r[a-zA-Z]*f|rm\s+-[a-zA-Z]*f[a-zA-Z]*r'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "🛑 rm -rf は禁止されています。個別ファイルの削除には rm を使用してください。"
    }
  }'
  exit 0
fi

# 2. force push の禁止
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*--force|git\s+push\s+.*-f\b'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "🛑 git push --force は禁止されています。--force-with-lease も使用しないでください。"
    }
  }'
  exit 0
fi

# 3. main への直接 push の禁止
if echo "$COMMAND" | grep -qE 'git\s+push\s+.*\s+main|git\s+push\s+origin\s+main'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "🛑 main ブランチへの直接 push は禁止されています。PR を作成してください。"
    }
  }'
  exit 0
fi

# 4. .env ファイルへのアクセス禁止
if echo "$COMMAND" | grep -qE '(cat|echo|print|less|more|head|tail)\s+.*\.env|\.env\s*>'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "🛑 .env ファイルの読み書きは禁止されています。環境変数は process.env 経由で使用してください。"
    }
  }'
  exit 0
fi

# 5. シークレット・トークンを含む可能性のあるコマンドの警告
if echo "$COMMAND" | grep -qiE '(password|secret|token|api.?key|private.?key)\s*=\s*["\x27][^"\x27]+["\x27]'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "🛑 シークレット情報をコマンドに直接含めることは禁止されています。環境変数を使用してください。"
    }
  }'
  exit 0
fi

# 6. sudo の禁止
if echo "$COMMAND" | grep -qE '^\s*sudo\s+'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "🛑 sudo コマンドは禁止されています。"
    }
  }'
  exit 0
fi

# 7. 本番 DB への直接アクセス警告（PROD / PRODUCTION を含む接続文字列）
if echo "$COMMAND" | grep -qiE '(psql|mysql|supabase)\s+.*prod(uction)?'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "🛑 本番データベースへの直接アクセスは禁止されています。ローカル環境または Supabase ダッシュボードを使用してください。"
    }
  }'
  exit 0
fi

# すべてのチェックをパス → 許可
exit 0
