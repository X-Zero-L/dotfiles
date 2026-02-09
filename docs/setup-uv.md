# setup-uv.sh

Installs the [uv](https://docs.astral.sh/uv/) package manager and optionally a Python version.

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| uv | [astral.sh/uv](https://astral.sh/uv/) | Fast Python package and project manager |
| Python | via `uv python install` | Optional, specified version |

## How It Works

| Step | Action |
|------|--------|
| 1/2 | Download and run uv install script from astral.sh. If uv already exists, runs `uv self update`. |
| 2/2 | If `UV_PYTHON` is set, runs `uv python install <version>` |

## Files Created/Modified

| File | Description |
|------|-------------|
| `~/.local/bin/uv` | uv binary |
| `~/.local/bin/uvx` | uvx (uv tool runner) |
| `~/.local/share/uv/` | uv cache and data directory |
| `~/.local/share/uv/python/` | Installed Python versions |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `UV_PYTHON` | _(empty)_ | Python version to install (also accepted as first argument). Empty = skip Python. |

## Re-run Behavior

- uv: if already installed, runs `uv self update` to upgrade to latest.
- Python: `uv python install` handles existing versions gracefully.

## Dependencies

- `curl`.
- No `sudo` required.

## Post-Install

Run `source ~/.zshrc` or open a new terminal. Then:

```bash
uv init myproject       # create a new project
uv add requests         # add dependencies
uv run python main.py   # run with managed Python
```
