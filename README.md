# dotfiles

[中文](README_CN.md)

Automated setup scripts for Debian/Ubuntu systems — shell environment and proxy.

## Scripts

### `setup-shell.sh` — Shell Environment

Installs and configures:

| Component | Description |
|-----------|-------------|
| **zsh** | Modern shell replacement for bash |
| **Oh My Zsh** | Configuration framework for zsh |
| **zsh-autosuggestions** | Fish-like autosuggestions based on history |
| **zsh-syntax-highlighting** | Syntax highlighting for the command line |
| **z** | Quick directory jumping (built-in plugin) |
| **Starship** | Cross-shell customizable prompt |
| **Catppuccin Powerline** | Starship theme preset |

```bash
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-shell.sh | bash
```

You will be prompted for your user password (used by `chsh` to change the default shell).
After installation, run `exec zsh` or open a new terminal to apply.

### `setup-clash.sh` — Clash Proxy

Installs [clash-for-linux](https://github.com/nelvko/clash-for-linux-install) with optional subscription URL.

```bash
# Pass subscription URL as argument
curl -fsSL https://raw.githubusercontent.com/X-Zero-L/dotfiles/master/setup-clash.sh | bash -s -- https://your-subscription-url

# Or via environment variable
CLASH_SUB_URL=https://your-subscription-url bash setup-clash.sh
```

Supported environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLASH_SUB_URL` | _(empty)_ | Subscription URL (can also be passed as first argument) |
| `CLASH_KERNEL` | `mihomo` | Proxy kernel (`mihomo` or `clash`) |
| `CLASH_GH_PROXY` | `https://gh-proxy.org` | GitHub proxy for downloads (set empty to disable) |

After installation, use `clashsub add <url>` to manage subscriptions and `clashon`/`clashoff` to toggle proxy.

## Full Setup

Clone and run both:

```bash
git clone https://github.com/X-Zero-L/dotfiles.git
cd dotfiles
./setup-shell.sh
./setup-clash.sh https://your-subscription-url
```

## Notes

- Both scripts are **idempotent** — safe to run multiple times.
- Requires `sudo` for installing system packages.
- Starship icons require a [Nerd Font](https://www.nerdfonts.com/) in your terminal.
