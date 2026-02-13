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
| 2/4 | If API keys provided: merge `~/.codex/config.toml` (model, provider, features) |
| 3/4 | If API keys provided: write `~/.codex/auth.json` with API key |
| 4/4 | Add `alias cx='codex --dangerously-bypass-approvals-and-sandbox'` to rc files |

### Config Writing

A single Node.js script handles both `config.toml` and `auth.json`:

1. Parses existing `config.toml` into TOML sections.
2. Merges managed sections (top-level, `[model_providers.*]`, `[features]`) independently.
3. Preserves unmanaged sections (`[projects.*]`, `[notice.*]`, etc.) untouched.
4. Only writes if content differs (idempotent).

Each section is independently idempotent — updating one section never affects others.

API keys are passed via environment variables (`_CODEX_URL`, `_CODEX_KEY`, etc.), not command arguments.

## Files Created/Modified

| File | Description |
|------|-------------|
| `~/.codex/config.toml` | Model, provider, and feature configuration |
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

# Only written when CODEX_FEATURES is set; existing [features] preserved otherwise
[features]
steer = false
collab = true
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
| `CODEX_NPM_MIRROR` | _(empty)_ | npm registry mirror. Auto-set when `GH_PROXY` is set. |
| `CODEX_FEATURES` | _(empty)_ | Comma-separated feature flags (e.g. `steer=false,collab=true`) |

### Available Features

Features are boolean flags under `[features]`. Common ones:

| Feature | Description |
|---------|-------------|
| `steer` | When false, Enter queues commands sequentially instead of submitting immediately |
| `collab` | Enable sub-agents to parallelize work |
| `use_linux_sandbox_bwrap` | Bubblewrap sandbox with stronger filesystem/network controls (Linux) |
| `apps` | Use connected ChatGPT Apps |
| `undo` | Create ghost commits at each turn for undo |
| `js_repl` | JavaScript REPL backed by a persistent Node kernel |
| `memory_tool` | File-backed memory extraction and consolidation |

See [Codex features source](https://github.com/openai/codex/blob/main/codex-rs/core/src/features.rs) for the full list.

## Re-run Behavior

- Install: skipped if `codex` command exists.
- Config: section-based merge. Each managed section is independently compared and updated. Unmanaged sections are preserved.
- Alias: skipped if already present in rc file.

## Dependencies

- Node.js (run `setup-node.sh` first).

## Post-Install

```bash
source ~/.zshrc    # load alias
cx                 # start Codex (with --dangerously-bypass-approvals-and-sandbox)
codex              # start Codex (standard)
```
