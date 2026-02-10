# install.sh

All-in-one interactive or non-interactive installer. Downloads and executes individual setup scripts in dependency order.

## Overview

`install.sh` is a dispatcher that provides a TUI checkbox menu for selecting components, resolves dependencies, collects API keys, downloads the needed `setup-*.sh` scripts from GitHub, and executes them in order. It does not contain installation logic itself — each component's logic lives in its own script.

## Modes

### Interactive TUI

When run with a terminal available and no `--all`/`--components` flag, a checkbox menu appears:

```
  > [x] Shell Environment        zsh, Oh My Zsh, plugins, Starship           [sudo]
    [ ] Tmux                     tmux + Catppuccin + TPM plugins              [sudo]
    [x] Node.js (nvm)            nvm + Node.js 24
    ...
```

Controls: `↑↓` navigate, `Space` toggle, `a` toggle all, `Enter` confirm, `q` quit.

### Non-Interactive

- `--all` — select all components.
- `--components shell,node,docker` — select specific components by ID.

If piped (`curl | bash`) without flags, the script exits with a usage hint.

## Execution Flow

1. **Parse arguments** — `--all`, `--components`, `--gh-proxy`, `--verbose`.
2. **Show TUI** (interactive) or validate selection (non-interactive).
3. **Resolve dependencies** — auto-adds missing deps (e.g., selecting Claude Code auto-adds Node.js).
4. **Show plan** — lists components in install order with tags (`sudo`, `key`, `install only`).
5. **Collect API keys** — prompts for API URL/Key for AI agents (interactive), or reads from env vars (non-interactive). Missing keys result in "install only" mode.
6. **Cache sudo** — pre-authenticates sudo if any selected component needs it, then keeps it alive in the background.
7. **Download scripts** — fetches all needed `setup-*.sh` to a temp directory (fail-fast: all downloads must succeed before any execution).
8. **Execute** — runs each script in order. In default mode, shows a spinner; in `--verbose` mode, shows raw output.
9. **Summary** — colored pass/fail report with post-install hints.

## Dependency Resolution

| Component | Depends On |
|-----------|------------|
| Claude Code | Node.js |
| Codex CLI | Node.js |
| Gemini CLI | Node.js |
| Agent Skills | Node.js |

Dependencies are auto-added and installed first. The install order follows the array index in the component registry.

## API Key Handling

For AI agent components (Claude Code, Codex, Gemini):

- **With env vars set** (`CLAUDE_API_URL` + `CLAUDE_API_KEY`) — tool is installed and configured.
- **Without env vars** — in interactive mode, prompts for input (API Key is masked with `*`). Leaving blank results in "install only" mode.
- **Install only** — the tool is installed but not configured. Post-install hints show which env vars to set later.

## Error Handling

- `install.sh` uses `set -uo pipefail` (**no** `-e`), so one component's failure does not abort the rest.
- Each sub-script runs in its own `bash` subprocess with `set -euo pipefail`.
- On failure, the last 15 lines of the component's log are shown, with a path to the full log.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GH_PROXY` | _(empty)_ | GitHub proxy URL prefix for script downloads |
| `CLAUDE_API_URL` | _(empty)_ | API base URL for Claude Code |
| `CLAUDE_API_KEY` | _(empty)_ | API key for Claude Code |
| `CODEX_API_URL` | _(empty)_ | API base URL for Codex CLI |
| `CODEX_API_KEY` | _(empty)_ | API key for Codex CLI |
| `GEMINI_API_URL` | _(empty)_ | API base URL for Gemini CLI |
| `GEMINI_API_KEY` | _(empty)_ | API key for Gemini CLI |

All env vars from individual scripts are also respected (e.g., `NODE_VERSION`, `DOCKER_MIRROR`).

## Files Created

| File | Description |
|------|-------------|
| `/tmp/rig-install-*` | Temp directory for downloaded scripts (cleaned up on exit) |
| `/tmp/rig-install-*.component` | Per-component log files (kept on failure) |
