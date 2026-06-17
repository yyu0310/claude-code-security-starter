#!/bin/bash
# pre_push_safety.sh
# PreToolUse hook for Claude Code — scans git push for secrets before anything leaves.
# Exit 2 cancels the push; output is fed back to Claude as context.
#
# Install: cp this file to ~/.claude/hooks/ && chmod +x ~/.claude/hooks/pre_push_safety.sh
# Wire up:  see settings.example.json

# ── User config ───────────────────────────────────────────────────────────────
# Extra filename patterns to block in addition to the built-in list.
# Uses grep -E syntax. Leave empty if not needed.
EXTRA_SENSITIVE_PATTERN=""
# Example: EXTRA_SENSITIVE_PATTERN="|my-keys\.md|internal-only"
# ─────────────────────────────────────────────────────────────────────────────

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    print('')
" 2>/dev/null)

# Only intercept git push
echo "$COMMAND" | grep -qE "git push" || exit 0

echo "[pre-push] Running security scan..."

BRANCH=$(git branch --show-current 2>/dev/null)
REMOTE_REF="origin/$BRANCH"

if git rev-parse "$REMOTE_REF" >/dev/null 2>&1; then
  CHANGED_FILES=$(git diff "$REMOTE_REF"..HEAD --name-only 2>/dev/null)
  DIFF_CONTENT=$(git diff "$REMOTE_REF"..HEAD -- . 2>/dev/null)
else
  CHANGED_FILES=$(git diff HEAD~1..HEAD --name-only 2>/dev/null)
  DIFF_CONTENT=$(git diff HEAD~1..HEAD -- . 2>/dev/null)
fi

BLOCKED=0

# ── Sensitive filenames ───────────────────────────────────────────────────────
BASE_PATTERN='(\.env$|\.env\.|\.clasprc|credentials\.json|service-account\.json|secret)'
FULL_PATTERN="${BASE_PATTERN}${EXTRA_SENSITIVE_PATTERN}"

SENSITIVE_FILES=$(echo "$CHANGED_FILES" | grep -E "$FULL_PATTERN")
if [[ -n "$SENSITIVE_FILES" ]]; then
  echo "🚫 [pre-push] Sensitive files detected:"
  echo "$SENSITIVE_FILES" | sed 's/^/    /'
  BLOCKED=1
fi

# ── Secret patterns in diff content ──────────────────────────────────────────
SECRET_HITS=$(echo "$DIFF_CONTENT" | grep -E '^\+' | grep -vE '^\+\+\+' \
  | grep -vE '(EXAMPLE|PLACEHOLDER|YOUR_KEY_HERE|xxx|test123|changeme|<[^>]+>)' \
  | grep -E \
  '((?:A3T[A-Z0-9]|AKIA|ASIA|ABIA|ACCA)[A-Z2-7]{16}'\
'|AIza[\w-]{35}'\
'|sk-ant-(?:api03|admin01)-[a-zA-Z0-9_-]{93}AA'\
'|sk-(?:proj|svcacct|admin)-[A-Za-z0-9_-]{58,74}T3BlbkFJ'\
'|sk-[a-zA-Z0-9]{20}T3BlbkFJ[a-zA-Z0-9]{20}'\
'|ghp_[0-9a-zA-Z]{36}'\
'|github_pat_[A-Za-z0-9_]{82}'\
'|gho_[0-9a-zA-Z]{36}'\
'|ghu_[0-9a-zA-Z]{36}'\
'|ghs_[0-9a-zA-Z]{36}'\
'|glpat-[\w-]{20}'\
'|(?:sk|rk)_(?:test|live|prod)_[a-zA-Z0-9]{10,99}'\
'|SG\.[a-zA-Z0-9=_.-]{22}\.[a-zA-Z0-9=_.-]{43}'\
'|SK[0-9a-fA-F]{32}'\
'|xoxb-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*'\
'|xox[pe]-[0-9]{10,13}-[0-9]{10,13}-[a-zA-Z0-9-]{28,34}'\
'|hf_[a-zA-Z]{34}'\
'|pplx-[a-zA-Z0-9]{48}'\
'|r8_[a-zA-Z0-9]{40}'\
'|npm_[a-z0-9]{36}'\
'|[0-9]{5,16}:A[a-zA-Z0-9_-]{34}'\
'|hvs\.[\w-]{90,120}'\
'|-----BEGIN[ A-Z0-9_-]{0,100}PRIVATE KEY'\
'|mongodb(\+srv)?://[^:]+:[^@]+@'\
'|postgres(ql)?://[^:]+:[^@]+@'\
'|mysql://[^:]+:[^@]+@'\
'|https?://[^:]+:[^@]{8,}@'\
'|(?i)(?:api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token|private[_-]?key|client[_-]?secret|password|passwd)[[:space:]]*[=:][[:space:]]*[\"'"'"'][A-Za-z0-9+/=_\-]{16,}[\"'"'"']'\
')')

if [[ -n "$SECRET_HITS" ]]; then
  echo "🚫 [pre-push] Possible API key / token detected:"
  echo "$SECRET_HITS" | head -5 | sed 's/^/    /'
  BLOCKED=1
fi

if [[ $BLOCKED -eq 1 ]]; then
  echo ""
  echo "🚫 [pre-push] Push blocked — review the above before pushing manually"
  exit 2
fi

echo "✅ [pre-push] Scan passed"
exit 0
