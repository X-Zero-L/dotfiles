#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-ssh.sh                                    # ensure sshd installed
#   SSH_PORT=2222 ./setup-ssh.sh                      # change port
#   SSH_PUBKEY="ssh-ed25519 AAAA..." ./setup-ssh.sh   # add key + disable password auth
#   SSH_PRIVATE_KEY="$(cat ~/.ssh/id_ed25519)" ./setup-ssh.sh  # import private key
#
# Environment variables:
#   SSH_PORT        - custom SSH port (empty = don't change)
#   SSH_PUBKEY      - public key string. When set, adds key and disables password auth.
#   SSH_PRIVATE_KEY - private key content. When set, writes to ~/.ssh/ and derives public key.

SSH_PORT="${SSH_PORT:-}"
SSH_PUBKEY="${SSH_PUBKEY:-}"
SSH_PRIVATE_KEY="${SSH_PRIVATE_KEY:-}"

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
        if [[ "$action" == "restart" ]]; then
            pkill sshd 2>/dev/null || true
        fi
        sudo /usr/sbin/sshd
    fi
}

echo "=== SSH Setup ==="

# [1/5] Ensure sshd is running
echo "[1/5] Ensuring sshd is running..."
if pgrep -x sshd &>/dev/null; then
    echo "  sshd already running."
else
    sshd_ctl start
    echo "  sshd started."
fi

# [2/5] Import private key
echo "[2/5] Importing private key..."
if [ -n "$SSH_PRIVATE_KEY" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # Detect key type from content
    KEY_FILE="$HOME/.ssh/id_ed25519"
    if echo "$SSH_PRIVATE_KEY" | grep -q "RSA"; then
        KEY_FILE="$HOME/.ssh/id_rsa"
    elif echo "$SSH_PRIVATE_KEY" | grep -q "ECDSA"; then
        KEY_FILE="$HOME/.ssh/id_ecdsa"
    fi

    if [ -f "$KEY_FILE" ]; then
        echo "  $KEY_FILE already exists, skipping."
    else
        echo "$SSH_PRIVATE_KEY" > "$KEY_FILE"
        chmod 600 "$KEY_FILE"
        echo "  Private key written to $KEY_FILE"
    fi

    # Derive public key
    PUB_FILE="${KEY_FILE}.pub"
    if [ ! -f "$PUB_FILE" ]; then
        ssh-keygen -y -f "$KEY_FILE" > "$PUB_FILE"
        chmod 644 "$PUB_FILE"
        echo "  Public key derived to $PUB_FILE"
    fi
else
    echo "  Skipped (SSH_PRIVATE_KEY not set)."
fi

# [3/5] Configure port
echo "[3/5] Configuring port..."
if [ -n "$SSH_PORT" ]; then
    if grep -qE "^\s*Port\s+${SSH_PORT}\b" "$SSHD_CONFIG"; then
        echo "  Port already set to $SSH_PORT."
    else
        sudo cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%s)"
        sudo sed -i '/^\s*#\?\s*Port\s/d' "$SSHD_CONFIG"
        echo "Port $SSH_PORT" | sudo tee -a "$SSHD_CONFIG" >/dev/null
        echo "  Port set to $SSH_PORT."
        CHANGED=1
    fi
else
    echo "  Skipped (SSH_PORT not set)."
fi

# [4/5] Add public key to authorized_keys
echo "[4/5] Configuring authorized keys..."
if [ -n "$SSH_PUBKEY" ]; then
    AUTH_KEYS="$HOME/.ssh/authorized_keys"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    touch "$AUTH_KEYS"
    chmod 600 "$AUTH_KEYS"

    if grep -qF "$SSH_PUBKEY" "$AUTH_KEYS" 2>/dev/null; then
        echo "  Public key already in authorized_keys."
    else
        echo "$SSH_PUBKEY" >> "$AUTH_KEYS"
        echo "  Public key added to authorized_keys."
    fi
else
    echo "  Skipped (SSH_PUBKEY not set)."
fi

# [5/5] Disable password auth (only if public key was provided)
echo "[5/5] Configuring authentication..."
if [ -n "$SSH_PUBKEY" ]; then
    [ "$CHANGED" -eq 0 ] && sudo cp "$SSHD_CONFIG" "${SSHD_CONFIG}.bak.$(date +%s)"

    sudo sed -i '/^\s*#\?\s*PubkeyAuthentication\s/d' "$SSHD_CONFIG"
    echo "PubkeyAuthentication yes" | sudo tee -a "$SSHD_CONFIG" >/dev/null

    sudo sed -i '/^\s*#\?\s*PasswordAuthentication\s/d' "$SSHD_CONFIG"
    echo "PasswordAuthentication no" | sudo tee -a "$SSHD_CONFIG" >/dev/null

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
[ -n "$SSH_PRIVATE_KEY" ] && echo "Identity: imported" || echo "Identity: (unchanged)"
