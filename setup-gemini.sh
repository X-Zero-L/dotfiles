#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   GEMINI_API_URL=https://... GEMINI_API_KEY=cr_... ./setup-gemini.sh
#   ./setup-gemini.sh --api-url https://... --api-key cr_...
#
# Environment variables:
#   GEMINI_API_URL    - API base URL (required)
#   GEMINI_API_KEY    - API key (required)
#   GEMINI_MODEL      - Model name (default: gemini-3-pro-preview)
#   GEMINI_NPM_MIRROR - npm registry mirror (default: https://registry.npmmirror.com)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-url)  GEMINI_API_URL="$2"; shift 2 ;;
        --api-key)  GEMINI_API_KEY="$2"; shift 2 ;;
        --model)    GEMINI_MODEL="$2"; shift 2 ;;
        *) shift ;;
    esac
done

GEMINI_API_URL="${GEMINI_API_URL:-}"
GEMINI_API_KEY="${GEMINI_API_KEY:-}"
GEMINI_MODEL="${GEMINI_MODEL:-gemini-3-pro-preview}"
GEMINI_NPM_MIRROR="${GEMINI_NPM_MIRROR:-https://registry.npmmirror.com}"

if [ -z "$GEMINI_API_URL" ] || [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_URL and GEMINI_API_KEY are required."
    echo ""
    echo "Usage:"
    echo "  GEMINI_API_URL=https://... GEMINI_API_KEY=cr_... $0"
    echo "  $0 --api-url https://... --api-key cr_..."
    exit 1
fi

echo "=== Gemini CLI Setup ==="

# Ensure node is available (load nvm if present)
if ! command -v node &>/dev/null; then
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [ -f "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
fi

if ! command -v node &>/dev/null; then
    echo "Error: Node.js not found. Run setup-node.sh first."
    exit 1
fi

# Install Gemini CLI
echo "[1/3] Installing Gemini CLI..."
if command -v gemini &>/dev/null; then
    echo "  Gemini CLI already installed, upgrading..."
fi
npm install -g @google/gemini-cli --registry="$GEMINI_NPM_MIRROR"

# Write .env
echo "[2/3] Writing config..."
GEMINI_DIR="$HOME/.gemini"
mkdir -p "$GEMINI_DIR"

cat > "$GEMINI_DIR/.env" << EOF
GOOGLE_GEMINI_BASE_URL=$GEMINI_API_URL
GEMINI_API_KEY=$GEMINI_API_KEY
GEMINI_MODEL=$GEMINI_MODEL
EOF
chmod 600 "$GEMINI_DIR/.env"

# Add alias gm='gemini -y'
echo "[3/3] Adding alias..."
ALIAS_LINE="alias gm='gemini -y'"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -qF "$ALIAS_LINE" "$rc"; then
        echo "" >> "$rc"
        echo "$ALIAS_LINE" >> "$rc"
    fi
done

echo ""
echo "=== Done! ==="
echo "Gemini: $(gemini --version 2>/dev/null || echo 'installed')"
echo "Model:  $GEMINI_MODEL"
echo "API:    $GEMINI_API_URL"
echo "Run 'gemini' to start, or 'gm' to auto-approve."
