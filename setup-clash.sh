#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   CLASH_SUB_URL=https://your-subscription-url ./setup-clash.sh
#   ./setup-clash.sh https://your-subscription-url
#   CLASH_KERNEL=clash ./setup-clash.sh https://your-subscription-url

CLASH_SUB_URL="${CLASH_SUB_URL:-${1:-}}"
CLASH_KERNEL="${CLASH_KERNEL:-mihomo}"
CLASH_GH_PROXY="${CLASH_GH_PROXY:-https://gh-proxy.org}"

GITHUB_URL="https://github.com/nelvko/clash-for-linux-install.git"

# Skip gh-proxy for git clone if system proxy is already configured,
# to avoid double-proxying (gh-proxy + local proxy).
if [ -n "${http_proxy:-}" ] || [ -n "${https_proxy:-}" ] || [ -n "${all_proxy:-}" ]; then
    CLONE_URL="$GITHUB_URL"
else
    CLONE_URL="${CLASH_GH_PROXY:+${CLASH_GH_PROXY%/}/}$GITHUB_URL"
fi

WORK_DIR=$(mktemp -d)

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

echo "=== Clash for Linux Setup ==="
echo "Kernel: $CLASH_KERNEL"
[ -n "$CLASH_SUB_URL" ] && echo "Subscription: (provided)"

git clone --branch master --depth 1 "$CLONE_URL" "$WORK_DIR/clash-for-linux-install"
cd "$WORK_DIR/clash-for-linux-install"

# Patch install.sh: remove the _quit line which exec's into an interactive
# shell with unquoted URL (breaks URLs containing & ? etc).
# We handle subscription ourselves after installation.
sed -i '/^_valid_config/d; /^_quit/d' install.sh

bash install.sh "$CLASH_KERNEL"

# Add subscription after installation
if [ -n "$CLASH_SUB_URL" ]; then
    CLASHCTL="$HOME/clashctl/scripts/cmd/clashctl.sh"
    if [ -f "$CLASHCTL" ]; then
        . "$CLASHCTL"
        clashsub add "$CLASH_SUB_URL"
    fi
fi
