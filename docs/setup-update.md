# update.sh

All-in-one interactive or non-interactive updater for installed rig components. Detects what's installed, shows a TUI checkbox menu, runs updates, and displays a version-diff summary.

## Overview

`update.sh` is a standalone script that mirrors the TUI quality of `install.sh` but for updating already-installed components. All update logic is embedded inline (no `setup-*.sh` downloads). It detects installed components, captures before/after versions, and shows a diff summary.

## Quick Start

```bash
# Interactive — shows only installed components, all pre-selected
bash update.sh

# Non-interactive — update everything installed
bash update.sh --all

# Selective
bash update.sh --components codex,claude-code,node

# Via install.sh dispatch
bash install.sh update
bash install.sh update --all
```

## Modes

### Interactive TUI

When run with a terminal available and no `--all`/`--components` flag, a checkbox menu appears showing **only installed components** (all selected by default):

```
  ● Shell Environment         zsh, Oh My Zsh, plugins, Starship
  ● Node.js (nvm)             nvm + Node.js 24
  ● Claude Code               Claude Code CLI
  ○ Codex CLI                 OpenAI Codex CLI           [sudo]
  ● Gemini CLI                Gemini CLI
```

Controls: `↑↓` navigate, `Space` toggle, `a` toggle all, `Enter` confirm, `q` quit.

### Non-Interactive

- `--all` — update all installed components.
- `--components codex,claude-code` — update specific installed components by ID.

If piped (`curl | bash`) without flags, the script exits with a usage hint.

## Execution Flow

1. **Parse arguments** — `--all`, `--components`, `--gh-proxy`, `--verbose`.
2. **Load environment** — sources nvm, goenv, uv PATH so detection works.
3. **Detect installed** — checks each component for presence.
4. **Show TUI** (interactive) or validate selection (non-interactive).
5. **Show plan** — lists selected components in order with `sudo` tags.
6. **Cache sudo** — pre-authenticates if any selected component needs it.
7. **Capture before versions** — records current version of each selected component.
8. **Execute updates** — runs each component's inline update function. Shows spinner in default mode; raw output in `--verbose` mode.
9. **Capture after versions** — records new version after each update.
10. **Summary** — colored pass/fail report with version diffs (`v1.0 → v1.1` or `(no change)`).

## Component Update Logic

| Component | What Gets Updated | Needs sudo |
|-----------|-------------------|------------|
| Shell Environment | Oh My Zsh, custom plugins/themes (git pull), Starship | No |
| Tmux | `apt-get --only-upgrade tmux`, TPM plugins | Yes |
| Git | `apt-get --only-upgrade git` | Yes |
| Essential Tools | `apt-get --only-upgrade` rg, jq, fd, bat, tree, shellcheck, build-essential, gh | Yes |
| Clash Proxy | `git pull` + re-run installer | Yes |
| Node.js (nvm) | `nvm install node --reinstall-packages-from=current` | No |
| uv + Python | `uv self update` | No |
| Go (goenv) | `git pull` goenv, install latest Go version | No |
| Docker | `apt-get --only-upgrade` docker packages | Yes |
| Tailscale | `tailscale update` (fallback: apt) | Yes |
| SSH | `apt-get --only-upgrade openssh-server` | Yes |
| Claude Code | `npm install -g @anthropic-ai/claude-code@latest` | No |
| Codex CLI | `npm install -g @openai/codex@latest` | No |
| Gemini CLI | `npm install -g @google/gemini-cli@latest` | No |
| Agent Skills | Re-run `npx skills add` for each skill repo | No |

## Detection Logic

Each component is detected by checking for installed artifacts:

| Component | Detection Check |
|-----------|----------------|
| Shell | `~/.oh-my-zsh` directory exists |
| Tmux | `tmux` command available |
| Git | `git` command available |
| Essential Tools | `rg` and `jq` commands available |
| Clash | `~/clash-for-linux` directory exists |
| Node.js | `nvm` function or `~/.nvm/nvm.sh` exists |
| uv | `uv` command available |
| Go | `goenv` command or `~/.goenv/bin` exists |
| Docker | `docker` command available |
| Tailscale | `tailscale` command available |
| SSH | `/etc/ssh/sshd_config` exists |
| Claude Code | `claude` command available |
| Codex CLI | `codex` command available |
| Gemini CLI | `gemini` command available |
| Skills | `~/.local/share/skills` or `~/.claude/skills` exists |

## install.sh Integration

`install.sh` supports an `update` subcommand that downloads and executes `update.sh`:

```bash
bash install.sh update              # Interactive
bash install.sh update --all        # Non-interactive
bash install.sh update --components codex,claude-code
```

The `--gh-proxy` flag set before `update` applies to the download URL:

```bash
bash install.sh --gh-proxy https://gh-proxy.org update --all
```

## Differences from install.sh

| Aspect | install.sh | update.sh |
|--------|-----------|-----------|
| Banner | "Rig Installer" | "Rig Updater" |
| Menu | All 15 components | Only installed ones |
| Default selection | None | All installed |
| API key collection | Yes | No |
| Dependency resolution | Yes | No |
| Script download | Downloads `setup-*.sh` | No (logic inline) |
| Summary | Pass/fail | Pass/fail + version diffs |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GH_PROXY` | _(empty)_ | GitHub proxy URL prefix (for Starship download, skills mirror) |
| `NODE_VERSION` | _(empty)_ | Pin Node.js version for update (default: latest) |
| `SKILLS_NPM_MIRROR` | _(empty)_ | npm registry mirror for skills (auto-set when `GH_PROXY` is set) |

## Error Handling

- `update.sh` uses `set -uo pipefail` (**no** `-e`), so one component's failure does not abort the rest.
- On failure, the last 15 lines of the component's log are shown, with a path to the full log.
- Components that fail are marked with ✘ in the summary.

## Files Created

| File | Description |
|------|-------------|
| `/tmp/rig-update-*` | Base name for log files |
| `/tmp/rig-update-*.component` | Per-component log files (kept on failure) |
