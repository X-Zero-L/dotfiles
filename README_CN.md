# dotfiles

[English](README.md)

Debian/Ubuntu 系统自动化配置脚本。

> 所有脚本均支持**重复运行** — 已安装的组件会自动跳过，配置变更时自动更新。需要 `curl`、`git` 和 `sudo`。

## 快速开始

使用 `install.sh` 进行一站式交互或非交互安装。

<p align="center">
  <img src="assets/demo.gif" alt="install.sh 演示" width="700">
</p>

交互式 TUI — 选择要安装的组件：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash
```

通过代理（推荐国内用户）：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --gh-proxy https://gh-proxy.org
```

非交互式安装全部：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --all
```

指定组件：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --components shell,node,docker
```

预配置 API 密钥：

```bash
export CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key
export CODEX_API_URL=https://your-api-url  CODEX_API_KEY=your-key
export GEMINI_API_URL=https://your-api-url GEMINI_API_KEY=your-key
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --all
```

详细模式（显示原始脚本输出而非 spinner）：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --all --verbose
```

可用组件：`shell`、`tmux`、`clash`、`node`、`uv`、`go`、`docker`、`tailscale`、`claude-code`、`codex`、`gemini`、`skills`

## 组件详解

每个脚本也可以单独运行，支持直连和代理两种方式：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/<script> | bash
```

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/<script> | bash
```

---

### 基础环境

#### Shell 环境 (`setup-shell.sh`)

安装 zsh、Oh My Zsh、插件（autosuggestions、syntax-highlighting、z）、Starship 提示符及 Catppuccin Powerline 主题。需要 `sudo`。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

#### Tmux (`setup-tmux.sh`)

安装 [tmux](https://github.com/tmux/tmux)、[TPM](https://github.com/tmux-plugins/tpm) 插件管理器、[Catppuccin](https://github.com/catppuccin/tmux) 主题及常用插件（sensible、vim-tmux-navigator、yank、resurrect、continuum）。需要 `sudo`。

默认配置（不修改键位）：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-tmux.sh | bash
```

启用自定义键位（Ctrl+a 前缀、`|` 和 `-` 分屏、vim 风格调整大小）：

```bash
export TMUX_KEYBINDS=1
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-tmux.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-tmux.sh | bash
```

配置项：`TMUX_KEYBINDS`、`TMUX_MOUSE`、`TMUX_STATUS_POS`、`GH_PROXY` — 详见[配置速查表](#配置速查表)。

#### Clash 代理 (`setup-clash.sh`)

安装 [clash-for-linux](https://github.com/nelvko/clash-for-linux-install)，支持传入订阅链接。

传入订阅链接：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
```

通过环境变量：

```bash
export CLASH_SUB_URL='https://your-subscription-url'
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
```

配置项：`CLASH_SUB_URL`、`CLASH_KERNEL`、`CLASH_GH_PROXY` — 详见[配置速查表](#配置速查表)。

#### Docker (`setup-docker.sh`)

安装 [Docker Engine](https://docs.docker.com/engine/install/)、Compose 插件，配置镜像加速、日志轮转、地址池和可选代理。需要 `sudo`。

默认配置（不含镜像加速，海外机器直接用）：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

自定义配置：

```bash
export DOCKER_MIRROR=https://mirror.example.com
export DOCKER_DATA_ROOT=/data/docker
export DOCKER_PROXY=http://localhost:7890
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

配置项：`DOCKER_MIRROR`、`DOCKER_PROXY`、`DOCKER_DATA_ROOT`、`DOCKER_LOG_SIZE` 等 — 详见[配置速查表](#配置速查表)。

#### Tailscale (`setup-tailscale.sh`)

安装 [Tailscale](https://tailscale.com/) VPN 组网。

仅安装：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-tailscale.sh | bash
```

安装并自动连接：

```bash
export TAILSCALE_AUTH_KEY=tskey-auth-xxxxx
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-tailscale.sh | bash
```

---

### 语言环境

#### Node.js (`setup-node.sh`)

安装 [nvm](https://github.com/nvm-sh/nvm) 和 Node.js。

默认安装 Node.js 24：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

指定版本：

```bash
export NODE_VERSION=22
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

#### uv + Python (`setup-uv.sh`)

安装 [uv](https://docs.astral.sh/uv/) 包管理器，可选安装 Python 版本。

仅安装 uv：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

uv + Python：

```bash
export UV_PYTHON=3.12
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

#### Go (`setup-go.sh`)

安装 [goenv](https://github.com/go-nv/goenv) 和 Go。

默认安装最新版 Go：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-go.sh | bash
```

指定版本：

```bash
export GO_VERSION=1.23.0
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-go.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-go.sh | GH_PROXY=https://gh-proxy.org bash
```

---

### AI 编码代理

三个代理脚本共享相同的行为模式：

- **有 API 密钥** → 安装工具 + 写入配置（已配置且一致则跳过）
- **无 API 密钥** → 仅安装工具，稍后手动配置
- **携带密钥重复运行** → 跳过安装，检查配置并按需更新

#### Claude Code (`setup-claude-code.sh`)

安装 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI。别名：`cc`。

安装 + 配置：

```bash
export CLAUDE_API_URL=https://your-api-url
export CLAUDE_API_KEY=your-key
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash
```

只安装不配置（稍后配置）：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash
```

通过命令行参数：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash
```

配置项：`CLAUDE_API_URL`、`CLAUDE_API_KEY`、`CLAUDE_MODEL`、`CLAUDE_NPM_MIRROR` — 详见[配置速查表](#配置速查表)。

#### Codex CLI (`setup-codex.sh`)

安装 [Codex CLI](https://github.com/openai/codex)。别名：`cx`。

安装 + 配置：

```bash
export CODEX_API_URL=https://your-api-url
export CODEX_API_KEY=your-key
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash
```

只安装不配置（稍后配置）：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash
```

通过命令行参数：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash
```

配置项：`CODEX_API_URL`、`CODEX_API_KEY`、`CODEX_MODEL`、`CODEX_EFFORT`、`CODEX_NPM_MIRROR` — 详见[配置速查表](#配置速查表)。

#### Gemini CLI (`setup-gemini.sh`)

安装 [Gemini CLI](https://github.com/google-gemini/gemini-cli)。别名：`gm`。

安装 + 配置：

```bash
export GEMINI_API_URL=https://your-api-url
export GEMINI_API_KEY=your-key
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash
```

只安装不配置（稍后配置）：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash
```

通过命令行参数：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash
```

配置项：`GEMINI_API_URL`、`GEMINI_API_KEY`、`GEMINI_MODEL`、`GEMINI_NPM_MIRROR` — 详见[配置速查表](#配置速查表)。

#### 代理技能 (`setup-skills.sh`)

为所有编码代理全局安装常用 [agent skills](https://skills.sh/)。

| 技能 | 来源 | 说明 |
|------|------|------|
| `find-skills` | [vercel-labs/skills](https://github.com/vercel-labs/skills) | 发现和安装代理技能 |
| `pdf` | [anthropics/skills](https://github.com/anthropics/skills) | PDF 读取和处理 |
| `gemini-cli-skill` | [X-Zero-L/gemini-cli-skill](https://github.com/X-Zero-L/gemini-cli-skill) | Gemini CLI 集成 |
| `context7` | [intellectronica/agent-skills](https://github.com/intellectronica/agent-skills) | 库文档查询 |
| `writing-plans` | [obra/superpowers](https://github.com/obra/superpowers) | 编写实现计划 |
| `executing-plans` | [obra/superpowers](https://github.com/obra/superpowers) | 带检查点的计划执行 |
| `codex` | [softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit) | Codex 代理技能 |

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-skills.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-skills.sh | bash
```

配置项：`SKILLS_NPM_MIRROR` — 详见[配置速查表](#配置速查表)。

## 配置速查表

所有脚本的环境变量汇总。

### 通用

| 变量 | 作用域 | 默认值 | 说明 |
|------|--------|--------|------|
| `GH_PROXY` | `install.sh` | _（空）_ | GitHub 代理地址，用于加速脚本下载 |

### Tmux

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TMUX_KEYBINDS` | `0` | 启用自定义键位：Ctrl+a 前缀、\| 和 - 分屏、vim 风格调整大小（设为 `1` 启用） |
| `TMUX_MOUSE` | `1` | 启用鼠标支持（设为 `0` 禁用） |
| `TMUX_STATUS_POS` | `top` | 状态栏位置（`top` 或 `bottom`） |

### Clash

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLASH_SUB_URL` | _（空）_ | 订阅链接（也可作为第一个参数传入） |
| `CLASH_KERNEL` | `mihomo` | 代理内核（`mihomo` 或 `clash`） |
| `CLASH_GH_PROXY` | `https://gh-proxy.org` | GitHub 加速代理（设为空字符串可禁用） |

### Node.js

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `NODE_VERSION` | `24` | Node.js 主版本号（也可作为第一个参数传入） |

### uv + Python

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `UV_PYTHON` | _（空）_ | 要安装的 Python 版本（也可作为第一个参数传入） |

### Go

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GO_VERSION` | `latest` | 要安装的 Go 版本（也可作为第一个参数传入） |

### Docker

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DOCKER_MIRROR` | _（空）_ | 镜像加速地址，多个用逗号分隔。通过 `install.sh` 的 `--gh-proxy` 安装时自动设为 `https://docker.1ms.run` |
| `DOCKER_PROXY` | _（空）_ | 守护进程和容器的 HTTP/HTTPS 代理 |
| `DOCKER_NO_PROXY` | `localhost,127.0.0.0/8` | 不走代理的地址列表 |
| `DOCKER_DATA_ROOT` | _（空）_ | Docker 数据存储目录（默认 `/var/lib/docker`） |
| `DOCKER_LOG_SIZE` | `20m` | 单个日志文件最大大小 |
| `DOCKER_LOG_FILES` | `3` | 最多保留日志文件数 |
| `DOCKER_EXPERIMENTAL` | `1` | 启用实验性功能（设为 `0` 禁用） |
| `DOCKER_ADDR_POOLS` | `172.17.0.0/12:24,192.168.0.0/16:24` | 默认地址池（`base/cidr:size`，逗号分隔） |
| `DOCKER_COMPOSE` | `1` | 安装 docker-compose-plugin（设为 `0` 跳过） |

### Tailscale

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TAILSCALE_AUTH_KEY` | _（空）_ | 自动连接的 Auth Key。留空则仅安装。 |

### Claude Code

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLAUDE_API_URL` | _（空）_ | API 基础地址（留空则只安装不配置） |
| `CLAUDE_API_KEY` | _（空）_ | 认证令牌（留空则只安装不配置） |
| `CLAUDE_MODEL` | `opus` | 模型名称 |
| `CLAUDE_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

### Codex CLI

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CODEX_API_URL` | _（空）_ | API 基础地址（留空则只安装不配置） |
| `CODEX_API_KEY` | _（空）_ | API 密钥（留空则只安装不配置） |
| `CODEX_MODEL` | `gpt-5.2` | 模型名称 |
| `CODEX_EFFORT` | `xhigh` | 推理强度 |
| `CODEX_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

### Gemini CLI

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GEMINI_API_URL` | _（空）_ | API 基础地址（留空则只安装不配置） |
| `GEMINI_API_KEY` | _（空）_ | API 密钥（留空则只安装不配置） |
| `GEMINI_MODEL` | `gemini-3-pro-preview` | 模型名称 |
| `GEMINI_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

### 代理技能

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SKILLS_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

## 从零开始

全新机器的完整配置流程。推荐顺序确保依赖关系正确。

**1. 代理**（后续下载更快）

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
```

```bash
source ~/.bashrc && clashon
```

**2. 准备 API 密钥**（可选 — 省略则只安装工具不配置）

```bash
export CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key
export CODEX_API_URL=https://your-api-url  CODEX_API_KEY=your-key
export GEMINI_API_URL=https://your-api-url GEMINI_API_KEY=your-key
```

**3. 一键安装**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --all
```

或按以下顺序逐个安装：

1. `setup-shell.sh` — Shell 环境（zsh、插件、Starship）
2. `setup-tmux.sh` — Tmux + Catppuccin + 插件
3. `setup-docker.sh` — Docker Engine + Compose
4. `setup-tailscale.sh` — Tailscale VPN
5. `setup-uv.sh` — uv + Python
6. `setup-go.sh` — goenv + Go
7. `setup-node.sh` — nvm + Node.js
8. `setup-claude-code.sh` — Claude Code
9. `setup-codex.sh` — Codex CLI
10. `setup-gemini.sh` — Gemini CLI
11. `setup-skills.sh` — 代理技能

## 详细文档

查看 [docs/zh/](docs/zh/) 目录获取每个脚本的详细文档 — 安装内容、创建/修改的文件、重复运行行为等。

## 注意事项

- Starship 需要终端支持 [Nerd Font](https://www.nerdfonts.com/) 才能正常显示图标。
- 如果 `gh-proxy.org` 不可用，可到 [ghproxy.link](https://ghproxy.link/) 查找其他可用代理。
- 携带不同的 API 密钥/配置重新运行脚本，会自动更新配置而不重复安装。
