#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   CLASH_SUB_URL=https://your-subscription-url ./setup-clash.sh
#   ./setup-clash.sh https://your-subscription-url
#   CLASH_KERNEL=clash ./setup-clash.sh https://your-subscription-url

CLASH_SUB_URL="${CLASH_SUB_URL:-${1:-}}"
CLASH_KERNEL="${CLASH_KERNEL:-mihomo}"
CLASH_GH_PROXY="${CLASH_GH_PROXY:-https://gh-proxy.org}"

CLONE_URL="${CLASH_GH_PROXY:+${CLASH_GH_PROXY%/}/}https://github.com/nelvko/clash-for-linux-install.git"
WORK_DIR=$(mktemp -d)

cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

echo "=== Clash for Linux Setup ==="
echo "Kernel: $CLASH_KERNEL"
[ -n "$CLASH_SUB_URL" ] && echo "Subscription: (provided)"

git clone --branch master --depth 1 "$CLONE_URL" "$WORK_DIR/clash-for-linux-install"
cd "$WORK_DIR/clash-for-linux-install"

ARGS=("$CLASH_KERNEL")
[ -n "$CLASH_SUB_URL" ] && ARGS+=("$CLASH_SUB_URL")

bash install.sh "${ARGS[@]}"
