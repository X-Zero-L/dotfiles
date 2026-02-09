# dotfiles

[中文](README_CN.md)

Automated setup scripts for Debian/Ubuntu systems.

> All scripts are **idempotent** — safe to run multiple times. Already installed components are skipped automatically. Requires `curl`, `git`, and `sudo`.

## Quick Start

Use `install.sh` for a one-stop interactive or non-interactive installation.

Interactive TUI — select what to install:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash
```

Via proxy (recommended for China):

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --gh-proxy https://gh-proxy.org
```

Install everything non-interactively:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --all
```

Specific components only:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --components shell,node,docker
```

With pre-configured API keys:

```bash
export CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key
export CODEX_API_URL=https://your-api-url  CODEX_API_KEY=your-key
export GEMINI_API_URL=https://your-api-url GEMINI_API_KEY=your-key
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --all
```

Verbose mode (show raw script output instead of spinner):

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --all --verbose
```

Available components: `shell`, `clash`, `node`, `uv`, `docker`, `claude-code`, `codex`, `gemini`, `skills`

## Components

Each script can also be run standalone. All scripts support two install styles — direct and via gh-proxy:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/<script> | bash
```

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/<script> | bash
```

---

### Base Environment

#### Shell (`setup-shell.sh`)

Installs zsh, Oh My Zsh, plugins (autosuggestions, syntax-highlighting, z), Starship prompt with Catppuccin Powerline preset. Requires `sudo`.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

#### Clash Proxy (`setup-clash.sh`)

Installs [clash-for-linux](https://github.com/nelvko/clash-for-linux-install) with subscription support.

With subscription URL as argument:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
```

With pre-exported env var:

```bash
export CLASH_SUB_URL='https://your-subscription-url'
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
```

Config: `CLASH_SUB_URL`, `CLASH_KERNEL`, `CLASH_GH_PROXY` — see [Configuration Reference](#configuration-reference).

#### Docker (`setup-docker.sh`)

Installs [Docker Engine](https://docs.docker.com/engine/install/), Compose plugin, configures registry mirrors, log rotation, address pools, and optional proxy. Requires `sudo`.

Default (includes China mirror):

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

Custom configuration:

```bash
export DOCKER_MIRROR=https://mirror.example.com
export DOCKER_DATA_ROOT=/data/docker
export DOCKER_PROXY=http://localhost:7890
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-docker.sh | bash
```

Config: `DOCKER_MIRROR`, `DOCKER_PROXY`, `DOCKER_DATA_ROOT`, `DOCKER_LOG_SIZE`, etc. — see [Configuration Reference](#configuration-reference).

---

### Language Runtimes

#### Node.js (`setup-node.sh`)

Installs [nvm](https://github.com/nvm-sh/nvm) and Node.js.

Default (Node.js 24):

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

Specific version:

```bash
export NODE_VERSION=22
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

#### uv + Python (`setup-uv.sh`)

Installs [uv](https://docs.astral.sh/uv/) package manager, optionally installs a Python version.

uv only:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

uv + Python:

```bash
export UV_PYTHON=3.12
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-uv.sh | bash
```

---

### AI Coding Agents

All three agent scripts share the same behavior:

- **With API keys** → install tool + write config (skip if already up to date)
- **Without API keys** → install tool only, configure later
- **Re-run with keys** → skip install, check and update config if changed

#### Claude Code (`setup-claude-code.sh`)

Installs [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI. Alias: `cc`.

Install + configure:

```bash
export CLAUDE_API_URL=https://your-api-url
export CLAUDE_API_KEY=your-key
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash
```

Install only (configure later):

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash
```

Via CLI arguments:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash
```

Config: `CLAUDE_API_URL`, `CLAUDE_API_KEY`, `CLAUDE_MODEL`, `CLAUDE_NPM_MIRROR` — see [Configuration Reference](#configuration-reference).

#### Codex CLI (`setup-codex.sh`)

Installs [Codex CLI](https://github.com/openai/codex). Alias: `cx`.

Install + configure:

```bash
export CODEX_API_URL=https://your-api-url
export CODEX_API_KEY=your-key
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash
```

Install only (configure later):

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash
```

Via CLI arguments:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-codex.sh | bash
```

Config: `CODEX_API_URL`, `CODEX_API_KEY`, `CODEX_MODEL`, `CODEX_EFFORT`, `CODEX_NPM_MIRROR` — see [Configuration Reference](#configuration-reference).

#### Gemini CLI (`setup-gemini.sh`)

Installs [Gemini CLI](https://github.com/google-gemini/gemini-cli). Alias: `gm`.

Install + configure:

```bash
export GEMINI_API_URL=https://your-api-url
export GEMINI_API_KEY=your-key
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash
```

Install only (configure later):

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash
```

Via CLI arguments:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

Via proxy:

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-gemini.sh | bash
```

Config: `GEMINI_API_URL`, `GEMINI_API_KEY`, `GEMINI_MODEL`, `GEMINI_NPM_MIRROR` — see [Configuration Reference](#configuration-reference).

#### Agent Skills (`setup-skills.sh`)

Installs common [agent skills](https://skills.sh/) globally for all coding agents.

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

Config: `SKILLS_NPM_MIRROR` — see [Configuration Reference](#configuration-reference).

## Configuration Reference

All environment variables across all scripts in one table.

### General

| Variable | Scope | Default | Description |
|----------|-------|---------|-------------|
| `GH_PROXY` | `install.sh` | _(empty)_ | GitHub proxy URL for script downloads |

### Clash

| Variable | Default | Description |
|----------|---------|-------------|
| `CLASH_SUB_URL` | _(empty)_ | Subscription URL (also accepted as first argument) |
| `CLASH_KERNEL` | `mihomo` | Proxy kernel (`mihomo` or `clash`) |
| `CLASH_GH_PROXY` | `https://gh-proxy.org` | GitHub proxy for clash downloads (empty to disable) |

### Node.js

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_VERSION` | `24` | Node.js major version (also accepted as first argument) |

### uv + Python

| Variable | Default | Description |
|----------|---------|-------------|
| `UV_PYTHON` | _(empty)_ | Python version to install (also accepted as first argument) |

### Docker

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_MIRROR` | `https://docker.1ms.run` | Registry mirror URL(s), comma-separated |
| `DOCKER_PROXY` | _(empty)_ | HTTP/HTTPS proxy for daemon and containers |
| `DOCKER_NO_PROXY` | `localhost,127.0.0.0/8` | No-proxy list |
| `DOCKER_DATA_ROOT` | _(empty)_ | Data directory (default: `/var/lib/docker`) |
| `DOCKER_LOG_SIZE` | `20m` | Max size per log file |
| `DOCKER_LOG_FILES` | `3` | Max number of log files |
| `DOCKER_EXPERIMENTAL` | `1` | Enable experimental features (`0` to disable) |
| `DOCKER_ADDR_POOLS` | `172.17.0.0/12:24,192.168.0.0/16:24` | Default address pools (`base/cidr:size`) |
| `DOCKER_COMPOSE` | `1` | Install docker-compose-plugin (`0` to skip) |

### Claude Code

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_API_URL` | _(empty)_ | API base URL (skip config if empty) |
| `CLAUDE_API_KEY` | _(empty)_ | Auth token (skip config if empty) |
| `CLAUDE_MODEL` | `opus` | Model name |
| `CLAUDE_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

### Codex CLI

| Variable | Default | Description |
|----------|---------|-------------|
| `CODEX_API_URL` | _(empty)_ | API base URL (skip config if empty) |
| `CODEX_API_KEY` | _(empty)_ | API key (skip config if empty) |
| `CODEX_MODEL` | `gpt-5.2` | Model name |
| `CODEX_EFFORT` | `xhigh` | Reasoning effort |
| `CODEX_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

### Gemini CLI

| Variable | Default | Description |
|----------|---------|-------------|
| `GEMINI_API_URL` | _(empty)_ | API base URL (skip config if empty) |
| `GEMINI_API_KEY` | _(empty)_ | API key (skip config if empty) |
| `GEMINI_MODEL` | `gemini-3-pro-preview` | Model name |
| `GEMINI_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

### Agent Skills

| Variable | Default | Description |
|----------|---------|-------------|
| `SKILLS_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

## Bootstrap Guide

Step-by-step flow for setting up a fresh machine. The recommended order ensures dependencies are met.

**1. Proxy** (so subsequent downloads are faster)

```bash
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
```

```bash
source ~/.bashrc && clashon
```

**2. Prepare API keys** (optional — omit to install tools without config)

```bash
export CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key
export CODEX_API_URL=https://your-api-url  CODEX_API_KEY=your-key
export GEMINI_API_URL=https://your-api-url GEMINI_API_KEY=your-key
```

**3. Install everything**

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/install.sh | bash -s -- --all
```

Or install components individually in this order:

1. `setup-shell.sh` — Shell environment (zsh, plugins, Starship)
2. `setup-docker.sh` — Docker Engine + Compose
3. `setup-uv.sh` — uv + Python
4. `setup-node.sh` — nvm + Node.js
5. `setup-claude-code.sh` — Claude Code
6. `setup-codex.sh` — Codex CLI
7. `setup-gemini.sh` — Gemini CLI
8. `setup-skills.sh` — Agent skills

## Notes

- Starship icons require a [Nerd Font](https://www.nerdfonts.com/) in your terminal.
- If `gh-proxy.org` is unavailable, check [ghproxy.link](https://ghproxy.link/) for alternatives.
- Re-running a script with different API keys/config will update the configuration without reinstalling.
