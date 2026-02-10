# setup-git.sh

Configures Git global settings: user identity and sensible defaults.

## What Gets Configured

| Item | Description |
|------|-------------|
| git | Installed if missing |
| `user.name` | Global author name |
| `user.email` | Global author email |
| Defaults | `init.defaultBranch`, `pull.rebase`, `push.autoSetupRemote`, `core.autocrlf` |

## How It Works

| Step | Action |
|------|--------|
| 1/2 | Set `user.name` and `user.email` (if env vars provided) |
| 2/2 | Set sensible defaults |

## Defaults Applied

| Setting | Value | Description |
|---------|-------|-------------|
| `init.defaultBranch` | `main` | Default branch name for new repos |
| `pull.rebase` | `true` | Rebase on pull instead of merge |
| `push.autoSetupRemote` | `true` | Auto-set upstream on first push |
| `core.autocrlf` | `input` | Convert CRLF to LF on commit |

## Files Created/Modified

| File | Description |
|------|-------------|
| `~/.gitconfig` | Global Git configuration |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `GIT_USER_NAME` | _(empty)_ | `git config --global user.name` value |
| `GIT_USER_EMAIL` | _(empty)_ | `git config --global user.email` value |

## Re-run Behavior

- Config values are always overwritten with the provided values.
- Defaults are always applied.

## Dependencies

- `git` (auto-installed if missing).
- No `sudo` required (unless installing git).
