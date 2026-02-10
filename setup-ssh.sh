#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-ssh.sh                                    # ensure sshd installed
#   SSH_PORT=2222 ./setup-ssh.sh                      # change port
#   SSH_PUBKEY="ssh-ed25519 AAAA..." ./setup-ssh.sh   # add key + disable password auth
#   SSH_PORT=2222 SSH_PUBKEY="ssh-ed25519 AAAA..." ./setup-ssh.sh   # both
#
# Environment variables:
#   SSH_PORT   - custom SSH port (empty = don't change)
#   SSH_PUBKEY - public key string. When set, adds key and disables password auth.

SSH_PORT="${SSH_PORT:-}"
SSH_PUBKEY="${SSH_PUBKEY:-}"

# Ensure dependencies
if ! dpkg -s openssh-server &>/dev/null 2>&1; then
    sudo apt-get update -qq && sudo apt-get install -y -qq openssh-server
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
CHANGED=0

# Helper: start/restart sshd (systemd → service → direct)
sshd_ctl() {
    local action="$1"
    if command -v systemctl &>/dev/null && systemctl is-system-running &>/dev/null 2>&1; then
        sudo systemctl "$action" ssh 2>/dev/null || sudo systemctl "$action" sshd 2>/dev/null
    elif command -v service &>/dev/null; then
        sudo service ssh "$action" 2>/dev/null || sudo service sshd "$action" 2>/dev/null
    else
        # Direct: stop then start for restart, just start otherwise
        if [[ "$action" == "restart" ]]; then
            pkill sshd 2>/dev/null || true
        fi
        sudo /usr/sbin/sshd
    fi
}

echo "=== SSH Setup ==="

# [1/4] Ensure sshd is running
echo "[1/4] Ensuring sshd is running..."
if pgrep -x sshd &>/dev/null; then
    echo "  sshd already running."
else
    sshd_ctl start
    echo "  sshd started."
fi

# [2/4] Configure port
echo "[2/4] Configuring port..."
if [ -n "$SSH_PORT" ]; then
    if grep -qE "^\s*Port\s+${SSH_PORT}\b" "$SSHD_CONFIG"; then
        echo "  Port already set to $SSH_PORT."
    else
        sudo cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%s)"
        # Remove existing Port directives and add new one
        sudo sed -i '/^\s*#\?\s*Port\s/d' "$SSHD_CONFIG"
        echo "Port $SSH_PORT" | sudo tee -a "$SSHD_CONFIG" >/dev/null
        echo "  Port set to $SSH_PORT."
        CHANGED=1
    fi
else
    echo "  Skipped (SSH_PORT not set)."
fi

# [3/4] Add public key
echo "[3/4] Configuring public key..."
if [ -n "$SSH_PUBKEY" ]; then
    AUTH_KEYS="$HOME/.ssh/authorized_keys"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    touch "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"

    if grep -qF "$SSH_PUBKEY" "$AUTH_KEYS" 2>/dev/null; then
        echo "  Public key already present."
    else
        echo "$SSH_PUBKEY" >> "$AUTH_KEYS"
        echo "  Public key added."
    fi
else
    echo "  Skipped (SSH_PUBKEY not set)."
fi

# [4/4] Disable password auth (only if public key was provided)
echo "[4/4] Configuring authentication..."
if [ -n "$SSH_PUBKEY" ]; then
    [ "$CHANGED" -eq 0 ] && sudo cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%s)"

    # Enable public key auth
    sudo sed -i '/^\s*#\?\s*PubkeyAuthentication\s/d' "$SSHD_CONFIG"
    echo "PubkeyAuthentication yes" | sudo tee -a "$SSHD_CONFIG" >/dev/null

    # Disable password auth
    sudo sed -i '/^\s*#\?\s*PasswordAuthentication\s/d' "$SSHD_CONFIG"
    echo "PasswordAuthentication no" | sudo tee -a "$SSHD_CONFIG" >/dev/null

    # Disable challenge-response auth
    sudo sed -i '/^\s*#\?\s*KbdInteractiveAuthentication\s/d' "$SSHD_CONFIG"
    echo "KbdInteractiveAuthentication no" | sudo tee -a "$SSHD_CONFIG" >/dev/null

    echo "  Password auth disabled, key-only login enabled."
    CHANGED=1
else
    echo "  Skipped (no public key provided, password auth unchanged)."
fi

# Restart sshd if config changed
if [ "$CHANGED" -eq 1 ]; then
    echo ""
    echo "Restarting sshd..."
    sshd_ctl restart
    echo "  sshd restarted."
fi

echo ""
echo "=== Done! ==="
echo "SSH: $(ssh -V 2>&1)"
[ -n "$SSH_PORT" ] && echo "Port: $SSH_PORT" || echo "Port: (default)"
[ -n "$SSH_PUBKEY" ] && echo "Auth: key-only" || echo "Auth: (unchanged)"
