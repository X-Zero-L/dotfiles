# dotfiles

[English](README.md)

Debian/Ubuntu 系统自动化配置脚本。

## 脚本说明

### `setup-shell.sh` — Shell 环境

安装 zsh、Oh My Zsh、插件（autosuggestions、syntax-highlighting、z）、Starship 提示符及 Catppuccin Powerline 主题。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

### `setup-clash.sh` — Clash 代理

安装 [clash-for-linux](https://github.com/nelvko/clash-for-linux-install)，支持传入订阅链接。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://你的订阅链接'
```

通过代理：

```bash
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
```

指定版本：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash -s -- 22
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `NODE_VERSION` | `24` | Node.js 主版本号（也可作为第一个参数传入） |

### `setup-uv.sh` — uv + Python

安装 [uv](https://docs.astral.sh/uv/) 包管理器，可选安装 Python 版本。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

同时安装 Python：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | UV_PYTHON=3.12 bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `UV_PYTHON` | _（空）_ | 要安装的 Python 版本（也可作为第一个参数传入） |

### `setup-claude-code.sh` — Claude Code

安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI 并配置 API。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://你的API地址 CLAUDE_API_KEY=你的密钥 bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://你的API地址 CLAUDE_API_KEY=你的密钥 bash
```

通过参数：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash -s -- --api-url https://你的API地址 --api-key 你的密钥
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLAUDE_API_URL` | _（必填）_ | API 基础地址 |
| `CLAUDE_API_KEY` | _（必填）_ | 认证令牌 |
| `CLAUDE_MODEL` | `opus` | 模型名称 |
| `CLAUDE_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

### `setup-codex.sh` — Codex CLI

安装 [Codex CLI](https://github.com/openai/codex) 并配置 API。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | CODEX_API_URL=https://你的API地址 CODEX_API_KEY=你的密钥 bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | CODEX_API_URL=https://你的API地址 CODEX_API_KEY=你的密钥 bash
```

通过参数：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash -s -- --api-url https://你的API地址 --api-key 你的密钥
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CODEX_API_URL` | _（必填）_ | API 基础地址 |
| `CODEX_API_KEY` | _（必填）_ | API 密钥 |
| `CODEX_MODEL` | `gpt-5.2` | 模型名称 |
| `CODEX_EFFORT` | `xhigh` | 推理强度 |
| `CODEX_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

## 完整安装

> 建议顺序：代理 → shell → uv → node → claude code / codex。

**1. 代理**（后续下载更快）

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://你的订阅链接'
```

```bash
source ~/.bashrc && clashon
```

**2. Shell 环境**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

**3. uv + Python**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | UV_PYTHON=3.12 bash
```

**4. Node.js**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

**5. Claude Code**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://你的API地址 CLAUDE_API_KEY=你的密钥 bash
```

**6. Codex CLI**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | CODEX_API_URL=https://你的API地址 CODEX_API_KEY=你的密钥 bash
```

## 注意事项

- 所有脚本均支持**重复运行**，已安装的组件会自动跳过。
- 需要 `sudo` 权限安装系统包。
- Starship 需要终端支持 [Nerd Font](https://www.nerdfonts.com/) 才能正常显示图标。
- 如果 `gh-proxy.org` 不可用，可到 [ghproxy.link](https://ghproxy.link/) 查找其他可用代理。
