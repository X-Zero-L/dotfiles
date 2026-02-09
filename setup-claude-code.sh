#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   CLAUDE_API_URL=https://... CLAUDE_API_KEY=cr_... ./setup-claude-code.sh
#   ./setup-claude-code.sh --api-url https://... --api-key cr_...
#   ./setup-claude-code.sh                # install only, configure later
#
# Environment variables:
#   CLAUDE_API_URL    - API base URL (optional, skip config if empty)
#   CLAUDE_API_KEY    - Auth token (optional, skip config if empty)
#   CLAUDE_MODEL      - Model name (default: opus)
#   CLAUDE_NPM_MIRROR - npm registry mirror (default: https://registry.npmmirror.com)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-url)  CLAUDE_API_URL="$2"; shift 2 ;;
        --api-key)  CLAUDE_API_KEY="$2"; shift 2 ;;
        --model)    CLAUDE_MODEL="$2"; shift 2 ;;
        *) shift ;;
    esac
done

CLAUDE_API_URL="${CLAUDE_API_URL:-}"
CLAUDE_API_KEY="${CLAUDE_API_KEY:-}"
CLAUDE_MODEL="${CLAUDE_MODEL:-opus}"
CLAUDE_NPM_MIRROR="${CLAUDE_NPM_MIRROR:-https://registry.npmmirror.com}"

HAS_KEYS=0
if [ -n "$CLAUDE_API_URL" ] && [ -n "$CLAUDE_API_KEY" ]; then
    HAS_KEYS=1
fi

echo "=== Claude Code Setup ==="

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

# [1] Install Claude Code
echo "[1/4] Installing Claude Code..."
if command -v claude &>/dev/null; then
    echo "  Claude Code already installed, upgrading..."
fi
npm install -g @anthropic-ai/claude-code --registry="$CLAUDE_NPM_MIRROR"

# [2] Skip onboarding
echo "[2/4] Configuring onboarding..."
CLAUDE_JSON="$HOME/.claude.json"
node -e "
const fs = require('fs');
const path = process.argv[1];
const data = fs.existsSync(path)
    ? JSON.parse(fs.readFileSync(path, 'utf-8'))
    : {};
data.hasCompletedOnboarding = true;
fs.writeFileSync(path, JSON.stringify(data, null, 2));
" "$CLAUDE_JSON"

# [3] Write settings (only if API keys provided)
echo "[3/4] Writing settings..."
if [ "$HAS_KEYS" -eq 1 ]; then
    CLAUDE_SETTINGS_DIR="$HOME/.claude"
    mkdir -p "$CLAUDE_SETTINGS_DIR"
    CLAUDE_SETTINGS="$CLAUDE_SETTINGS_DIR/settings.json"

    node -e "
const fs = require('fs');
const path = process.argv[1];
const settings = fs.existsSync(path)
    ? JSON.parse(fs.readFileSync(path, 'utf-8'))
    : {};
settings.env = {
    ...settings.env,
    ANTHROPIC_BASE_URL: process.argv[2],
    ANTHROPIC_AUTH_TOKEN: process.argv[3],
    CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: '1'
};
settings.permissions = settings.permissions || { allow: [], deny: [] };
settings.alwaysThinkingEnabled = true;
settings.model = process.argv[4];
fs.writeFileSync(path, JSON.stringify(settings, null, 2));
" "$CLAUDE_SETTINGS" "$CLAUDE_API_URL" "$CLAUDE_API_KEY" "$CLAUDE_MODEL"
else
    echo "  Skipped (no API keys provided). Configure later with:"
    echo "    claude config set env.ANTHROPIC_BASE_URL <url>"
    echo "    claude config set env.ANTHROPIC_AUTH_TOKEN <key>"
fi

# [4] Add alias
echo "[4/4] Adding alias..."
ALIAS_LINE="alias cc='claude --dangerously-skip-permissions'"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -qF "$ALIAS_LINE" "$rc"; then
        echo "" >> "$rc"
        echo "$ALIAS_LINE" >> "$rc"
    fi
done

echo ""
echo "=== Done! ==="
echo "Claude Code: $(claude --version 2>/dev/null || echo 'installed')"
if [ "$HAS_KEYS" -eq 1 ]; then
    echo "Model:       $CLAUDE_MODEL"
    echo "API URL:     $CLAUDE_API_URL"
fi
echo "Run 'source ~/.zshrc' or open a new terminal to use the 'cc' alias."
