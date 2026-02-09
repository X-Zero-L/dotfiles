#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-skills.sh
#   SKILLS_NPM_MIRROR=https://registry.npmmirror.com ./setup-skills.sh
#
# Environment variables:
#   SKILLS_NPM_MIRROR - npm registry mirror (default: https://registry.npmmirror.com)

SKILLS_NPM_MIRROR="${SKILLS_NPM_MIRROR:-https://registry.npmmirror.com}"

echo "=== Agent Skills Setup ==="

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

# Common flags: global, all agents, skip prompts
FLAGS=(-g -a '*' -y)

# Skills to install: [repo] [--skill name ...]
SKILLS=(
    "vercel-labs/skills                --skill find-skills"
    "anthropics/skills                 --skill pdf"
    "X-Zero-L/gemini-cli-skill"
    "intellectronica/agent-skills      --skill context7"
    "obra/superpowers                  --skill writing-plans executing-plans"
    "softaworks/agent-toolkit          --skill codex"
)

TOTAL=${#SKILLS[@]}
CURRENT=0

for entry in "${SKILLS[@]}"; do
    CURRENT=$((CURRENT + 1))
    # Extract repo (first token) for display
    repo="${entry%% *}"
    echo ""
    echo "[$CURRENT/$TOTAL] $repo"

    # shellcheck disable=SC2086
    npx --registry="$SKILLS_NPM_MIRROR" skills add $entry "${FLAGS[@]}" || {
        echo "  Warning: failed to install $repo, continuing..."
    }
done

echo ""
echo "=== Done! ==="
echo "Installed $TOTAL skill(s) globally for all agents."
echo ""
echo "Verify with: npx skills list -g"
