#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-tailscale.sh                              # install only
#   TAILSCALE_AUTH_KEY=tskey-auth-xxx ./setup-tailscale.sh  # install + auto connect
#
# Environment variables:
#   TAILSCALE_AUTH_KEY  - Auth key for automatic tailscale up (default: empty)

TAILSCALE_AUTH_KEY="${TAILSCALE_AUTH_KEY:-}"

echo "=== Tailscale Setup ==="

# [1/2] Install Tailscale
echo "[1/2] Installing Tailscale..."
if command -v tailscale &>/dev/null; then
    echo "  Tailscale already installed, skipping."
else
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# [2/2] Connect to Tailscale
echo "[2/2] Connecting to Tailscale..."
if [ -n "$TAILSCALE_AUTH_KEY" ]; then
    sudo tailscale up --auth-key="$TAILSCALE_AUTH_KEY" --advertise-exit-node
    echo "  Connected to Tailscale network."
else
    echo "  No auth key provided. Run 'sudo tailscale up' to connect manually."
fi

echo ""
echo "=== Done! ==="
echo "Tailscale: $(tailscale version 2>/dev/null | head -1 || echo 'installed')"
