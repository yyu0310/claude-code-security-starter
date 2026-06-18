# Claude Code Instructions

This repo is a security starter pack for Claude Code. When the user asks you to install it, follow the steps below — no need to ask for confirmation on each step.

## Trigger phrases

Any of: "install", "set this up", "apply this", "幫我安裝", "幫我設定" → run the full installation.

## Installation steps

**Step 1 — Copy hooks**

```bash
mkdir -p ~/.claude/hooks
cp hooks/block_sensitive_read.sh ~/.claude/hooks/
cp hooks/pre_push_safety.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/block_sensitive_read.sh
chmod +x ~/.claude/hooks/pre_push_safety.sh
```

**Step 2 — Configure forbidden directories**

Ask the user: "Where do you keep sensitive files like API keys? (e.g. `~/secrets/`)"

Then edit `~/.claude/hooks/block_sensitive_read.sh` and add their path to the `FORBIDDEN_DIRS` array near the top of the file.

**Step 3 — Merge hooks into settings.json**

Read `~/.claude/settings.json`. If it doesn't exist, treat it as `{}`.

Merge the `hooks` section from `settings.example.json` into it, preserving all existing keys. Write the result back to `~/.claude/settings.json`.

**Step 4 — Add CLAUDE.md rules to a project (optional)**

Ask: "Which project do you want to add the security rules to? (leave blank to skip)"

If the user names a project:
- If that project already has a `CLAUDE.md`, append the contents of `CLAUDE.md.template` to it.
- If not, copy `CLAUDE.md.template` to that project as `CLAUDE.md`.
- Then tell the user to replace the `<PLACEHOLDER>` values in the file.

## Verification

After installation, run:

```bash
ls -la ~/.claude/hooks/
```

Confirm `block_sensitive_read.sh` and `pre_push_safety.sh` are present and executable. Then tell the user what was installed and remind them to restart Claude Code for hooks to take effect.
