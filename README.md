# dotfiles

[中文](README_CN.md)

Automated setup scripts for Debian/Ubuntu systems.

## Scripts

### `setup-shell.sh` — Shell Environment

Installs zsh, Oh My Zsh, plugins (autosuggestions, syntax-highlighting, z), Starship prompt with Catppuccin Powerline preset.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash

# Via proxy
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

### `setup-clash.sh` — Clash Proxy

Installs [clash-for-linux](https://github.com/nelvko/clash-for-linux-install) with optional subscription URL.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'

# Via proxy
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

# Specific version
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash -s -- 22

# Via proxy
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash
```

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_VERSION` | `24` | Node.js major version to install (can also be passed as first argument) |

### `setup-claude-code.sh` — Claude Code

Installs [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI and configures API settings.

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key bash

# Via proxy
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key bash

# Or with arguments
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | bash -s -- --api-url https://your-api-url --api-key your-key
```

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_API_URL` | _(required)_ | API base URL |
| `CLAUDE_API_KEY` | _(required)_ | Auth token |
| `CLAUDE_MODEL` | `opus` | Model name |
| `CLAUDE_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

## Full Setup

> Recommended order: proxy → shell → node → claude code.

```bash
# 1. Proxy (so subsequent downloads are faster)
curl -fsSL https://gh-proxy.org/https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- 'https://your-subscription-url'
source ~/.bashrc && clashon

# 2. Shell environment
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash

# 3. Node.js
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-node.sh | bash

# 4. Claude Code
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-claude-code.sh | CLAUDE_API_URL=https://your-api-url CLAUDE_API_KEY=your-key bash
```

## Notes

- All scripts are **idempotent** — safe to run multiple times.
- Requires `sudo` for installing system packages.
- Starship icons require a [Nerd Font](https://www.nerdfonts.com/) in your terminal.
- If `gh-proxy.org` is unavailable, check [ghproxy.link](https://ghproxy.link/) for alternatives.
