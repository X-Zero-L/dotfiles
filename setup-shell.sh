#!/usr/bin/env bash
set -euo pipefail

echo "=== Shell Environment Setup ==="

# 1. Install dependencies
echo "[1/6] Installing packages..."
sudo apt update -qq && sudo apt install -y zsh git curl wget vim

# 2. Install Oh My Zsh (unattended)
echo "[2/6] Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    echo "  Oh My Zsh already installed, skipping."
else
    # Clean up partial install
    [ -d "$HOME/.oh-my-zsh" ] && rm -rf "$HOME/.oh-my-zsh"
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# 3. Install zsh plugins
echo "[3/6] Installing zsh plugins..."

install_zsh_plugin() {
    local name="$1" url="$2"
    local dest="$ZSH_CUSTOM/plugins/$name"
    if [ -d "$dest" ] && [ -f "$dest/${name}.plugin.zsh" ]; then
        echo "  $name already installed."
    else
        # Clean up partial clone
        [ -d "$dest" ] && rm -rf "$dest"
        git clone --depth=1 "$url" "$dest"
    fi
}

install_zsh_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions
install_zsh_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting

# 4. Configure .zshrc plugins
echo "[4/6] Configuring .zshrc plugins..."
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC" ]; then
    echo "  Warning: .zshrc not found, skipping plugin configuration."
elif grep -q 'zsh-autosuggestions' "$ZSHRC"; then
    echo "  Plugins already configured."
else
    # Try the standard pattern first; if it doesn't match, append after any plugins=(...) line
    if grep -q '^plugins=(git)' "$ZSHRC"; then
        sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting z)/' "$ZSHRC"
    elif grep -q '^plugins=(' "$ZSHRC"; then
        # Insert our plugins into the existing plugins list (before the closing paren)
        sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions zsh-syntax-highlighting z)/' "$ZSHRC"
    else
        echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting z)' >> "$ZSHRC"
    fi
fi

# 5. Install Starship prompt (non-interactive)
echo "[5/6] Installing Starship..."
if command -v starship &>/dev/null; then
    echo "  Starship already installed."
else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Add starship init to .zshrc if not already present
if [ -f "$ZSHRC" ] && ! grep -q 'starship init zsh' "$ZSHRC"; then
    echo '' >> "$ZSHRC"
    echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
fi

# 6. Apply Starship Catppuccin Powerline preset
echo "[6/6] Applying Starship Catppuccin Powerline preset..."
mkdir -p "$HOME/.config"
starship preset catppuccin-powerline -o "$HOME/.config/starship.toml"

# 7. Change default shell to zsh (use sudo to avoid password prompt)
echo "Changing default shell to zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
    sudo chsh -s "$(which zsh)" "$USER"
fi

echo ""
echo "=== Done! Run 'exec zsh' or open a new terminal to start using zsh. ==="
