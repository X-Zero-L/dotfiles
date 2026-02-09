# 文档

每个脚本的详细文档。快速上手请查看[主 README](../../README_CN.md)。

## 脚本列表

### 基础环境

| 脚本 | 说明 |
|------|------|
| [install.sh](install.md) | 一站式交互/非交互安装器 |
| [setup-shell.sh](setup-shell.md) | zsh + Oh My Zsh + 插件 + Starship |
| [setup-tmux.sh](setup-tmux.md) | tmux + TPM + Catppuccin + 鼠标增强 |
| [setup-clash.sh](setup-clash.md) | Clash 代理 + 订阅管理 |
| [setup-docker.sh](setup-docker.md) | Docker Engine + Compose + 守护进程配置 |

### 语言环境

| 脚本 | 说明 |
|------|------|
| [setup-node.sh](setup-node.md) | nvm + Node.js |
| [setup-uv.sh](setup-uv.md) | uv 包管理器 + Python |

### AI 编码代理

| 脚本 | 说明 |
|------|------|
| [setup-claude-code.sh](setup-claude-code.md) | Claude Code CLI + API 配置 |
| [setup-codex.sh](setup-codex.md) | OpenAI Codex CLI + API 配置 |
| [setup-gemini.sh](setup-gemini.md) | Google Gemini CLI + API 配置 |
| [setup-skills.sh](setup-skills.md) | 所有编码代理的通用技能 |

## 设计原则

所有脚本遵循以下约定：

- **幂等** — 可安全重复运行。已安装的组件自动跳过，变更的配置自动更新。
- **独立** — 每个脚本可通过 `curl | bash` 独立运行。
- **可配置** — 通过环境变量或命令行参数控制行为。
- **安全** — API 密钥通过环境变量传递（非命令行参数），配置文件权限设为 `chmod 600`。
- **快速失败** — `set -euo pipefail` 尽早捕获错误。
