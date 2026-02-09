# dotfiles

[English](README.md)

Debian/Ubuntu 系统自动化配置脚本。

## 脚本说明

### `setup-shell.sh` — Shell 环境

安装 zsh、Oh My Zsh、插件（autosuggestions、syntax-highlighting、z）、Starship 提示符及 Catppuccin Powerline 主题。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash

# 通过代理
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

### `setup-clash.sh` — Clash 代理

安装 [clash-for-linux](https://github.com/nelvko/clash-for-linux-install)，支持传入订阅链接。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://你的订阅链接'

# 通过代理
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://你的订阅链接'
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLASH_SUB_URL` | _（空）_ | 订阅链接（也可作为第一个参数传入） |
| `CLASH_KERNEL` | `mihomo` | 代理内核（`mihomo` 或 `clash`） |
| `CLASH_GH_PROXY` | `https://gh-proxy.org` | GitHub 加速代理（设为空字符串可禁用） |

### `setup-node.sh` — Node.js（通过 nvm）

安装 [nvm](https://github.com/nvm-sh/nvm) 和 Node.js。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash

# 指定版本
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash -s -- 22

# 通过代理
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `NODE_VERSION` | `24` | Node.js 主版本号（也可作为第一个参数传入） |

### `setup-claude-code.sh` — Claude Code

安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI 并配置 API。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://你的API地址 CLAUDE_API_KEY=你的密钥 bash

# 通过代理
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://你的API地址 CLAUDE_API_KEY=你的密钥 bash

# 或通过参数
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash -s -- --api-url https://你的API地址 --api-key 你的密钥
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLAUDE_API_URL` | _（必填）_ | API 基础地址 |
| `CLAUDE_API_KEY` | _（必填）_ | 认证令牌 |
| `CLAUDE_MODEL` | `opus` | 模型名称 |
| `CLAUDE_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

## 完整安装

> 建议顺序：代理 → shell → node → claude code。

```bash
# 1. 先配代理（后续下载更快）
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://你的订阅链接'
source ~/.bashrc && clashon

# 2. Shell 环境
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash

# 3. Node.js
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash

# 4. Claude Code
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://你的API地址 CLAUDE_API_KEY=你的密钥 bash
```

## 注意事项

- 所有脚本均支持**重复运行**，已安装的组件会自动跳过。
- 需要 `sudo` 权限安装系统包。
- Starship 需要终端支持 [Nerd Font](https://www.nerdfonts.com/) 才能正常显示图标。
- 如果 `gh-proxy.org` 不可用，可到 [ghproxy.link](https://ghproxy.link/) 查找其他可用代理。
