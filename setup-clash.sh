#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   CLASH_SUB_URL=https://your-subscription-url ./setup-clash.sh
#   ./setup-clash.sh https://your-subscription-url
#   CLASH_KERNEL=clash ./setup-clash.sh https://your-subscription-url

CLASH_SUB_URL="${CLASH_SUB_URL:-${1:-}}"
CLASH_KERNEL="${CLASH_KERNEL:-mihomo}"
CLASH_GH_PROXY="${CLASH_GH_PROXY:-https://gh-proxy.org}"

# Build GitHub URL dynamically to prevent gh-proxy.org from rewriting
# it when this script is fetched through the proxy.
_GH="github.com"
REPO_URL="https://${_GH}/nelvko/clash-for-linux-install.git"

if [ -n "${http_proxy:-}" ] || [ -n "${https_proxy:-}" ] || [ -n "${all_proxy:-}" ]; then
    CLONE_URL="$REPO_URL"
else
    CLONE_URL="${CLASH_GH_PROXY:+${CLASH_GH_PROXY%/}/}$REPO_URL"
fi

WORK_DIR=$(mktemp -d)

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

echo "=== Clash for Linux Setup ==="
echo "Kernel: $CLASH_KERNEL"
[ -n "$CLASH_SUB_URL" ] && echo "Subscription: (provided)"

# Check if already installed
CLASHCTL="$HOME/clashctl/scripts/cmd/clashctl.sh"
if [ -d "$HOME/clashctl" ] && [ -f "$CLASHCTL" ]; then
    echo "  Clash already installed, skipping installation."
else
    # Clean up any partial previous install
    [ -d "$HOME/clashctl" ] && rm -rf "$HOME/clashctl"

    git clone --branch master --depth 1 "$CLONE_URL" "$WORK_DIR/clash-for-linux-install"
    cd "$WORK_DIR/clash-for-linux-install"

    # Patch install.sh: remove the _quit line which exec's into an interactive
    # shell with unquoted URL (breaks URLs containing & ? etc).
    # We handle subscription ourselves after installation.
    sed -i '/^_valid_config/d; /^_quit/d' install.sh

    bash install.sh "$CLASH_KERNEL"
fi

# Ensure clashctl is sourced in both .bashrc and .zshrc
# (upstream installer may only write to .bashrc if zsh isn't installed yet)
CLASH_BLOCK="# clashctl START
# Load clashctl commands
. $CLASHCTL
# Auto-enable proxy environment
watch_proxy
# clashctl END"

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    # Create .bashrc if missing; skip .zshrc if zsh not installed yet
    if [ ! -f "$rc" ]; then
        if [ "$rc" = "$HOME/.bashrc" ]; then
            touch "$rc"
        else
            continue
        fi
    fi
    if grep -q "clashctl START" "$rc"; then
        echo "  clashctl block already in $(basename "$rc"), skipping."
    else
        printf '\n%s\n' "$CLASH_BLOCK" >> "$rc"
        echo "  Added clashctl block to $(basename "$rc")."
    fi
done

# Add subscription after installation in a clean bash subprocess,
# since clashctl.sh has unbound variables incompatible with set -u.
if [ -n "$CLASH_SUB_URL" ]; then
    if [ -f "$CLASHCTL" ]; then
        bash -c '. "$0" && clashsub add "$1" && clashsub use 1' "$CLASHCTL" "$CLASH_SUB_URL"
    else
        echo "  Warning: clashctl not found, cannot add subscription."
    fi
fi
