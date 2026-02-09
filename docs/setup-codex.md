# setup-codex.sh

Installs [Codex CLI](https://github.com/openai/codex) and optionally configures API credentials. Alias: `cx`.

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| Codex CLI | `npm install -g @openai/codex` | OpenAI's coding agent CLI |

## How It Works

| Step | Action |
|------|--------|
| 1/4 | Install Codex globally via npm (skipped if `codex` command exists) |
| 2/4 | If API keys provided: write `~/.codex/config.toml` with model, provider, effort |
| 3/4 | If API keys provided: write `~/.codex/auth.json` with API key |
| 4/4 | Add `alias cx='codex --dangerously-bypass-approvals-and-sandbox'` to rc files |

### Config Writing

A single Node.js script handles both `config.toml` and `auth.json`:

1. Builds the desired content for each file.
2. Compares with existing content (full string comparison).
3. Only writes if content differs.

API keys are passed via environment variables (`_CODEX_URL`, `_CODEX_KEY`, etc.), not command arguments.

## Files Created/Modified

| File | Description |
|------|-------------|
| `~/.codex/config.toml` | Model and provider configuration |
| `~/.codex/auth.json` | API key (mode `0600`) |
| `~/.bashrc` | Alias `cx` added |
| `~/.zshrc` | Alias `cx` added |

### config.toml Structure

```toml
disable_response_storage = true
model = "gpt-5.2"
model_provider = "ellyecode"
model_reasoning_effort = "xhigh"
personality = "pragmatic"

[model_providers.ellyecode]
base_url = "https://your-api-url"
name = "ellyecode"
requires_openai_auth = true
wire_api = "responses"
```

### auth.json Structure

```json
{
  "OPENAI_API_KEY": "your-key"
}
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CODEX_API_URL` | _(empty)_ | API base URL (skip config if empty) |
| `CODEX_API_KEY` | _(empty)_ | API key (skip config if empty) |
| `CODEX_MODEL` | `gpt-5.2` | Model name |
| `CODEX_EFFORT` | `xhigh` | Reasoning effort |
| `CODEX_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror |

## Re-run Behavior

- Install: skipped if `codex` command exists.
- Config: full content comparison for both files. Only writes if content differs.
- Alias: skipped if already present in rc file.

## Dependencies

- Node.js (run `setup-node.sh` first).

## Post-Install

```bash
source ~/.zshrc    # load alias
cx                 # start Codex (with --dangerously-bypass-approvals-and-sandbox)
codex              # start Codex (standard)
```
