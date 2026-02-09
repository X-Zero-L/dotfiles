# setup-clash.sh

Installs [clash-for-linux](https://github.com/nelvko/clash-for-linux-install) proxy with optional subscription.

## Overview

Sets up a local proxy (default: mihomo kernel) that can be toggled with `clashon`/`clashoff` shell functions. The proxy listens on `localhost:7890` and supports HTTP/HTTPS/SOCKS5.

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| clash-for-linux | [nelvko/clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install) | Clash wrapper with clashctl management |
| mihomo (default) | Downloaded by installer | Proxy kernel |

## How It Works

| Step | Action |
|------|--------|
| 1 | Clone `clash-for-linux-install` to a temp directory (uses `CLASH_GH_PROXY` if set) |
| 2 | Patch the installer script to remove interactive prompts |
| 3 | Run `install.sh mihomo` to install kernel and create `~/clashctl/` |
| 4 | Ensure clashctl block is in both `~/.bashrc` and `~/.zshrc` (skips `.zshrc` if it doesn't exist yet) |
| 5 | If `CLASH_SUB_URL` is provided, add subscription and activate it |

## Files Created

| File | Description |
|------|-------------|
| `~/clashctl/` | Installation directory |
| `~/clashctl/scripts/cmd/clashctl.sh` | Management script (sourced by shell) |
| `~/.bashrc` / `~/.zshrc` | clashctl block added (sources clashctl.sh + auto watch_proxy) |

## Shell Functions

After installation, these functions are available (via sourced `clashctl.sh`):

| Function | Description |
|----------|-------------|
| `clashon` | Start the proxy and set `http_proxy`/`https_proxy` env vars |
| `clashoff` | Stop the proxy and unset env vars |
| `clashsub add <url>` | Add a subscription URL |
| `clashsub use <n>` | Switch to subscription number `n` |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLASH_SUB_URL` | _(empty)_ | Subscription URL (also accepted as first argument) |
| `CLASH_KERNEL` | `mihomo` | Proxy kernel: `mihomo` or `clash` |
| `CLASH_GH_PROXY` | `https://gh-proxy.org` | GitHub proxy for downloading clash (empty to disable) |

## Re-run Behavior

- Installation: skipped if `~/clashctl/` exists with `clashctl.sh`.
- RC files: skipped if `clashctl START` block already present. `.zshrc` skipped if file doesn't exist.
- Subscription: re-added and activated if `CLASH_SUB_URL` is provided.

## Dependencies

- `git`, `curl`, `unzip` (auto-installed if missing).
- `sudo` required for installing dependencies.

## Post-Install

```bash
source ~/.bashrc   # or ~/.zshrc
clashon             # start proxy
```
