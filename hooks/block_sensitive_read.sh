#!/bin/bash
# block_sensitive_read.sh
# PreToolUse hook for Claude Code — blocks the Read tool on sensitive files/paths.
# Exit 2 cancels the tool call; output is fed back to Claude as context.
#
# Install: cp this file to ~/.claude/hooks/ && chmod +x ~/.claude/hooks/block_sensitive_read.sh
# Wire up:  see settings.example.json

# ── User config ───────────────────────────────────────────────────────────────
# Directories: any file_path containing one of these strings will be blocked.
# Add your secrets folder here, e.g. "secrets" or "no-ai-read".
FORBIDDEN_DIRS=(
  # "secrets"
  # "no-ai-read"
)

# Exact basenames to block (files that don't match the patterns below).
FORBIDDEN_FILES=(
  # "my-api-keys.md"
)
# ─────────────────────────────────────────────────────────────────────────────

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    print('')
" 2>/dev/null)

[[ -z "$FILE_PATH" ]] && exit 0

BASENAME=$(basename "$FILE_PATH")
REASON=""

# User-configured forbidden directories
for dir in "${FORBIDDEN_DIRS[@]}"; do
  if [[ "$FILE_PATH" == *"$dir"* ]]; then
    REASON="Path is inside a forbidden directory ($dir) — refusing to avoid credential leak"
    break
  fi
done

# User-configured forbidden filenames
if [[ -z "$REASON" ]]; then
  for file in "${FORBIDDEN_FILES[@]}"; do
    if [[ "$BASENAME" == "$file" ]]; then
      REASON="Blocked by forbidden filename list: $BASENAME"
      break
    fi
  done
fi

# .env files
if [[ -z "$REASON" ]]; then
  if [[ "$BASENAME" == ".env" ]] || [[ "$BASENAME" == .env.* ]]; then
    REASON="Blocked: .env files must not be read — use Edit directly if you need to modify"
  fi
fi

# Google clasp credentials
if [[ -z "$REASON" ]]; then
  if [[ "$BASENAME" == .clasprc* ]]; then
    REASON="Blocked: .clasprc* contains OAuth tokens — reading would leak credentials"
  fi
fi

# Well-known credential filenames
if [[ -z "$REASON" ]]; then
  if [[ "$BASENAME" == "credentials.json" ]] || [[ "$BASENAME" == "service-account.json" ]]; then
    REASON="Blocked: $BASENAME is a known credential file"
  fi
fi

# Sensitive keywords in filename
if [[ -z "$REASON" ]]; then
  if [[ "$BASENAME" =~ (secret|credential|token|key) ]]; then
    REASON="Blocked: filename contains sensitive keyword ($BASENAME)"
  fi
fi

if [[ -n "$REASON" ]]; then
  echo "🚫 [block-read] $REASON"
  echo "🚫 [block-read] File contents will NOT be sent to Anthropic servers"
  exit 2
fi

exit 0
