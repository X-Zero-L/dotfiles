# setup-claude-code.sh

Installs [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI and optionally configures API credentials. Alias: `cc`.

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| Claude Code | `npm install -g @anthropic-ai/claude-code` | Anthropic's coding agent CLI |

## How It Works

| Step | Action |
|------|--------|
| 1/4 | Install Claude Code globally via npm (skipped if `claude` command exists) |
| 2/4 | Set `hasCompletedOnboarding: true` in `~/.claude.json` (skip interactive onboarding) |
| 3/4 | If API keys provided: write `~/.claude/settings.json` with API URL, key, and model. Uses Node.js to parse and compare JSON — only writes if config differs. |
| 4/4 | Add `alias cc='claude --dangerously-skip-permissions'` to `~/.bashrc` and `~/.zshrc` |

### Security

API keys are passed to the Node.js config writer via environment variables (`_CLAUDE_URL`, `_CLAUDE_KEY`, `_CLAUDE_MODEL`), not command arguments, so they are not visible in `ps aux`.

## Files Created/Modified

| File | Description |
|------|-------------|
| `~/.claude.json` | Onboarding flag (`hasCompletedOnboarding: true`) |
| `~/.claude/settings.json` | API configuration (only if keys provided) |
| `~/.bashrc` | Alias `cc` added |
| `~/.zshrc` | Alias `cc` added |

### settings.json Structure

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://your-api-url",
    "ANTHROPIC_AUTH_TOKEN": "your-key",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "permissions": { "allow": [], "deny": [] },
  "alwaysThinkingEnabled": true,
  "model": "opus"
}
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_API_URL` | _(empty)_ | API base URL (skip config if empty) |
| `CLAUDE_API_KEY` | _(empty)_ | Auth token (skip config if empty) |
| `CLAUDE_MODEL` | `opus` | Model name |
| `CLAUDE_NPM_MIRROR` | _(empty)_ | npm registry mirror. Auto-set when `GH_PROXY` is set. |

## Re-run Behavior

- Install: skipped if `claude` command exists.
- Onboarding: skipped if `hasCompletedOnboarding` is already `true`.
- Settings: Node.js compares all three fields (URL, key, model). Only writes if any differ.
- Alias: skipped if already present in rc file.

## Dependencies

- Node.js (run `setup-node.sh` first).

## Post-Install

```bash
source ~/.zshrc    # load alias
cc                 # start Claude Code (with --dangerously-skip-permissions)
claude             # start Claude Code (standard)
```
