# claude-code-security-starter

[English](README.md) | 繁體中文 | [简体中文](README.zh-CN.md)

Claude Code 新手資安設定包。CLAUDE.md 規則 + 預建 hooks，在憑證外洩前就擋下來。

## 為什麼需要這個

Claude Code 每次讀取檔案，內容都會送到 Anthropic 伺服器。預設沒有任何防護，只要你（或 Claude）不小心問到，它就會去讀你的 `.env`、`.clasprc.json`，或任何檔名含 "secret" 的檔案。

這個 starter pack 從兩個層面堵死這個漏洞：

1. **`CLAUDE.md` 規則** — 告訴 Claude 哪些東西不能碰，包括用 Bash 繞過的方式（`cat .env` 和 `Read .env` 一樣會洩漏）
2. **`block_sensitive_read` hook** — 在 Claude 嘗試讀取前，OS 層直接攔截
3. **`pre_push_safety` hook** — 每次 `git push` 前掃描 25+ 種 API key 格式，確保沒有憑證進 repo

## 快速開始

這個 repo 內建 `CLAUDE.md`，讓 Claude Code 知道怎麼安裝。最簡單的方式：

```bash
git clone https://github.com/<YOUR_USERNAME>/claude-code-security-starter
cd claude-code-security-starter
claude  # 用 Claude Code 開啟這個目錄
```

然後說：**「幫我安裝」** — Claude 會自動複製 hooks、設定禁讀目錄、合併 settings。

### 手動安裝

```bash
# 1. 複製 hooks
mkdir -p ~/.claude/hooks
cp hooks/block_sensitive_read.sh ~/.claude/hooks/
cp hooks/pre_push_safety.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# 2. 設定你的禁讀目錄
nano ~/.claude/hooks/block_sensitive_read.sh   # 填入 FORBIDDEN_DIRS

# 3. 將 settings.example.json 的 hooks 區段合併進 ~/.claude/settings.json

# 4. 複製 CLAUDE.md 規則到你的專案
cp CLAUDE.md.template /path/to/your/project/CLAUDE.md
# 替換所有 <PLACEHOLDER>
```

## 檔案說明

| 檔案 | 用途 |
|------|------|
| `CLAUDE.md.template` | 貼進你專案 `CLAUDE.md` 的資安規則 |
| `hooks/block_sensitive_read.sh` | 攔截 Read 工具讀取 `.env`、憑證、自訂禁讀路徑 |
| `hooks/pre_push_safety.sh` | `git push` 前掃描 25+ 種 API key / token 格式 |
| `settings.example.json` | Hook 接線設定（合併進 `settings.json`） |

## 攔截範圍

### block_sensitive_read.sh

- 你加進 `FORBIDDEN_DIRS` 的任何目錄（如 `~/secrets/`）
- 你加進 `FORBIDDEN_FILES` 的特定檔名
- `.env` 和 `.env.*`
- `.clasprc*`（Google clasp OAuth token）
- `credentials.json`、`service-account.json`
- 任何檔名含有 `secret`、`credential`、`token`、`key` 的檔案

### pre_push_safety.sh

掃描格式涵蓋：AWS、Google API、Anthropic、OpenAI、GitHub、GitLab、Stripe、SendGrid、Twilio、Slack、HuggingFace、Perplexity、Replicate、npm、Telegram Bot、HashiCorp Vault、PEM 私鑰、資料庫連線字串（MongoDB、PostgreSQL、MySQL），以及通用 `api_key = "..."` 格式。

## Hook 運作原理

Claude Code hooks 是在特定生命週期事件執行的 shell script。Hook 回傳 exit code `2` 會**取消**工具呼叫，並把輸出送回給 Claude 作為上下文。

```
PreToolUse → hook 執行 → exit 2 → 工具呼叫取消
                       → exit 0 → 工具呼叫正常執行
```

更多說明：https://code.claude.com/docs/hooks

## License

MIT
