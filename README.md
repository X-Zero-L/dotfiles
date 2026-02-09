# dotfiles

[中文](README_CN.md)

Automated shell environment setup script for Debian/Ubuntu systems.

## What's Included

| Component | Description |
|-----------|-------------|
| **zsh** | Modern shell replacement for bash |
| **Oh My Zsh** | Configuration framework for zsh |
| **zsh-autosuggestions** | Fish-like autosuggestions based on history |
| **zsh-syntax-highlighting** | Syntax highlighting for the command line |
| **z** | Quick directory jumping (built-in plugin) |
| **Starship** | Cross-shell customizable prompt |
| **Catppuccin Powerline** | Starship theme preset |

## Quick Start

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

Or clone and run:

```bash
git clone https://github.com/X-Zero-L/dotfiles.git
cd dotfiles
./setup-shell.sh
```

You will be prompted for your user password (used by `chsh` to change the default shell).

After installation, run `exec zsh` or open a new terminal to apply.

## Notes

- The script is **idempotent** — safe to run multiple times.
- Requires `sudo` for installing system packages.
- Starship icons require a [Nerd Font](https://www.nerdfonts.com/) in your terminal.
