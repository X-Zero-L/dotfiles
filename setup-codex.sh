#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   CODEX_API_URL=https://... CODEX_API_KEY=cr_... ./setup-codex.sh
#   ./setup-codex.sh --api-url https://... --api-key cr_...
#   ./setup-codex.sh                # install only, configure later
#
# Environment variables:
#   CODEX_API_URL     - API base URL (optional, skip config if empty)
#   CODEX_API_KEY     - API key (optional, skip config if empty)
#   CODEX_MODEL       - Model name (default: gpt-5.2)
#   CODEX_EFFORT      - Reasoning effort (default: xhigh)
#   CODEX_NPM_MIRROR  - npm registry mirror (auto-set when GH_PROXY is set)

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
GH_PROXY="${GH_PROXY:-}"
CODEX_NPM_MIRROR="${CODEX_NPM_MIRROR:-}"
[[ -n "$GH_PROXY" && -z "$CODEX_NPM_MIRROR" ]] && CODEX_NPM_MIRROR="https://registry.npmmirror.com"
CODEX_PROVIDER="ellyecode"

HAS_KEYS=0
if [ -n "$CODEX_API_URL" ] && [ -n "$CODEX_API_KEY" ]; then
    HAS_KEYS=1
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
echo "[1/4] Installing Codex CLI..."
if command -v codex &>/dev/null; then
    echo "  Already installed, skipping."
else
    npm install -g @openai/codex ${CODEX_NPM_MIRROR:+--registry="$CODEX_NPM_MIRROR"}
fi

# Write config and auth (only if API keys provided)
echo "[2/4] Writing config..."
echo "[3/4] Writing auth..."
if [ "$HAS_KEYS" -eq 1 ]; then
    CODEX_DIR="$HOME/.codex"
    mkdir -p "$CODEX_DIR"

    _CODEX_URL="$CODEX_API_URL" _CODEX_KEY="$CODEX_API_KEY" \
    _CODEX_MODEL="$CODEX_MODEL" _CODEX_EFFORT="$CODEX_EFFORT" \
    _CODEX_PROVIDER="$CODEX_PROVIDER" node -e "
const fs = require('fs');
const dir = process.argv[1];
const url = process.env._CODEX_URL;
const key = process.env._CODEX_KEY;
const model = process.env._CODEX_MODEL;
const effort = process.env._CODEX_EFFORT;
const provider = process.env._CODEX_PROVIDER;

// Check & update config.toml
const configPath = dir + '/config.toml';
const wantConfig = [
    'disable_response_storage = true',
    'model = \"' + model + '\"',
    'model_provider = \"' + provider + '\"',
    'model_reasoning_effort = \"' + effort + '\"',
    'personality = \"pragmatic\"',
    '',
    '[model_providers.' + provider + ']',
    'base_url = \"' + url + '\"',
    'name = \"' + provider + '\"',
    'requires_openai_auth = true',
    'wire_api = \"responses\"',
    ''
].join('\n');

const curConfig = fs.existsSync(configPath) ? fs.readFileSync(configPath, 'utf-8') : '';
if (curConfig === wantConfig) {
    console.log('  Config already up to date, skipping.');
} else {
    fs.writeFileSync(configPath, wantConfig);
    console.log('  Config written.');
}

// Check & update auth.json
const authPath = dir + '/auth.json';
const wantAuth = JSON.stringify({ OPENAI_API_KEY: key }, null, 2) + '\n';
const curAuth = fs.existsSync(authPath) ? fs.readFileSync(authPath, 'utf-8') : '';
if (curAuth === wantAuth) {
    console.log('  Auth already up to date, skipping.');
} else {
    fs.writeFileSync(authPath, wantAuth, { mode: 0o600 });
    console.log('  Auth written.');
}
" "$CODEX_DIR"
else
    echo "  Skipped (no API keys provided). Configure later:"
    echo "    mkdir -p ~/.codex && edit ~/.codex/config.toml"
fi

# Add alias cx='codex --dangerously-bypass-approvals-and-sandbox'
echo "[4/4] Adding alias..."
ALIAS_LINE="alias cx='codex --dangerously-bypass-approvals-and-sandbox'"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -qF "$ALIAS_LINE" "$rc"; then
        echo "" >> "$rc"
        echo "$ALIAS_LINE" >> "$rc"
    fi
done

echo ""
echo "=== Done! ==="
echo "Codex: $(codex --version 2>/dev/null || echo 'installed')"
if [ "$HAS_KEYS" -eq 1 ]; then
    echo "Model: $CODEX_MODEL"
    echo "API:   $CODEX_API_URL"
fi
echo "Run 'source ~/.zshrc' or open a new terminal to use the 'cx' alias."
