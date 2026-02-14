# setup-shell.sh

Installs zsh, Oh My Zsh, plugins, and Starship prompt with Catppuccin theme.

## OS Support

Works on all supported platforms. The script automatically uses the appropriate package manager:

| OS | Package Manager | sudo Required |
|----|----------------|---------------|
| Debian/Ubuntu | `apt` | ✓ |
| CentOS/RHEL | `yum`/`dnf` | ✓ |
| Fedora | `dnf` | ✓ |
| Arch Linux | `pacman` | ✓ |
| macOS | `brew` | Homebrew operations only |

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| zsh | Package manager | Z shell |
| git, curl, wget, vim | Package manager | Common utilities |
| Oh My Zsh | [ohmyzsh/ohmyzsh](https://github.com/ohmyzsh/ohmyzsh) | Zsh framework |
| zsh-autosuggestions | [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-like autosuggestions |
| zsh-syntax-highlighting | [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Syntax highlighting for commands |
| z | built-in Oh My Zsh plugin | Directory jumping by frecency |
| Starship | [starship.rs](https://starship.rs/) | Cross-shell prompt |

## How It Works

| Step | Action |
|------|--------|
| 1/6 | Install zsh, git, curl, wget, vim via package manager (apt/yum/dnf/pacman/brew) |
| 2/6 | Install Oh My Zsh (unattended: `RUNZSH=no CHSH=no`) |
| 3/6 | Clone autosuggestions and syntax-highlighting plugins to `$ZSH_CUSTOM/plugins/` |
| 4/6 | Edit `~/.zshrc` — add plugins to the `plugins=(...)` line |
| 5/6 | Install Starship binary, add `eval "$(starship init zsh)"` to `~/.zshrc` |
| 6/6 | Apply Catppuccin Powerline preset to `~/.config/starship.toml` |
| Final | Set zsh as default shell (Linux: `sudo chsh`, macOS: `chsh`) |

## Files Created/Modified

| File | Action |
|------|--------|
| `~/.oh-my-zsh/` | Oh My Zsh installation directory |
| `~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/` | Plugin clone |
| `~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/` | Plugin clone |
| `~/.zshrc` | Modified: plugins list, starship init |
| `~/.config/starship.toml` | Created: Catppuccin Powerline preset |
| `/etc/passwd` | Modified: user's default shell changed to zsh |

## Re-run Behavior

- apt packages: skipped if already installed (handled by apt).
- Oh My Zsh: skipped if `~/.oh-my-zsh/oh-my-zsh.sh` exists.
- Plugins: skipped if plugin directory and `.plugin.zsh` file exist.
- `.zshrc` plugins: skipped if `zsh-autosuggestions` already in file.
- Starship: skipped if `starship` command exists.
- Starship init: skipped if `starship init zsh` already in `.zshrc`.
- Preset: re-applied every run (overwrites `starship.toml`).
- Default shell: skipped if `$SHELL` is already zsh.

## Dependencies

- `sudo` access.
- Network access to GitHub (Oh My Zsh, plugins) and starship.rs.

## Post-Install

Run `exec zsh` or open a new terminal to start using zsh. Terminal must support a [Nerd Font](https://www.nerdfonts.com/) for Starship icons.
