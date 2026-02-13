#!/usr/bin/env bash
set -euo pipefail

echo "=== Essential Tools Setup ==="

# [1/3] Install apt packages
echo "[1/3] Installing apt packages..."
sudo apt-get update -qq
sudo apt-get install -y -qq \
    ripgrep jq fd-find bat tree shellcheck build-essential wget unzip xclip

# [2/3] Install GitHub CLI
echo "[2/3] Installing GitHub CLI..."
if command -v gh &>/dev/null; then
    echo "  gh already installed, skipping."
else
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq gh
fi

# [3/3] Create convenience symlinks (Debian renames fd-find→fdfind, bat→batcat)
echo "[3/3] Creating symlinks..."
mkdir -p "$HOME/.local/bin"
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    echo "  Created bat → batcat symlink."
else
    echo "  bat symlink not needed."
fi
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "  Created fd → fdfind symlink."
else
    echo "  fd symlink not needed."
fi

echo ""
echo "=== Done! Essential tools installed. ==="
