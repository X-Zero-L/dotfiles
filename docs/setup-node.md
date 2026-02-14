# setup-node.sh

Installs nvm (Node Version Manager) and Node.js.

## OS Support

nvm works on all supported platforms (Linux and macOS). No OS-specific package manager needed:

| OS | Status |
|----|--------|
| Debian/Ubuntu | ✓ |
| CentOS/RHEL | ✓ |
| Fedora | ✓ |
| Arch Linux | ✓ |
| macOS | ✓ |

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| nvm | [nvm-sh/nvm](https://github.com/nvm-sh/nvm) | Node.js version manager |
| Node.js | via nvm | JavaScript runtime (default: v24) |
| npm | bundled with Node.js | Package manager |

## How It Works

| Step | Action |
|------|--------|
| 1/3 | Download and run nvm install script from GitHub |
| 2/3 | `nvm install <version>` + `nvm alias default <version>` |
| 3/3 | Configure npm registry (if mirror is set) |

## Files Created/Modified

| File | Description |
|------|-------------|
| `~/.nvm/` | nvm installation directory |
| `~/.nvm/nvm.sh` | nvm shell function (sourced by shell rc files) |
| `~/.bashrc` / `~/.zshrc` | Modified by nvm installer to load nvm on shell start |
| `~/.nvm/versions/node/` | Installed Node.js versions |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_VERSION` | `24` | Node.js major version to install (also accepted as first argument) |
| `NVM_NODEJS_ORG_MIRROR` | _(empty)_ | Mirror for Node.js binary downloads. Auto-set to `https://npmmirror.com/mirrors/node` when `GH_PROXY` is set. |
| `NPM_REGISTRY` | _(empty)_ | npm registry URL. Auto-set to `https://registry.npmmirror.com` when `GH_PROXY` is set. |

## Re-run Behavior

- nvm: skipped if `~/.nvm/nvm.sh` exists.
- Node.js: `nvm install` is always run (nvm handles caching internally; if the version is already installed, it's a no-op).

## Dependencies

- `curl`.
- No `sudo` required.

## Post-Install

Run `source ~/.zshrc` or open a new terminal to use `node`, `npm`, and `nvm`.

Note: Other scripts that depend on Node.js (Claude Code, Codex, Gemini, Skills) will automatically load nvm if installed.
