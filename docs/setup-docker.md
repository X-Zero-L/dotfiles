# setup-docker.sh

Installs Docker, Compose plugin, and configures the daemon with mirrors, logging, address pools, and optional proxy.

## OS-Specific Behavior

| OS | Docker Variant | Installation Method | systemd |
|----|---------------|---------------------|---------|
| Debian/Ubuntu | Docker Engine | [get.docker.com](https://get.docker.com) + apt | ✓ |
| CentOS/RHEL | Docker Engine | [get.docker.com](https://get.docker.com) + yum/dnf | ✓ |
| Fedora | Docker Engine | [get.docker.com](https://get.docker.com) + dnf | ✓ |
| Arch Linux | Docker Engine | [get.docker.com](https://get.docker.com) + pacman | ✓ |
| macOS | Docker Desktop | Homebrew (`brew install --cask docker`) | ✗ |

**macOS Notes:**
- Docker Desktop is installed via Homebrew Cask instead of Docker Engine
- No systemd service configuration (macOS doesn't use systemd)
- Docker Desktop manages daemon.json differently - manual configuration may be required
- Requires `sudo` for initial installation but not for Homebrew operations

## What Gets Installed

### Linux (Docker Engine)

| Tool | Source | Description |
|------|--------|-------------|
| Docker Engine | [get.docker.com](https://get.docker.com) | Container runtime |
| docker-compose-plugin | Package manager | `docker compose` command |

### macOS (Docker Desktop)

| Tool | Source | Description |
|------|--------|-------------|
| Docker Desktop | Homebrew Cask | Container runtime with GUI |

## How It Works

| Step | Action |
|------|--------|
| 1/5 | Install Docker Engine via `get.docker.com` convenience script |
| 2/5 | Install `docker-compose-plugin` via apt (skipped if `DOCKER_COMPOSE=0`) |
| 3/5 | Add current user to `docker` group |
| 4/5 | Generate `/etc/docker/daemon.json` with mirrors, logging, pools, etc. |
| 5/5 | If `DOCKER_PROXY` is set: create systemd drop-in for daemon proxy + write `~/.docker/config.json` for container proxy |
| Final | Restart Docker only if configuration actually changed |

### daemon.json Generation

Uses `python3` if available (preserves unknown keys via JSON merge). Falls back to manual JSON construction if python3 is not installed.

The generated `daemon.json` contains:

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "20m", "max-file": "3" },
  "experimental": true,
  "default-address-pools": [
    { "base": "172.17.0.0/12", "size": 24 },
    { "base": "192.168.0.0/16", "size": 24 }
  ]
}
```

## Files Created/Modified

| File | Description |
|------|-------------|
| `/etc/docker/daemon.json` | Daemon configuration (mirrors, logging, pools) |
| `/etc/systemd/system/docker.service.d/proxy.conf` | Daemon proxy (only if `DOCKER_PROXY` is set) |
| `~/.docker/config.json` | Container proxy settings (only if `DOCKER_PROXY` is set) |
| `/etc/group` | User added to `docker` group |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCKER_MIRROR` | _(empty)_ | Registry mirror URL(s), comma-separated. `install.sh` auto-sets to `https://docker.1ms.run` when `--gh-proxy` is used |
| `DOCKER_PROXY` | _(empty)_ | HTTP/HTTPS proxy for daemon and containers |
| `DOCKER_NO_PROXY` | `localhost,127.0.0.0/8` | No-proxy list |
| `DOCKER_DATA_ROOT` | _(empty)_ | Data directory (default: `/var/lib/docker`) |
| `DOCKER_LOG_SIZE` | `20m` | Max size per log file |
| `DOCKER_LOG_FILES` | `3` | Max number of log files |
| `DOCKER_EXPERIMENTAL` | `1` | Enable experimental features (`0` to disable) |
| `DOCKER_ADDR_POOLS` | `172.17.0.0/12:24,192.168.0.0/16:24` | Default address pools (`base/cidr:size`) |
| `DOCKER_COMPOSE` | `1` | Install docker-compose-plugin (`0` to skip) |

## Re-run Behavior

- Docker Engine: skipped if `docker` command exists.
- Compose plugin: skipped if `docker compose version` succeeds.
- User group: skipped if user already in `docker` group.
- daemon.json: snapshots before/after, restarts Docker only if changed.
- Proxy drop-in: compared before/after, restarts Docker only if changed.

## Dependencies

- `sudo` access.
- `curl`.
- `python3` recommended (for clean JSON merge). Works without it but replaces daemon.json entirely.

## Post-Install

Run `newgrp docker` or re-login to use Docker without `sudo`.
