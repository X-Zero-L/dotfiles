#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-node.sh          # install nvm + Node.js 24
#   ./setup-node.sh 22       # install nvm + Node.js 22
#   NODE_VERSION=20 ./setup-node.sh

NODE_VERSION="${NODE_VERSION:-${1:-24}}"
NVM_NODEJS_ORG_MIRROR="${NVM_NODEJS_ORG_MIRROR:-}"
NPM_REGISTRY="${NPM_REGISTRY:-}"
GH_PROXY="${GH_PROXY:-}"

# Auto-set mirrors when behind GH_PROXY (likely in China)
if [[ -n "$GH_PROXY" ]]; then
    [[ -z "$NVM_NODEJS_ORG_MIRROR" ]] && NVM_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node"
    [[ -z "$NPM_REGISTRY" ]]          && NPM_REGISTRY="https://registry.npmmirror.com"
fi

# Ensure dependencies
if ! command -v curl &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq curl
fi

echo "=== Node.js Environment Setup ==="

# Install nvm
echo "[1/3] Installing nvm..."
export NVM_DIR="$HOME/.nvm"
if [ -f "$NVM_DIR/nvm.sh" ]; then
    echo "  nvm already installed, skipping."
else
    # Clean up partial install
    [ -d "$NVM_DIR" ] && rm -rf "$NVM_DIR"
    _GH="github.com"
    curl -fsSL "https://${_GH}/nvm-sh/nvm/raw/HEAD/install.sh" | bash
fi

# Load nvm into current shell
# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

# Install Node.js
echo "[2/3] Installing Node.js ${NODE_VERSION}..."
if [[ -n "$NVM_NODEJS_ORG_MIRROR" ]]; then
    export NVM_NODEJS_ORG_MIRROR
    echo "  Node mirror: $NVM_NODEJS_ORG_MIRROR"
fi
nvm install "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

# Configure npm registry
echo "[3/3] Configuring npm..."
if [[ -n "$NPM_REGISTRY" ]]; then
    npm config set registry "$NPM_REGISTRY"
    echo "  npm registry: $NPM_REGISTRY"
else
    echo "  npm registry: (default)"
fi

echo ""
echo "=== Done! ==="
echo "Node.js: $(node -v)"
echo "npm:     $(npm -v)"
echo "Run 'source ~/.zshrc' or open a new terminal to use nvm."
