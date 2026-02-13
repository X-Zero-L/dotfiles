# setup-tools.sh

Installs essential CLI tools that coding agents depend on daily — fast code search, JSON processing, GitHub CLI, build tools, and more.

## What Gets Installed

| Package | Binary | Purpose |
|---------|--------|---------|
| `ripgrep` | `rg` | Fast code search (used internally by Claude Code) |
| `jq` | `jq` | JSON processing |
| `fd-find` | `fdfind` → `fd` | Fast file finder |
| `bat` | `batcat` → `bat` | Syntax-highlighted cat |
| `tree` | `tree` | Directory structure visualization |
| `gh` | `gh` | GitHub CLI (PRs, issues, API) |
| `shellcheck` | `shellcheck` | Shell script linting |
| `build-essential` | `gcc`, `g++`, `make` | Native npm module compilation |
| `wget` | `wget` | HTTP downloads |
| `unzip` | `unzip` | Archive extraction |
| `xclip` | `xclip` | Clipboard (tmux integration) |

## How It Works

### Step 1: apt packages

Installs all packages via `apt-get install -y`. This is naturally idempotent — already-installed packages are skipped by apt.

### Step 2: GitHub CLI

The `gh` CLI requires adding GitHub's official apt repository:

```bash
# Add GitHub apt repo keyring and source list
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/...
echo "deb [...] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/...
sudo apt-get install -y gh
```

If `gh` is already installed, this step is skipped entirely.

### Step 3: Convenience symlinks

On Debian/Ubuntu, `fd-find` installs as `fdfind` and `bat` installs as `batcat` to avoid name conflicts. The script creates symlinks in `~/.local/bin/`:

- `~/.local/bin/fd` → `/usr/bin/fdfind`
- `~/.local/bin/bat` → `/usr/bin/batcat`

Symlinks are only created if the canonical name (`fd`, `bat`) is not already available.

## Re-run Behavior

The script is fully idempotent:

- `apt-get install` is naturally idempotent for already-installed packages.
- `gh` installation is skipped if the command already exists.
- Symlinks are only created if the target name is not already available.

## Dependencies

None. This component has no dependencies on other rig components.

## Environment Variables

None required. The script uses only system apt repositories and GitHub's official apt repo.

## Files Created

| File | Description |
|------|-------------|
| `~/.local/bin/bat` | Symlink to `batcat` (if needed) |
| `~/.local/bin/fd` | Symlink to `fdfind` (if needed) |
| `/etc/apt/keyrings/githubcli-archive-keyring.gpg` | GitHub CLI apt signing key |
| `/etc/apt/sources.list.d/github-cli.list` | GitHub CLI apt repository |

## Post-Install

Verify all tools are available:

```bash
command -v rg jq fd bat tree gh shellcheck gcc wget unzip xclip
```
