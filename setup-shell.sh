#!/usr/bin/env bash
set -euo pipefail

echo "=== Shell Environment Setup ==="

# 1. Install dependencies
echo "[1/6] Installing packages..."
sudo apt update -qq && sudo apt install -y zsh git curl wget vim

# 2. Install Oh My Zsh (unattended)
echo "[2/6] Installing Oh My Zsh..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "  Oh My Zsh already installed, skipping."
else
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# 3. Install zsh plugins
echo "[3/6] Installing zsh plugins..."
if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    echo "  zsh-autosuggestions already installed."
else
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    echo "  zsh-syntax-highlighting already installed."
else
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# 4. Configure .zshrc plugins
echo "[4/6] Configuring .zshrc plugins..."
if grep -q 'zsh-autosuggestions' "$HOME/.zshrc" 2>/dev/null; then
    echo "  Plugins already configured."
else
    sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting z)/' "$HOME/.zshrc"
fi

# 5. Install Starship prompt (non-interactive)
echo "[5/6] Installing Starship..."
if command -v starship &>/dev/null; then
    echo "  Starship already installed."
else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Add starship init to .zshrc if not already present
if ! grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null; then
    echo '' >> "$HOME/.zshrc"
    echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
fi

# 6. Apply Starship Catppuccin Powerline preset
echo "[6/6] Applying Starship Catppuccin Powerline preset..."
mkdir -p "$HOME/.config"
starship preset catppuccin-powerline -o "$HOME/.config/starship.toml"

# 7. Change default shell to zsh
echo "Changing default shell to zsh..."
if [ "$SHELL" != "$(which zsh)" ]; then
    chsh -s "$(which zsh)"
fi

echo ""
echo "=== Done! Run 'exec zsh' or open a new terminal to start using zsh. ==="
