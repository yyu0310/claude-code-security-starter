# claude-code-security-starter

[English](README.md) | [繁體中文](README.zh-TW.md) | 简体中文

Claude Code 新手安全配置包。CLAUDE.md 规则 + 预构建 hooks，在凭据泄露前就拦截。

## 为什么需要这个

Claude Code 每次读取文件，内容都会发送到 Anthropic 服务器。默认没有任何防护，只要你（或 Claude）不小心请求，它就会去读你的 `.env`、`.clasprc.json`，或任何文件名含 "secret" 的文件。

这个 starter pack 从两个层面堵死这个漏洞：

1. **`CLAUDE.md` 规则** — 告诉 Claude 哪些东西不能碰，包括用 Bash 绕过的方式（`cat .env` 和 `Read .env` 同样会泄露）
2. **`block_sensitive_read` hook** — 在 Claude 尝试读取前，OS 层直接拦截
3. **`pre_push_safety` hook** — 每次 `git push` 前扫描 25+ 种 API key 格式，确保没有凭据进 repo

## 快速开始

这个 repo 内置 `CLAUDE.md`，让 Claude Code 知道如何安装。最简单的方式：

```bash
git clone https://github.com/<YOUR_USERNAME>/claude-code-security-starter
cd claude-code-security-starter
claude  # 用 Claude Code 打开这个目录
```

然后说：**「帮我安装」** — Claude 会自动复制 hooks、配置禁读目录、合并 settings。

### 手动安装

```bash
# 1. 复制 hooks
mkdir -p ~/.claude/hooks
cp hooks/block_sensitive_read.sh ~/.claude/hooks/
cp hooks/pre_push_safety.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# 2. 配置禁读目录
nano ~/.claude/hooks/block_sensitive_read.sh   # 填入 FORBIDDEN_DIRS

# 3. 将 settings.example.json 的 hooks 区段合并进 ~/.claude/settings.json

# 4. 复制 CLAUDE.md 规则到你的项目
cp CLAUDE.md.template /path/to/your/project/CLAUDE.md
# 替换所有 <PLACEHOLDER>
```

## 文件说明

| 文件 | 用途 |
|------|------|
| `CLAUDE.md.template` | 贴进你项目 `CLAUDE.md` 的安全规则 |
| `hooks/block_sensitive_read.sh` | 拦截 Read 工具读取 `.env`、凭据、自定义禁读路径 |
| `hooks/pre_push_safety.sh` | `git push` 前扫描 25+ 种 API key / token 格式 |
| `settings.example.json` | Hook 接线配置（合并进 `settings.json`） |

## 拦截范围

### block_sensitive_read.sh

- 你加进 `FORBIDDEN_DIRS` 的任何目录（如 `~/secrets/`）
- 你加进 `FORBIDDEN_FILES` 的特定文件名
- `.env` 和 `.env.*`
- `.clasprc*`（Google clasp OAuth token）
- `credentials.json`、`service-account.json`
- 任何文件名含有 `secret`、`credential`、`token`、`key` 的文件

### pre_push_safety.sh

扫描格式涵盖：AWS、Google API、Anthropic、OpenAI、GitHub、GitLab、Stripe、SendGrid、Twilio、Slack、HuggingFace、Perplexity、Replicate、npm、Telegram Bot、HashiCorp Vault、PEM 私钥、数据库连接字符串（MongoDB、PostgreSQL、MySQL），以及通用 `api_key = "..."` 格式。

## Hook 运作原理

Claude Code hooks 是在特定生命周期事件执行的 shell script。Hook 返回 exit code `2` 会**取消**工具调用，并把输出送回给 Claude 作为上下文。

```
PreToolUse → hook 执行 → exit 2 → 工具调用取消
                       → exit 0 → 工具调用正常执行
```

更多说明：https://code.claude.com/docs/hooks

## License

MIT
