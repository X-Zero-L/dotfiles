#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-skills.sh
#   SKILLS_NPM_MIRROR=https://registry.npmmirror.com ./setup-skills.sh
#
# Environment variables:
#   SKILLS_NPM_MIRROR - npm registry mirror (auto-set when GH_PROXY is set)

GH_PROXY="${GH_PROXY:-}"
SKILLS_NPM_MIRROR="${SKILLS_NPM_MIRROR:-}"
[[ -n "$GH_PROXY" && -z "$SKILLS_NPM_MIRROR" ]] && SKILLS_NPM_MIRROR="https://registry.npmmirror.com"

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
    "X-Zero-L/agent-skills             --skill gemini-cli"
    "intellectronica/agent-skills      --skill context7"
    "obra/superpowers                  --skill writing-plans executing-plans"
    "softaworks/agent-toolkit          --skill codex"
)

TOTAL=${#SKILLS[@]}
CURRENT=0
SUCCEEDED=0
FAILED=0
FAILED_NAMES=()

for entry in "${SKILLS[@]}"; do
    CURRENT=$((CURRENT + 1))
    # Extract repo (first token) for display
    repo="${entry%% *}"
    echo ""
    echo "[$CURRENT/$TOTAL] $repo"

    # shellcheck disable=SC2086
    if npx ${SKILLS_NPM_MIRROR:+--registry="$SKILLS_NPM_MIRROR"} skills add $entry "${FLAGS[@]}"; then
        SUCCEEDED=$((SUCCEEDED + 1))
    else
        echo "  Warning: failed to install $repo, continuing..."
        FAILED=$((FAILED + 1))
        FAILED_NAMES+=("$repo")
    fi
done

echo ""
echo "=== Done! ==="
echo "Installed $SUCCEEDED/$TOTAL skill(s) globally for all agents."
if [ "$FAILED" -gt 0 ]; then
    echo "Failed ($FAILED):"
    for name in "${FAILED_NAMES[@]}"; do
        echo "  - $name"
    done
fi
echo ""
echo "Verify with: npx skills list -g"
