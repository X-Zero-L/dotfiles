# setup-tools.sh

Installs essential CLI tools that coding agents depend on daily — fast code search, JSON processing, GitHub CLI, build tools, and more.

## OS-Specific Package Names

The script automatically detects your OS and installs the appropriate packages:

| Tool | Debian/Ubuntu | CentOS/RHEL/Fedora | Arch Linux | macOS (Homebrew) |
|------|---------------|-------------------|------------|------------------|
| ripgrep | `ripgrep` | `ripgrep` | `ripgrep` | `ripgrep` |
| jq | `jq` | `jq` | `jq` | `jq` |
| fd | `fd-find` → symlink to `fd` | `fd-find` | `fd` | `fd` |
| bat | `bat` → symlink to `batcat` | `bat` | `bat` | `bat` |
| tree | `tree` | `tree` | `tree` | `tree` |
| gh | `gh` (via GitHub apt repo) | `gh` | `github-cli` | `gh` |
| shellcheck | `shellcheck` | `ShellCheck` | `shellcheck` | `shellcheck` |
| build tools | `build-essential` (gcc, g++, make) | `gcc`, `gcc-c++`, `make` | `base-devel` | Xcode Command Line Tools |
| wget | `wget` | `wget` | `wget` | `wget` |
| unzip | `unzip` | `unzip` | `unzip` | `unzip` |
| clipboard | `xclip` | `xclip` | `xclip` | `pbcopy` (built-in) |

**Notes:**
- On Debian/Ubuntu, `fd-find` and `bat` are symlinked to `fd` and `bat` in `~/.local/bin/`
- On macOS, Xcode Command Line Tools are installed automatically if not present
- macOS uses `pbcopy`/`pbpaste` built-in commands instead of `xclip`

## What Gets Installed

| Binary | Purpose |
|--------|---------|
| `rg` | Fast code search (used internally by Claude Code) |
| `jq` | JSON processing |
| `fd` | Fast file finder |
| `bat` | Syntax-highlighted cat |
| `tree` | Directory structure visualization |
| `gh` | GitHub CLI (PRs, issues, API) |
| `shellcheck` | Shell script linting |
| `gcc`, `g++`, `make` | Native npm module compilation |
| `wget` | HTTP downloads |
| `unzip` | Archive extraction |

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
