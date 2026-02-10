# setup-go.sh

Installs [goenv](https://github.com/go-nv/goenv) and Go.

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| goenv | [go-nv/goenv](https://github.com/go-nv/goenv) | Go version manager (like nvm for Node.js) |
| Go | via `goenv install` | Specified version or latest |

## How It Works

| Step | Action |
|------|--------|
| 1/4 | Clone goenv to `~/.goenv` (uses `GH_PROXY` if set). If already installed, `git pull` to update. |
| 2/4 | Load goenv into current shell (`eval "$(goenv init -)"`) |
| 3/4 | Install specified Go version (or resolve `latest`). Skip if already installed. Set as global default. |
| 4/4 | Ensure goenv block is in `~/.bashrc` and `~/.zshrc` (skip `.zshrc` if it doesn't exist) |

## Files Created/Modified

| File | Description |
|------|-------------|
| `~/.goenv/` | goenv installation directory |
| `~/.goenv/versions/` | Installed Go versions |
| `~/.bashrc` | goenv init block added |
| `~/.zshrc` | goenv init block added (if file exists) |

### Shell Block

```bash
# goenv START
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
# goenv END
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GO_VERSION` | `latest` | Go version to install (also accepted as first argument) |
| `GH_PROXY` | _(empty)_ | GitHub proxy for cloning goenv |
| `GO_BUILD_MIRROR_URL` | _(empty)_ | Mirror for Go binary downloads. Auto-set to `https://mirrors.aliyun.com/golang/` when `GH_PROXY` is set. |

## Re-run Behavior

- goenv: already installed → `git pull` to update.
- Go version: already installed → skipped.
- Shell config: `goenv START` block already present → skipped.

## Dependencies

- `git`, `curl`.
- No `sudo` required.

## Post-Install

```bash
source ~/.zshrc     # or open a new terminal
go version          # verify installation
goenv versions      # list installed versions
goenv install 1.23.0  # install additional version
goenv global 1.23.0   # switch global version
```
