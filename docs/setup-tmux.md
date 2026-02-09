# setup-tmux.sh

Installs tmux, TPM plugin manager, Catppuccin theme, and essential plugins with full mouse interaction. Requires `sudo`.

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| tmux | apt | Terminal multiplexer |
| TPM | [tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) | Tmux Plugin Manager |
| tmux-sensible | [tmux-plugins/tmux-sensible](https://github.com/tmux-plugins/tmux-sensible) | Sensible defaults (ESC delay fix, history, etc.) |
| Catppuccin | [catppuccin/tmux](https://github.com/catppuccin/tmux) | Catppuccin Mocha theme |
| vim-tmux-navigator | [christoomey/vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator) | Seamless Ctrl+h/j/k/l navigation between vim and tmux |
| tmux-yank | [tmux-plugins/tmux-yank](https://github.com/tmux-plugins/tmux-yank) | System clipboard integration |
| tmux-resurrect | [tmux-plugins/tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Save and restore sessions |
| tmux-continuum | [tmux-plugins/tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Automatic session saving (uses resurrect) |

## Configuration Generated

The script generates `~/.tmux.conf` with these sections:

### General

- 256-color + RGB terminal support.
- Windows and panes numbered from 1 (not 0).
- `renumber-windows on` — no gaps after closing a window.
- `detach-on-destroy off` — switch to another session instead of detaching when a session is destroyed.

### Mouse Interactions

All mouse features are enabled by default (`set -g mouse on`):

| Action | Effect |
|--------|--------|
| Left-click window tab on status bar | Switch to that window |
| Left-click session name (status bar left) | Open session/window tree picker |
| Right-click on pane | Context menu: split, zoom, swap, kill |
| Right-click window tab on status bar | Context menu: rename, new window, kill |
| Right-click session name | Context menu: new session, rename, kill |
| Double-click on pane | Toggle zoom (maximize/restore) |
| Middle-click on pane | Paste buffer |
| Scroll wheel on status bar | Cycle through windows |
| Drag pane border | Resize pane |

### Quick Navigation

These keybindings work without prefix:

| Key | Action |
|-----|--------|
| `Alt+1` .. `Alt+9` | Switch to window by number |
| `Alt+n` | New window in current directory |

### Custom Keybindings (optional)

Disabled by default. Enable with `TMUX_KEYBINDS=1`:

| Key | Action | Replaces |
|-----|--------|----------|
| `Ctrl+a` | Prefix key | `Ctrl+b` |
| `Prefix + \|` | Vertical split | `Prefix + %` |
| `Prefix + -` | Horizontal split | `Prefix + "` |
| `Prefix + H/J/K/L` | Resize pane (repeatable) | — |

## How It Works

| Step | Action |
|------|--------|
| 1/4 | `sudo apt install -y tmux` (skipped if already installed) |
| 2/4 | `git clone` TPM to `~/.tmux/plugins/tpm` (supports `GH_PROXY`) |
| 3/4 | Generate `~/.tmux.conf` — compare with existing, write only if different |
| 4/4 | Clone each plugin to `~/.tmux/plugins/` (skipped if directory exists) |

## Files Created/Modified

| File | Description |
|------|-------------|
| `~/.tmux.conf` | Generated configuration |
| `~/.tmux/plugins/tpm/` | TPM installation |
| `~/.tmux/plugins/tmux-sensible/` | Plugin |
| `~/.tmux/plugins/tmux/` | Catppuccin theme |
| `~/.tmux/plugins/vim-tmux-navigator/` | Plugin |
| `~/.tmux/plugins/tmux-yank/` | Plugin |
| `~/.tmux/plugins/tmux-resurrect/` | Plugin |
| `~/.tmux/plugins/tmux-continuum/` | Plugin |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TMUX_KEYBINDS` | `0` | Enable custom keybindings (`1` to enable) |
| `TMUX_MOUSE` | `1` | Enable mouse support (`0` to disable) |
| `TMUX_STATUS_POS` | `top` | Status bar position (`top` or `bottom`) |
| `GH_PROXY` | _(empty)_ | GitHub proxy URL for git clone |

## Re-run Behavior

- tmux binary: skipped if `tmux` command exists.
- TPM: skipped if `~/.tmux/plugins/tpm` directory exists.
- Config: regenerated and compared; written only if content differs.
- Plugins: each skipped if its directory exists.

## Dependencies

- `sudo` access (for apt).
- `git` (for cloning TPM and plugins).

## Post-Install

Start a new tmux session: `tmux` or `tmux new -s work`. To reload config in an existing session: `tmux source ~/.tmux.conf`.

To manage plugins later: `Prefix + I` installs new plugins, `Prefix + U` updates plugins.
