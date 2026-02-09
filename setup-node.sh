#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-node.sh          # install nvm + Node.js 24
#   ./setup-node.sh 22       # install nvm + Node.js 22
#   NODE_VERSION=20 ./setup-node.sh

NODE_VERSION="${NODE_VERSION:-${1:-24}}"

echo "=== Node.js Environment Setup ==="

# Install nvm
echo "[1/2] Installing nvm..."
if [ -d "$HOME/.nvm" ]; then
    echo "  nvm already installed, skipping."
else
    _GH="github.com"
    curl -fsSL "https://${_GH}/nvm-sh/nvm/raw/HEAD/install.sh" | bash
fi

# Load nvm into current shell
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

# Install Node.js
echo "[2/2] Installing Node.js ${NODE_VERSION}..."
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

echo ""
echo "=== Done! ==="
echo "Node.js: $(node -v)"
echo "npm:     $(npm -v)"
echo "Run 'source ~/.zshrc' or open a new terminal to use nvm."
