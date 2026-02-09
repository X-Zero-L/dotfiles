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

### `setup-gemini.sh` — Gemini CLI

安装 [Gemini CLI](https://github.com/google-gemini/gemini-cli) 并配置 API。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | GEMINI_API_URL=https://你的API地址 GEMINI_API_KEY=你的密钥 bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | GEMINI_API_URL=https://你的API地址 GEMINI_API_KEY=你的密钥 bash
```

通过参数：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash -s -- --api-url https://你的API地址 --api-key 你的密钥
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GEMINI_API_URL` | _（必填）_ | API 基础地址 |
| `GEMINI_API_KEY` | _（必填）_ | API 密钥 |
| `GEMINI_MODEL` | `gemini-3-pro-preview` | 模型名称 |
| `GEMINI_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

### `setup-docker.sh` — Docker

安装 [Docker Engine](https://docs.docker.com/engine/install/)、Docker Compose 插件，配置镜像加速和可选代理。

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

通过代理：

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

自定义镜像：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | DOCKER_MIRROR=https://mirror.example.com bash
```

配置守护进程代理：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | DOCKER_PROXY=http://localhost:7890 bash
```

自定义数据目录：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | DOCKER_DATA_ROOT=/data/docker bash
```

通过参数：

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash -s -- --mirror https://mirror.example.com --proxy http://localhost:7890 --data-root /data/docker
```

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DOCKER_MIRROR` | `https://docker.1ms.run` | 镜像加速地址，多个用逗号分隔 |
| `DOCKER_PROXY` | _（空）_ | 守护进程和容器的 HTTP/HTTPS 代理 |
| `DOCKER_NO_PROXY` | `localhost,127.0.0.0/8` | 不走代理的地址列表 |
| `DOCKER_DATA_ROOT` | _（空）_ | Docker 数据存储目录（默认 `/var/lib/docker`） |
| `DOCKER_COMPOSE` | `1` | 安装 docker-compose-plugin（设为 `0` 跳过） |

### `setup-skills.sh` — 代理技能

为所有编码代理（Claude Code、Codex、Gemini CLI 等）全局安装常用 [agent skills](https://skills.sh/)。

包含的技能：

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

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SKILLS_NPM_MIRROR` | `https://registry.npmmirror.com` | npm 镜像源 |

## 完整安装

> 建议顺序：代理 → shell → docker → uv → node → 编码代理 → 技能。

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

**3. Docker**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

**4. uv + Python**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | UV_PYTHON=3.12 bash
```

**5. Node.js**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

**6. Claude Code**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://你的API地址 CLAUDE_API_KEY=你的密钥 bash
```

**7. Codex CLI**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | CODEX_API_URL=https://你的API地址 CODEX_API_KEY=你的密钥 bash
```

**8. Gemini CLI**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | GEMINI_API_URL=https://你的API地址 GEMINI_API_KEY=你的密钥 bash
```

**9. 代理技能**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-skills.sh | bash
```

## 注意事项

- 所有脚本均支持**重复运行**，已安装的组件会自动跳过。
- 需要 `sudo` 权限安装系统包。
- Starship 需要终端支持 [Nerd Font](https://www.nerdfonts.com/) 才能正常显示图标。
- 如果 `gh-proxy.org` 不可用，可到 [ghproxy.link](https://ghproxy.link/) 查找其他可用代理。
