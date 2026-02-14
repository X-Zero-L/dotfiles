#!/usr/bin/env bash
set -euo pipefail

# Source library dependencies
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/os-detect.sh
source "$SCRIPT_DIR/lib/os-detect.sh"
# shellcheck source=lib/pkg-maps.sh
source "$SCRIPT_DIR/lib/pkg-maps.sh"
# shellcheck source=lib/pkg-manager.sh
source "$SCRIPT_DIR/lib/pkg-manager.sh"

echo "=== Essential Tools Setup ==="

# [1/3] Install packages
echo "[1/3] Installing packages..."

# macOS: Install Xcode Command Line Tools first
if is_macos; then
    if ! xcode-select -p &>/dev/null; then
        echo "  Installing Xcode Command Line Tools..."
        xcode-select --install 2>/dev/null || true
        # Wait for installation (user must click through GUI)
        echo "  Note: Please complete Xcode CLI Tools installation if prompted."
    fi
fi

# Core tools (pkg_install auto-maps names per OS and skips unavailable ones)
pkg_install ripgrep jq fd bat tree shellcheck build-tools wget unzip
# xclip: skip on macOS (pbcopy is built-in); pkg_map returns "" on macOS anyway
if ! is_macos; then
    pkg_install xclip
fi

# [2/3] Install GitHub CLI
echo "[2/3] Installing GitHub CLI..."
if command -v gh &>/dev/null; then
    echo "  gh already installed, skipping."
elif is_macos; then
    brew install gh
elif is_debian; then
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt-get update -qq
    sudo apt-get install -y -qq gh
elif is_fedora || is_rhel; then
    sudo dnf install -y 'dnf-command(config-manager)' 2>/dev/null || true
    sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
    sudo dnf install -y gh
elif is_arch; then
    sudo pacman -Sy --noconfirm github-cli
else
    echo "  Warning: Unsupported OS for GitHub CLI. Attempting install via conda-forge..."
    echo "  Please install gh manually: https://github.com/cli/cli#installation"
fi

# [3/3] Create convenience symlinks (Debian renames fd-find→fdfind, bat→batcat)
echo "[3/3] Creating symlinks..."
if is_debian; then
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
else
    echo "  Symlinks not needed on ${OS_DISTRO}."
fi

echo ""
echo "=== Done! Essential tools installed. ==="
