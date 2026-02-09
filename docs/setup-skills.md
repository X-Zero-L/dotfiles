# setup-skills.sh

Installs common [agent skills](https://skills.sh/) globally for all coding agents (Claude Code, Codex, Gemini).

## What Gets Installed

| Skill | Source | Description |
|-------|--------|-------------|
| `find-skills` | [vercel-labs/skills](https://github.com/vercel-labs/skills) | Discover and install agent skills |
| `pdf` | [anthropics/skills](https://github.com/anthropics/skills) | PDF reading and manipulation |
| `gemini-cli-skill` | [X-Zero-L/gemini-cli-skill](https://github.com/X-Zero-L/gemini-cli-skill) | Gemini CLI integration |
| `context7` | [intellectronica/agent-skills](https://github.com/intellectronica/agent-skills) | Library documentation lookup |
| `writing-plans` | [obra/superpowers](https://github.com/obra/superpowers) | Implementation plan writing |
| `executing-plans` | [obra/superpowers](https://github.com/obra/superpowers) | Plan execution with checkpoints |
| `codex` | [softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit) | Codex agent skill |

## How It Works

For each skill, runs:

```bash
npx --registry="$SKILLS_NPM_MIRROR" skills add <repo> [--skill <name>] -g -a '*' -y
```

Flags:
- `-g` — install globally (not per-project).
- `-a '*'` — make available to all agents.
- `-y` — skip confirmation prompts.

The script tracks success/failure per skill and reports a summary at the end. A failed skill does not prevent others from installing.

## Files Created

Skills are installed to the global skills directory managed by the `skills` CLI. Location depends on the skills tool's configuration (typically `~/.skills/` or similar).

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SKILLS_NPM_MIRROR` | `https://registry.npmmirror.com` | npm registry mirror for npx |

## Re-run Behavior

The `skills add` command handles existing skills internally. Re-running the script will attempt to re-add all skills; already-installed ones are handled by the skills CLI.

## Dependencies

- Node.js (run `setup-node.sh` first).
- The `skills` CLI is invoked via `npx` (not installed globally).

## Post-Install

Verify installed skills:

```bash
npx skills list -g
```

Skills are automatically available to Claude Code, Codex, and Gemini CLI when they run.
