# Documentation

Detailed documentation for each setup script. For quick start, see the [main README](../README.md).

## Scripts

### Base Environment

| Script | Description |
|--------|-------------|
| [install.sh](install.md) | All-in-one interactive/non-interactive installer |
| [setup-shell.sh](setup-shell.md) | zsh + Oh My Zsh + plugins + Starship |
| [setup-tmux.sh](setup-tmux.md) | tmux + TPM + Catppuccin + mouse enhancements |
| [setup-clash.sh](setup-clash.md) | Clash proxy with subscription management |
| [setup-docker.sh](setup-docker.md) | Docker Engine + Compose + daemon configuration |

### Language Runtimes

| Script | Description |
|--------|-------------|
| [setup-node.sh](setup-node.md) | nvm + Node.js |
| [setup-uv.sh](setup-uv.md) | uv package manager + Python |

### AI Coding Agents

| Script | Description |
|--------|-------------|
| [setup-claude-code.sh](setup-claude-code.md) | Claude Code CLI + API configuration |
| [setup-codex.sh](setup-codex.md) | OpenAI Codex CLI + API configuration |
| [setup-gemini.sh](setup-gemini.md) | Google Gemini CLI + API configuration |
| [setup-skills.sh](setup-skills.md) | Agent skills for all coding agents |

## Design Principles

All scripts follow these conventions:

- **Idempotent** — safe to run multiple times. Already installed components are skipped, changed configuration is updated.
- **Standalone** — each script can be run independently via `curl | bash`.
- **Configurable** — behavior controlled via environment variables or CLI arguments.
- **Secure** — API keys passed via environment variables (not command arguments), config files set to `chmod 600`.
- **Fail-safe** — `set -euo pipefail` catches errors early.
