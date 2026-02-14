# Documentation

[中文](zh/README.md)

Detailed documentation for each setup script. For quick start, see the [main README](../README.md).

## OS Compatibility

All scripts automatically detect the operating system and use the appropriate package manager:

| Component | Debian/Ubuntu | CentOS/RHEL | Fedora | Arch Linux | macOS |
|-----------|---------------|-------------|--------|------------|-------|
| Shell (zsh, Oh My Zsh, Starship) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Tmux | ✓ | ✓ | ✓ | ✓ | ✓ |
| Git | ✓ | ✓ | ✓ | ✓ | ✓ |
| Essential Tools | ✓ | ✓ | ✓ | ✓ | ✓ |
| Clash Proxy | ✓ | ✓ | ✓ | ✓ | ✗ (Linux only) |
| Docker | ✓ (Engine) | ✓ (Engine) | ✓ (Engine) | ✓ (Engine) | ✓ (Desktop) |
| Tailscale | ✓ | ✓ | ✓ | ✓ | ✓ |
| SSH | ✓ | ✓ | ✓ | ✓ | ✓ (Remote Login) |
| Node.js (nvm) | ✓ | ✓ | ✓ | ✓ | ✓ |
| uv + Python | ✓ | ✓ | ✓ | ✓ | ✓ |
| Go (goenv) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Claude Code | ✓ | ✓ | ✓ | ✓ | ✓ |
| Codex CLI | ✓ | ✓ | ✓ | ✓ | ✓ |
| Gemini CLI | ✓ | ✓ | ✓ | ✓ | ✓ |
| Agent Skills | ✓ | ✓ | ✓ | ✓ | ✓ |

**Notes:**
- Docker on macOS uses Docker Desktop (installed via Homebrew) instead of Docker Engine
- SSH on macOS configures Remote Login instead of the OpenSSH server via systemd
- Clash proxy is only supported on Linux systems

## Scripts

### Base Environment

| Script | Description |
|--------|-------------|
| [install.sh](install.md) | All-in-one interactive/non-interactive installer |
| [setup-shell.sh](setup-shell.md) | zsh + Oh My Zsh + plugins + Starship |
| [setup-tmux.sh](setup-tmux.md) | tmux + TPM + Catppuccin + mouse enhancements |
| [setup-git.sh](setup-git.md) | Git user identity + sensible defaults |
| [setup-clash.sh](setup-clash.md) | Clash proxy with subscription management |
| [setup-docker.sh](setup-docker.md) | Docker Engine + Compose + daemon configuration |
| [setup-tailscale.sh](setup-tailscale.md) | Tailscale VPN mesh network |
| [setup-ssh.sh](setup-ssh.md) | SSH port + key-only authentication |

### Language Runtimes

| Script | Description |
|--------|-------------|
| [setup-node.sh](setup-node.md) | nvm + Node.js |
| [setup-uv.sh](setup-uv.md) | uv package manager + Python |
| [setup-go.sh](setup-go.md) | goenv + Go |

### AI Coding Agents

| Script | Description |
|--------|-------------|
| [setup-claude-code.sh](setup-claude-code.md) | Claude Code CLI + API configuration |
| [setup-codex.sh](setup-codex.md) | OpenAI Codex CLI + API configuration |
| [setup-gemini.sh](setup-gemini.md) | Google Gemini CLI + API configuration |
| [setup-skills.sh](setup-skills.md) | Agent skills for all coding agents |

### Management

| Script | Description |
|--------|-------------|
| [rig](rig-management.md) | CLI wrapper — presets, status, export/import, uninstall |
| [update.sh](setup-update.md) | Update installed components |
| [status.sh](rig-management.md#rig-status) | Show installed components and versions |
| [export-config.sh](rig-management.md#rig-export) | Export configuration to JSON + secrets |
| [import-config.sh](rig-management.md#rig-import) | Import configuration from exported files |
| [uninstall.sh](rig-management.md#rig-uninstall) | Safely remove components |

## Design Principles

All scripts follow these conventions:

- **Idempotent** — safe to run multiple times. Already installed components are skipped, changed configuration is updated.
- **Standalone** — each script can be run independently via `curl | bash`.
- **Configurable** — behavior controlled via environment variables or CLI arguments.
- **Secure** — API keys passed via environment variables (not command arguments), config files set to `chmod 600`.
- **Fail-safe** — `set -euo pipefail` catches errors early.
