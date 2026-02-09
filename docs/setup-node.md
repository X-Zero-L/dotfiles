# setup-node.sh

Installs nvm (Node Version Manager) and Node.js.

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| nvm | [nvm-sh/nvm](https://github.com/nvm-sh/nvm) | Node.js version manager |
| Node.js | via nvm | JavaScript runtime (default: v24) |
| npm | bundled with Node.js | Package manager |

## How It Works

| Step | Action |
|------|--------|
| 1/2 | Download and run nvm install script from GitHub |
| 2/2 | `nvm install <version>` + `nvm alias default <version>` |

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

## Re-run Behavior

- nvm: skipped if `~/.nvm/nvm.sh` exists.
- Node.js: `nvm install` is always run (nvm handles caching internally; if the version is already installed, it's a no-op).

## Dependencies

- `curl`.
- No `sudo` required.

## Post-Install

Run `source ~/.zshrc` or open a new terminal to use `node`, `npm`, and `nvm`.

Note: Other scripts that depend on Node.js (Claude Code, Codex, Gemini, Skills) will automatically load nvm if installed.
