# setup-gemini.sh

Installs [Gemini CLI](https://github.com/google-gemini/gemini-cli) and optionally configures API credentials. Alias: `gm`.

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| Gemini CLI | `npm install -g @google/gemini-cli` | Google's coding agent CLI |

## How It Works

| Step | Action |
|------|--------|
| 1/3 | Install Gemini CLI globally via npm (skipped if `gemini` command exists) |
| 2/3 | If API keys provided: write `~/.gemini/.env` with API URL, key, and model |
| 3/3 | Add `alias gm='gemini -y'` to `~/.bashrc` and `~/.zshrc` |

### Config Writing

Uses full content string comparison — builds the desired `.env` content, compares with existing file via `cat`, only writes if different. Simple enough to not need Node.js.

## Files Created/Modified

| File | Description |
|------|-------------|
| `~/.gemini/.env` | API configuration (mode `0600`) |
| `~/.bashrc` | Alias `gm` added |
| `~/.zshrc` | Alias `gm` added |

### .env Structure

```env
GOOGLE_GEMINI_BASE_URL=https://your-api-url
GEMINI_API_KEY=your-key
GEMINI_MODEL=gemini-3-pro-preview
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GEMINI_API_URL` | _(empty)_ | API base URL (skip config if empty) |
| `GEMINI_API_KEY` | _(empty)_ | API key (skip config if empty) |
| `GEMINI_MODEL` | `gemini-3-pro-preview` | Model name |
| `GEMINI_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

## Re-run Behavior

- Install: skipped if `gemini` command exists.
- Config: full `.env` content comparison. Only writes if content differs.
- Alias: skipped if already present in rc file.

## Dependencies

- Node.js (run `setup-node.sh` first).

## Post-Install

```bash
source ~/.zshrc    # load alias
gm                 # start Gemini CLI (with -y auto-confirm)
gemini             # start Gemini CLI (standard)
```
