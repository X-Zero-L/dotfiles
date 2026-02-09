# dotfiles

[中文](README_CN.md)

Automated setup scripts for Debian/Ubuntu systems.

## Quick Start

Interactive installer with TUI checkbox menu:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --gh-proxy https://gh-proxy.org
```

Install everything non-interactively:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --all
```

Specific components:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --components shell,node,docker
```

Available components: `shell`, `clash`, `node`, `uv`, `docker`, `claude-code`, `codex`, `gemini`, `skills`

## Scripts

### `setup-shell.sh` — Shell Environment

Installs zsh, Oh My Zsh, plugins (autosuggestions, syntax-highlighting, z), Starship prompt with Catppuccin Powerline preset.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

### `setup-clash.sh` — Clash Proxy

Installs [clash-for-linux](https://github.com/nelvko/clash-for-linux-install) with optional subscription URL.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
```

| Variable | Default | Description |
|----------|---------|-------------|
| `CLASH_SUB_URL` | _(empty)_ | Subscription URL (can also be passed as first argument) |
| `CLASH_KERNEL` | `mihomo` | Proxy kernel (`mihomo` or `clash`) |
| `CLASH_GH_PROXY` | `https://gh-proxy.org` | GitHub proxy for downloads (set empty to disable) |

### `setup-node.sh` — Node.js (via nvm)

Installs [nvm](https://github.com/nvm-sh/nvm) and Node.js.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

Specific version:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash -s -- 22
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_VERSION` | `24` | Node.js major version to install (can also be passed as first argument) |

### `setup-uv.sh` — uv + Python

Installs [uv](https://docs.astral.sh/uv/) package manager, optionally installs a Python version.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

With Python:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | UV_PYTHON=3.12 bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

| Variable | Default | Description |
|----------|---------|-------------|
| `UV_PYTHON` | _(empty)_ | Python version to install (can also be passed as first argument) |

### `setup-claude-code.sh` — Claude Code

Installs [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI and configures API settings.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key bash
```

With arguments:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_API_URL` | _(required)_ | API base URL |
| `CLAUDE_API_KEY` | _(required)_ | Auth token |
| `CLAUDE_MODEL` | `opus` | Model name |
| `CLAUDE_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

### `setup-codex.sh` — Codex CLI

Installs [Codex CLI](https://github.com/openai/codex) and configures API settings.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | CODEX_API_URL=https://your-api-url CODEX_API_KEY=your-key bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | CODEX_API_URL=https://your-api-url CODEX_API_KEY=your-key bash
```

With arguments:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

| Variable | Default | Description |
|----------|---------|-------------|
| `CODEX_API_URL` | _(required)_ | API base URL |
| `CODEX_API_KEY` | _(required)_ | API key |
| `CODEX_MODEL` | `gpt-5.2` | Model name |
| `CODEX_EFFORT` | `xhigh` | Reasoning effort |
| `CODEX_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

### `setup-gemini.sh` — Gemini CLI

Installs [Gemini CLI](https://github.com/google-gemini/gemini-cli) and configures API settings.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | GEMINI_API_URL=https://your-api-url GEMINI_API_KEY=your-key bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | GEMINI_API_URL=https://your-api-url GEMINI_API_KEY=your-key bash
```

With arguments:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

| Variable | Default | Description |
|----------|---------|-------------|
| `GEMINI_API_URL` | _(required)_ | API base URL |
| `GEMINI_API_KEY` | _(required)_ | API key |
| `GEMINI_MODEL` | `gemini-3-pro-preview` | Model name |
| `GEMINI_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

### `setup-docker.sh` — Docker

Installs [Docker Engine](https://docs.docker.com/engine/install/), Docker Compose plugin, configures registry mirrors, log rotation, address pools, and optional proxy.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

With custom mirror:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | DOCKER_MIRROR=https://mirror.example.com bash
```

With daemon proxy:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | DOCKER_PROXY=http://localhost:7890 bash
```

With custom data root:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | DOCKER_DATA_ROOT=/data/docker bash
```

With arguments:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash -s -- --mirror https://mirror.example.com --data-root /data/docker --log-size 50m --log-files 5
```

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_MIRROR` | `https://docker.1ms.run` | Registry mirror URL(s), comma-separated for multiple |
| `DOCKER_PROXY` | _(empty)_ | HTTP/HTTPS proxy for daemon and containers |
| `DOCKER_NO_PROXY` | `localhost,127.0.0.0/8` | No-proxy list for daemon |
| `DOCKER_DATA_ROOT` | _(empty)_ | Docker data directory (default: `/var/lib/docker`) |
| `DOCKER_LOG_SIZE` | `20m` | Max size per log file |
| `DOCKER_LOG_FILES` | `3` | Max number of log files to keep |
| `DOCKER_EXPERIMENTAL` | `1` | Enable experimental features (`0` to disable) |
| `DOCKER_ADDR_POOLS` | `172.17.0.0/12:24,192.168.0.0/16:24` | Default address pools (`base/cidr:size`, comma-separated) |
| `DOCKER_COMPOSE` | `1` | Install docker-compose-plugin (`0` to skip) |

### `setup-skills.sh` — Agent Skills

Installs common [agent skills](https://skills.sh/) globally for all coding agents (Claude Code, Codex, Gemini CLI, etc.).

Included skills:

| Skill | Source | Description |
|-------|--------|-------------|
| `find-skills` | [vercel-labs/skills](https://github.com/vercel-labs/skills) | Discover and install agent skills |
| `pdf` | [anthropics/skills](https://github.com/anthropics/skills) | PDF reading and manipulation |
| `gemini-cli-skill` | [X-Zero-L/gemini-cli-skill](https://github.com/X-Zero-L/gemini-cli-skill) | Gemini CLI integration |
| `context7` | [intellectronica/agent-skills](https://github.com/intellectronica/agent-skills) | Library documentation lookup |
| `writing-plans` | [obra/superpowers](https://github.com/obra/superpowers) | Implementation plan writing |
| `executing-plans` | [obra/superpowers](https://github.com/obra/superpowers) | Plan execution with checkpoints |
| `codex` | [softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit) | Codex agent skill |

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-skills.sh | bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-skills.sh | bash
```

| Variable | Default | Description |
|----------|---------|-------------|
| `SKILLS_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

## Full Setup

> Recommended order: proxy → shell → docker → uv → node → coding agents → skills.

**1. Proxy** (so subsequent downloads are faster)

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
```

```bash
source ~/.bashrc && clashon
```

**2. Shell environment**

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
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key bash
```

**7. Codex CLI**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | CODEX_API_URL=https://your-api-url CODEX_API_KEY=your-key bash
```

**8. Gemini CLI**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | GEMINI_API_URL=https://your-api-url GEMINI_API_KEY=your-key bash
```

**9. Agent Skills**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-skills.sh | bash
```

## Notes

- All scripts are **idempotent** — safe to run multiple times.
- Requires `sudo` for installing system packages.
- Starship icons require a [Nerd Font](https://www.nerdfonts.com/) in your terminal.
- If `gh-proxy.org` is unavailable, check [ghproxy.link](https://ghproxy.link/) for alternatives.
