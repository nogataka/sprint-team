#!/bin/bash
# PostToolUse Hook: ファイル編集後に自動で lint・型チェックを実行する

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // ""' 2>/dev/null)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# ファイルパスがなければスキップ
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 絶対パスに変換
if [[ "$FILE_PATH" != /* ]]; then
  FILE_PATH="$PROJECT_DIR/$FILE_PATH"
fi

# ファイルが存在しなければスキップ
if [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# node_modules が存在しなければ lint/format をスキップ
if [ ! -d "$PROJECT_DIR/node_modules" ]; then
  # マイグレーション検知のみ実行して終了
  if [[ "$FILE_PATH" == */migrations/*.sql ]]; then
    jq -n '{
      transcript: "SQL マイグレーション検知: バックアップを取ってから `pnpm db:migrate` を実行してください。"
    }'
  fi
  exit 0
fi

ERRORS=""
HAS_ERROR=0

# ===== TypeScript / TSX =====
if [[ "$FILE_PATH" == *.ts || "$FILE_PATH" == *.tsx ]]; then

  # ESLint（自動修正付き）— eslint がインストール済みの場合のみ
  if [ -f "$PROJECT_DIR/node_modules/.bin/eslint" ]; then
    LINT_RESULT=$(cd "$PROJECT_DIR" && npx eslint --fix "$FILE_PATH" 2>&1)
    LINT_EXIT=$?
    if [ $LINT_EXIT -ne 0 ]; then
      ERRORS+="### ESLint エラー\n\`\`\`\n$LINT_RESULT\n\`\`\`\n"
      HAS_ERROR=1
    fi
  fi

  # Prettier（自動フォーマット）— prettier がインストール済みの場合のみ
  if [ -f "$PROJECT_DIR/node_modules/.bin/prettier" ]; then
    npx prettier --write "$FILE_PATH" > /dev/null 2>&1 || true
  fi

fi

# ===== CSS / SCSS =====
if [[ "$FILE_PATH" == *.css || "$FILE_PATH" == *.scss ]]; then
  if [ -f "$PROJECT_DIR/node_modules/.bin/prettier" ]; then
    npx prettier --write "$FILE_PATH" > /dev/null 2>&1 || true
  fi
fi

# ===== SQL（マイグレーション）=====
if [[ "$FILE_PATH" == */migrations/*.sql ]]; then
  ERRORS+="### :warning: SQL マイグレーション検知\n"
  ERRORS+="バックアップを取ってから \`pnpm db:migrate\` を実行してください。\n"
fi

# ===== エラーレポートを Claude にフィードバック =====
if [ $HAS_ERROR -eq 1 ]; then
  jq -n \
    --arg msg "$(echo -e "$ERRORS")" \
    '{
      hookSpecificOutput: {
        hookEventName: "PostToolUse"
      },
      transcript: ("⚠️ 品質チェックで問題が検出されました:\n" + $msg)
    }'
fi

exit 0
