#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   CODEX_API_URL=https://... CODEX_API_KEY=cr_... ./setup-codex.sh
#   ./setup-codex.sh --api-url https://... --api-key cr_...
#
# Environment variables:
#   CODEX_API_URL     - API base URL (required)
#   CODEX_API_KEY     - API key (required)
#   CODEX_MODEL       - Model name (default: gpt-5.2)
#   CODEX_EFFORT      - Reasoning effort (default: xhigh)
#   CODEX_NPM_MIRROR  - npm registry mirror (default: https://registry.npmmirror.com)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-url)  CODEX_API_URL="$2"; shift 2 ;;
        --api-key)  CODEX_API_KEY="$2"; shift 2 ;;
        --model)    CODEX_MODEL="$2"; shift 2 ;;
        --effort)   CODEX_EFFORT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

CODEX_API_URL="${CODEX_API_URL:-}"
CODEX_API_KEY="${CODEX_API_KEY:-}"
CODEX_MODEL="${CODEX_MODEL:-gpt-5.2}"
CODEX_EFFORT="${CODEX_EFFORT:-xhigh}"
CODEX_NPM_MIRROR="${CODEX_NPM_MIRROR:-https://registry.npmmirror.com}"
CODEX_PROVIDER="ellyecode"

if [ -z "$CODEX_API_URL" ] || [ -z "$CODEX_API_KEY" ]; then
    echo "Error: CODEX_API_URL and CODEX_API_KEY are required."
    echo ""
    echo "Usage:"
    echo "  CODEX_API_URL=https://... CODEX_API_KEY=cr_... $0"
    echo "  $0 --api-url https://... --api-key cr_..."
    exit 1
fi

echo "=== Codex CLI Setup ==="

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

# Install Codex
echo "[1/3] Installing Codex CLI..."
if command -v codex &>/dev/null; then
    echo "  Codex already installed, upgrading..."
fi
npm install -g @openai/codex --registry="$CODEX_NPM_MIRROR"

# Write config.toml
echo "[2/3] Writing config..."
CODEX_DIR="$HOME/.codex"
mkdir -p "$CODEX_DIR"

cat > "$CODEX_DIR/config.toml" << EOF
disable_response_storage = true
model = "$CODEX_MODEL"
model_provider = "$CODEX_PROVIDER"
model_reasoning_effort = "$CODEX_EFFORT"
personality = "pragmatic"

[model_providers.$CODEX_PROVIDER]
base_url = "$CODEX_API_URL"
name = "$CODEX_PROVIDER"
requires_openai_auth = true
wire_api = "responses"
EOF

# Write auth.json
echo "[3/3] Writing auth..."
cat > "$CODEX_DIR/auth.json" << EOF
{
  "OPENAI_API_KEY": "$CODEX_API_KEY"
}
EOF
chmod 600 "$CODEX_DIR/auth.json"

echo ""
echo "=== Done! ==="
echo "Codex: $(codex --version 2>/dev/null || echo 'installed')"
echo "Model: $CODEX_MODEL"
echo "API:   $CODEX_API_URL"
echo "Run 'codex' to start."
