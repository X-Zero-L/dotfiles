# 文档

[English](../README.md)

每个脚本的详细文档。快速上手请查看[主 README](../../README_CN.md)。

## 操作系统兼容性

所有脚本自动检测操作系统并使用适当的包管理器：

| 组件 | Debian/Ubuntu | CentOS/RHEL | Fedora | Arch Linux | macOS |
|------|---------------|-------------|--------|------------|-------|
| Shell (zsh, Oh My Zsh, Starship) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Tmux | ✓ | ✓ | ✓ | ✓ | ✓ |
| Git | ✓ | ✓ | ✓ | ✓ | ✓ |
| 基础工具 | ✓ | ✓ | ✓ | ✓ | ✓ |
| Clash 代理 | ✓ | ✓ | ✓ | ✓ | ✗ (仅限 Linux) |
| Docker | ✓ (Engine) | ✓ (Engine) | ✓ (Engine) | ✓ (Engine) | ✓ (Desktop) |
| Tailscale | ✓ | ✓ | ✓ | ✓ | ✓ |
| SSH | ✓ | ✓ | ✓ | ✓ | ✓ (Remote Login) |
| Node.js (nvm) | ✓ | ✓ | ✓ | ✓ | ✓ |
| uv + Python | ✓ | ✓ | ✓ | ✓ | ✓ |
| Go (goenv) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Claude Code | ✓ | ✓ | ✓ | ✓ | ✓ |
| Codex CLI | ✓ | ✓ | ✓ | ✓ | ✓ |
| Gemini CLI | ✓ | ✓ | ✓ | ✓ | ✓ |
| 代理技能 | ✓ | ✓ | ✓ | ✓ | ✓ |

**注意事项：**
- macOS 上的 Docker 使用 Docker Desktop（通过 Homebrew 安装）而非 Docker Engine
- macOS 上的 SSH 配置 Remote Login 而非通过 systemd 配置 OpenSSH 服务器
- Clash 代理仅支持 Linux 系统

## 脚本列表

### 基础环境

| 脚本 | 说明 |
|------|------|
| [install.sh](install.md) | 一站式交互/非交互安装器 |
| [setup-shell.sh](setup-shell.md) | zsh + Oh My Zsh + 插件 + Starship |
| [setup-tmux.sh](setup-tmux.md) | tmux + TPM + Catppuccin + 鼠标增强 |
| [setup-git.sh](setup-git.md) | Git 用户身份 + 合理默认值 |
| [setup-clash.sh](setup-clash.md) | Clash 代理 + 订阅管理 |
| [setup-docker.sh](setup-docker.md) | Docker Engine + Compose + 守护进程配置 |
| [setup-tailscale.sh](setup-tailscale.md) | Tailscale VPN 组网 |
| [setup-ssh.sh](setup-ssh.md) | SSH 端口 + 密钥登录 |

### 语言环境

| 脚本 | 说明 |
|------|------|
| [setup-node.sh](setup-node.md) | nvm + Node.js |
| [setup-uv.sh](setup-uv.md) | uv 包管理器 + Python |
| [setup-go.sh](setup-go.md) | goenv + Go |

### AI 编码代理

| 脚本 | 说明 |
|------|------|
| [setup-claude-code.sh](setup-claude-code.md) | Claude Code CLI + API 配置 |
| [setup-codex.sh](setup-codex.md) | OpenAI Codex CLI + API 配置 |
| [setup-gemini.sh](setup-gemini.md) | Google Gemini CLI + API 配置 |
| [setup-skills.sh](setup-skills.md) | 所有编码代理的通用技能 |

### 管理工具

| 脚本 | 说明 |
|------|------|
| [rig](rig-management.md) | CLI 包装器 — 预设、状态、导出/导入、卸载 |
| [update.sh](setup-update.md) | 更新已安装组件 |
| [status.sh](rig-management.md#rig-status) | 显示已安装组件和版本 |
| [export-config.sh](rig-management.md#rig-export) | 导出配置为 JSON + 密钥文件 |
| [import-config.sh](rig-management.md#rig-import) | 从导出文件导入配置 |
| [uninstall.sh](rig-management.md#rig-uninstall) | 安全卸载组件 |

## 设计原则

所有脚本遵循以下约定：

- **幂等** — 可安全重复运行。已安装的组件自动跳过，变更的配置自动更新。
- **独立** — 每个脚本可通过 `curl | bash` 独立运行。
- **可配置** — 通过环境变量或命令行参数控制行为。
- **安全** — API 密钥通过环境变量传递（非命令行参数），配置文件权限设为 `chmod 600`。
- **快速失败** — `set -euo pipefail` 尽早捕获错误。
