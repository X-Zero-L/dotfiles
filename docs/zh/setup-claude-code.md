# setup-claude-code.sh

安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI，可选配置 API 凭据。别名：`cc`。

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| Claude Code | `npm install -g @anthropic-ai/claude-code` | Anthropic 编码代理 CLI |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/4 | 通过 npm 全局安装 Claude Code（`claude` 命令存在则跳过） |
| 2/4 | 在 `~/.claude.json` 中设置 `hasCompletedOnboarding: true`（跳过交互式引导） |
| 3/4 | 如提供 API 密钥：写入 `~/.claude/settings.json`，包含 API URL、密钥和模型。使用 Node.js 解析并比较 JSON — 仅在配置不同时写入。 |
| 4/4 | 在 `~/.bashrc` 和 `~/.zshrc` 中添加 `alias cc='claude --dangerously-skip-permissions'` |

### 安全性

API 密钥通过环境变量（`_CLAUDE_URL`、`_CLAUDE_KEY`、`_CLAUDE_MODEL`）传递给 Node.js 配置写入器，而非命令行参数，因此在 `ps aux` 中不可见。

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `~/.claude.json` | 引导标记（`hasCompletedOnboarding: true`） |
| `~/.claude/settings.json` | API 配置（仅提供密钥时） |
| `~/.bashrc` | 添加别名 `cc` |
| `~/.zshrc` | 添加别名 `cc` |

### settings.json 结构

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://your-api-url",
    "ANTHROPIC_AUTH_TOKEN": "your-key",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "permissions": { "allow": [], "deny": [] },
  "alwaysThinkingEnabled": true,
  "model": "opus"
}
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLAUDE_API_URL` | _（空）_ | API 基础地址（留空则只安装不配置） |
| `CLAUDE_API_KEY` | _（空）_ | 认证令牌（留空则只安装不配置） |
| `CLAUDE_MODEL` | `opus` | 模型名称 |
| `CLAUDE_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

## 重复运行行为

- 安装：`claude` 命令存在则跳过。
- 引导：`hasCompletedOnboarding` 已为 `true` 则跳过。
- 配置：Node.js 比较全部三个字段（URL、密钥、模型）。仅在任一字段不同时写入。
- 别名：rc 文件中已存在则跳过。

## 依赖

- Node.js（先运行 `setup-node.sh`）。

## 安装后

```bash
source ~/.zshrc    # 加载别名
cc                 # 启动 Claude Code（带 --dangerously-skip-permissions）
claude             # 启动 Claude Code（标准模式）
```
