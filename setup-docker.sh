#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-docker.sh
#   ./setup-docker.sh --mirror https://mirror1.example.com,https://mirror2.example.com
#   ./setup-docker.sh --proxy http://localhost:7890
#   ./setup-docker.sh --no-compose
#
# Environment variables:
#   DOCKER_MIRROR    - Registry mirror URL(s), comma-separated (default: https://docker.1ms.run)
#   DOCKER_PROXY     - HTTP/HTTPS proxy for daemon and containers (default: empty)
#   DOCKER_NO_PROXY  - No-proxy list for daemon (default: localhost,127.0.0.0/8)
#   DOCKER_COMPOSE   - Install docker-compose-plugin: 1=yes 0=no (default: 1)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mirror)     DOCKER_MIRROR="$2"; shift 2 ;;
        --proxy)      DOCKER_PROXY="$2"; shift 2 ;;
        --no-proxy)   DOCKER_NO_PROXY="$2"; shift 2 ;;
        --no-compose) DOCKER_COMPOSE=0; shift ;;
        *) shift ;;
    esac
done

DOCKER_MIRROR="${DOCKER_MIRROR:-https://docker.1ms.run}"
DOCKER_PROXY="${DOCKER_PROXY:-}"
DOCKER_NO_PROXY="${DOCKER_NO_PROXY:-localhost,127.0.0.0/8}"
DOCKER_COMPOSE="${DOCKER_COMPOSE:-1}"

echo "=== Docker Setup ==="

# [1/5] Install Docker Engine
echo "[1/5] Installing Docker Engine..."
if command -v docker &>/dev/null; then
    echo "  Docker already installed, skipping."
else
    curl -fsSL https://get.docker.com | sudo sh
fi

# [2/5] Install Docker Compose plugin
echo "[2/5] Docker Compose plugin..."
if [ "$DOCKER_COMPOSE" = "0" ]; then
    echo "  Skipped (DOCKER_COMPOSE=0)."
elif docker compose version &>/dev/null 2>&1; then
    echo "  Docker Compose already installed, skipping."
else
    sudo apt-get update -qq
    sudo apt-get install -y -qq docker-compose-plugin
fi

# [3/5] Add current user to docker group
echo "[3/5] Adding user to docker group..."
if id -nG "$USER" | grep -qw docker; then
    echo "  User already in docker group."
else
    sudo usermod -aG docker "$USER"
    echo "  Added $USER to docker group."
fi

# [4/5] Configure registry mirrors
echo "[4/5] Configuring registry mirrors..."
DAEMON_JSON="/etc/docker/daemon.json"

# Build mirrors JSON array from comma-separated string
IFS=',' read -ra MIRROR_ARRAY <<< "$DOCKER_MIRROR"
MIRRORS_JSON="["
for i in "${!MIRROR_ARRAY[@]}"; do
    m="${MIRROR_ARRAY[$i]}"
    # Trim whitespace
    m="${m#"${m%%[![:space:]]*}"}"
    m="${m%"${m##*[![:space:]]}"}"
    [ "$i" -gt 0 ] && MIRRORS_JSON+=","
    MIRRORS_JSON+="\"$m\""
done
MIRRORS_JSON+="]"

if command -v python3 &>/dev/null; then
    # Merge with existing daemon.json using python3
    sudo python3 -c "
import json, sys, os
path = sys.argv[1]
mirrors = json.loads(sys.argv[2])
data = {}
if os.path.isfile(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError):
        pass
data['registry-mirrors'] = mirrors
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" "$DAEMON_JSON" "$MIRRORS_JSON"
else
    # Fallback: write directly (overwrites existing file)
    echo "  Warning: python3 not found, writing daemon.json from scratch."
    sudo mkdir -p /etc/docker
    printf '{\n  "registry-mirrors": %s\n}\n' "$MIRRORS_JSON" | sudo tee "$DAEMON_JSON" > /dev/null
fi
echo "  Mirrors: $DOCKER_MIRROR"

# [5/5] Configure proxy (only if DOCKER_PROXY is set)
echo "[5/5] Configuring proxy..."
if [ -n "$DOCKER_PROXY" ]; then
    # Daemon-level proxy (systemd drop-in)
    PROXY_DIR="/etc/systemd/system/docker.service.d"
    sudo mkdir -p "$PROXY_DIR"
    sudo tee "$PROXY_DIR/proxy.conf" > /dev/null << EOF
[Service]
Environment="HTTP_PROXY=$DOCKER_PROXY"
Environment="HTTPS_PROXY=$DOCKER_PROXY"
Environment="NO_PROXY=$DOCKER_NO_PROXY"
EOF
    echo "  Daemon proxy: $DOCKER_PROXY"

    # Container-level proxy (~/.docker/config.json)
    DOCKER_CONFIG_DIR="$HOME/.docker"
    DOCKER_CONFIG="$DOCKER_CONFIG_DIR/config.json"
    mkdir -p "$DOCKER_CONFIG_DIR"

    if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys, os
path = sys.argv[1]
proxy = sys.argv[2]
no_proxy = sys.argv[3]
data = {}
if os.path.isfile(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError):
        pass
data['proxies'] = {
    'default': {
        'httpProxy': proxy,
        'httpsProxy': proxy,
        'noProxy': no_proxy
    }
}
with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" "$DOCKER_CONFIG" "$DOCKER_PROXY" "$DOCKER_NO_PROXY"
    else
        # Fallback: write directly
        cat > "$DOCKER_CONFIG" << CEOF
{
  "proxies": {
    "default": {
      "httpProxy": "$DOCKER_PROXY",
      "httpsProxy": "$DOCKER_PROXY",
      "noProxy": "$DOCKER_NO_PROXY"
    }
  }
}
CEOF
    fi
    echo "  Container proxy: $DOCKER_PROXY"

    # Reload and restart
    sudo systemctl daemon-reload
    sudo systemctl restart docker
else
    echo "  No proxy configured (set DOCKER_PROXY to enable)."
    # Still restart to apply mirror changes
    sudo systemctl restart docker
fi

echo ""
echo "=== Done! ==="
echo "Docker:  $(docker --version 2>/dev/null || echo 'installed')"
if [ "$DOCKER_COMPOSE" != "0" ]; then
    echo "Compose: $(docker compose version 2>/dev/null || echo 'installed')"
fi
echo "Mirrors: $DOCKER_MIRROR"
[ -n "$DOCKER_PROXY" ] && echo "Proxy:   $DOCKER_PROXY"
echo ""
echo "Run 'newgrp docker' or re-login to use Docker without sudo."
