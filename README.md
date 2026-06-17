# claude-code-security-starter

English | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md)

A security starter pack for Claude Code beginners — CLAUDE.md rules + pre-built hooks that prevent credential leaks before they happen.

## Why

Claude Code sends file contents to Anthropic servers whenever it reads a file. By default there are no guardrails — nothing stops it from reading your `.env`, `.clasprc.json`, or any file with "secret" in the name if you (or Claude) accidentally ask it to.

This pack closes those gaps with:

1. **`CLAUDE.md` rules** — instructions that tell Claude _what not to touch_, including Bash-based workarounds (because `cat .env` leaks just as much as `Read .env`)
2. **`block_sensitive_read` hook** — a hard OS-level block on the Read tool before Claude can even try
3. **`pre_push_safety` hook** — scans every `git push` for 25+ API key patterns before anything leaves your machine

## Quick Start

This repo ships with a `CLAUDE.md` that tells Claude Code how to install everything. The easiest way:

```bash
git clone https://github.com/<YOUR_USERNAME>/claude-code-security-starter
cd claude-code-security-starter
claude  # open Claude Code in this directory
```

Then just say: **"幫我安裝" or "install this"** — Claude will copy the hooks, configure your forbidden directories, and merge the settings for you.

### Manual install (without AI)

```bash
# 1. Copy hooks
mkdir -p ~/.claude/hooks
cp hooks/block_sensitive_read.sh ~/.claude/hooks/
cp hooks/pre_push_safety.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# 2. Edit your forbidden directories
nano ~/.claude/hooks/block_sensitive_read.sh   # fill in FORBIDDEN_DIRS

# 3. Merge settings.example.json into ~/.claude/settings.json

# 4. Copy and adapt the CLAUDE.md template to your project
cp CLAUDE.md.template /path/to/your/project/CLAUDE.md
# Replace all <PLACEHOLDER> values
```

## Files

| File | Purpose |
|------|---------|
| `CLAUDE.md.template` | Security rules to paste into your project's `CLAUDE.md` |
| `hooks/block_sensitive_read.sh` | Blocks the Read tool on `.env`, credentials, and your custom forbidden paths |
| `hooks/pre_push_safety.sh` | Scans `git push` for 25+ API key / token regex patterns |
| `settings.example.json` | Claude Code hook wiring (merge into `settings.json`) |

## What Gets Blocked

### block_sensitive_read.sh

- Any path you add to `FORBIDDEN_DIRS` (e.g. your `~/secrets/` folder)
- Any filename you add to `FORBIDDEN_FILES`
- `.env` and `.env.*`
- `.clasprc*` (Google clasp OAuth tokens)
- `credentials.json`, `service-account.json`
- Any filename containing `secret`, `credential`, `token`, or `key`

### pre_push_safety.sh

Regex patterns for: AWS, Google API, Anthropic, OpenAI, GitHub, GitLab, Stripe, SendGrid, Twilio, Slack, HuggingFace, Perplexity, Replicate, npm, Telegram Bot, HashiCorp Vault, PEM private keys, database connection strings (MongoDB, PostgreSQL, MySQL), and generic `api_key = "..."` patterns.

## How Hooks Work

Claude Code hooks are shell scripts that run at defined lifecycle events. A hook that exits with code `2` **blocks** the tool call and feeds the output back to Claude as context.

```
PreToolUse → hook runs → exit 2 → tool call cancelled
                       → exit 0 → tool call proceeds normally
```

More on hooks: https://code.claude.com/docs/hooks

## License

MIT
