#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-docker.sh
#   ./setup-docker.sh --mirror https://mirror1.example.com,https://mirror2.example.com
#   ./setup-docker.sh --proxy http://localhost:7890
#   ./setup-docker.sh --data-root /data/docker
#   ./setup-docker.sh --log-size 50m --log-files 5
#   ./setup-docker.sh --addr-pools 172.17.0.0/12:24,192.168.0.0/16:24
#   ./setup-docker.sh --no-compose --no-experimental
#
# Environment variables:
#   DOCKER_MIRROR       - Registry mirror URL(s), comma-separated (default: https://docker.1ms.run)
#   DOCKER_PROXY        - HTTP/HTTPS proxy for daemon and containers (default: empty)
#   DOCKER_NO_PROXY     - No-proxy list for daemon (default: localhost,127.0.0.0/8)
#   DOCKER_DATA_ROOT    - Docker data root directory (default: /var/lib/docker)
#   DOCKER_LOG_SIZE     - Max size per log file (default: 20m)
#   DOCKER_LOG_FILES    - Max number of log files (default: 3)
#   DOCKER_EXPERIMENTAL - Enable experimental features: 1=yes 0=no (default: 1)
#   DOCKER_ADDR_POOLS   - Address pools, format: base/cidr:size,... (default: 172.17.0.0/12:24,192.168.0.0/16:24)
#   DOCKER_COMPOSE      - Install docker-compose-plugin: 1=yes 0=no (default: 1)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mirror)          DOCKER_MIRROR="$2"; shift 2 ;;
        --proxy)           DOCKER_PROXY="$2"; shift 2 ;;
        --no-proxy)        DOCKER_NO_PROXY="$2"; shift 2 ;;
        --data-root)       DOCKER_DATA_ROOT="$2"; shift 2 ;;
        --log-size)        DOCKER_LOG_SIZE="$2"; shift 2 ;;
        --log-files)       DOCKER_LOG_FILES="$2"; shift 2 ;;
        --experimental)    DOCKER_EXPERIMENTAL=1; shift ;;
        --no-experimental) DOCKER_EXPERIMENTAL=0; shift ;;
        --addr-pools)      DOCKER_ADDR_POOLS="$2"; shift 2 ;;
        --no-compose)      DOCKER_COMPOSE=0; shift ;;
        *) shift ;;
    esac
done

DOCKER_MIRROR="${DOCKER_MIRROR:-https://docker.1ms.run}"
DOCKER_PROXY="${DOCKER_PROXY:-}"
DOCKER_NO_PROXY="${DOCKER_NO_PROXY:-localhost,127.0.0.0/8}"
DOCKER_DATA_ROOT="${DOCKER_DATA_ROOT:-}"
DOCKER_LOG_SIZE="${DOCKER_LOG_SIZE:-20m}"
DOCKER_LOG_FILES="${DOCKER_LOG_FILES:-3}"
DOCKER_EXPERIMENTAL="${DOCKER_EXPERIMENTAL:-1}"
DOCKER_ADDR_POOLS="${DOCKER_ADDR_POOLS:-172.17.0.0/12:24,192.168.0.0/16:24}"
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

# [4/5] Configure daemon.json
echo "[4/5] Configuring Docker daemon..."
DAEMON_JSON="/etc/docker/daemon.json"
sudo mkdir -p /etc/docker

# Snapshot existing config to detect changes
OLD_DAEMON_JSON=""
[ -f "$DAEMON_JSON" ] && OLD_DAEMON_JSON=$(sudo cat "$DAEMON_JSON" 2>/dev/null || true)

if command -v python3 &>/dev/null; then
    # Merge with existing daemon.json using python3 (preserves unknown keys)
    sudo python3 -c "
import json, sys, os

path        = sys.argv[1]
mirrors_raw = sys.argv[2]
data_root   = sys.argv[3]
log_size    = sys.argv[4]
log_files   = sys.argv[5]
experimental = sys.argv[6] == '1'
pools_raw   = sys.argv[7]

# Load existing
data = {}
if os.path.isfile(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except (json.JSONDecodeError, IOError):
        pass

# Registry mirrors
data['registry-mirrors'] = [m.strip() for m in mirrors_raw.split(',') if m.strip()]

# Log driver
data['log-driver'] = 'json-file'
data['log-opts'] = {'max-size': log_size, 'max-file': log_files}

# Experimental
data['experimental'] = experimental

# Data root
if data_root:
    data['data-root'] = data_root

# Address pools
if pools_raw:
    pools = []
    for entry in pools_raw.split(','):
        entry = entry.strip()
        if not entry:
            continue
        idx = entry.rfind(':')
        if idx == -1:
            continue
        base = entry[:idx]
        try:
            size = int(entry[idx+1:])
        except ValueError:
            continue
        pools.append({'base': base, 'size': size})
    if pools:
        data['default-address-pools'] = pools

with open(path, 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" "$DAEMON_JSON" "$DOCKER_MIRROR" "$DOCKER_DATA_ROOT" \
  "$DOCKER_LOG_SIZE" "$DOCKER_LOG_FILES" "$DOCKER_EXPERIMENTAL" \
  "$DOCKER_ADDR_POOLS"
else
    # Fallback: build JSON manually, attempt merge if jq or python3 unavailable
    echo "  Warning: python3 not found, writing daemon.json (existing keys not managed by this script are preserved only with python3)."

    # Build mirrors array
    IFS=',' read -ra MIRROR_ARRAY <<< "$DOCKER_MIRROR"
    MIRRORS_JSON="["
    for i in "${!MIRROR_ARRAY[@]}"; do
        m="${MIRROR_ARRAY[$i]}"
        m="${m#"${m%%[![:space:]]*}"}"
        m="${m%"${m##*[![:space:]]}"}"
        [ "$i" -gt 0 ] && MIRRORS_JSON+=","
        MIRRORS_JSON+="\"$m\""
    done
    MIRRORS_JSON+="]"

    # Build address pools array
    POOLS_JSON="["
    IFS=',' read -ra POOL_ARRAY <<< "$DOCKER_ADDR_POOLS"
    for i in "${!POOL_ARRAY[@]}"; do
        entry="${POOL_ARRAY[$i]}"
        entry="${entry#"${entry%%[![:space:]]*}"}"
        entry="${entry%"${entry##*[![:space:]]}"}"
        base="${entry%:*}"
        size="${entry##*:}"
        [ "$i" -gt 0 ] && POOLS_JSON+=","
        POOLS_JSON+="{\"base\":\"$base\",\"size\":$size}"
    done
    POOLS_JSON+="]"

    # Experimental
    if [ "$DOCKER_EXPERIMENTAL" = "1" ]; then
        EXP_JSON="true"
    else
        EXP_JSON="false"
    fi

    {
        echo '{'
        echo "  \"registry-mirrors\": $MIRRORS_JSON,"
        echo '  "log-driver": "json-file",'
        echo '  "log-opts": {'
        echo "    \"max-size\": \"$DOCKER_LOG_SIZE\","
        echo "    \"max-file\": \"$DOCKER_LOG_FILES\""
        echo '  },'
        echo "  \"experimental\": $EXP_JSON,"
        echo "  \"default-address-pools\": $POOLS_JSON"
        if [ -n "$DOCKER_DATA_ROOT" ]; then
            echo "  ,\"data-root\": \"$DOCKER_DATA_ROOT\""
        fi
        echo '}'
    } | sudo tee "$DAEMON_JSON" > /dev/null
fi

echo "  Mirrors:      $DOCKER_MIRROR"
echo "  Log:          json-file (max-size=$DOCKER_LOG_SIZE, max-file=$DOCKER_LOG_FILES)"
echo "  Experimental: $DOCKER_EXPERIMENTAL"
echo "  Addr pools:   $DOCKER_ADDR_POOLS"
[ -n "$DOCKER_DATA_ROOT" ] && echo "  Data root:    $DOCKER_DATA_ROOT"

# Detect if daemon config actually changed
NEW_DAEMON_JSON=$(sudo cat "$DAEMON_JSON" 2>/dev/null || true)
DAEMON_CHANGED=0
if [ "$OLD_DAEMON_JSON" != "$NEW_DAEMON_JSON" ]; then
    DAEMON_CHANGED=1
fi

# [5/5] Configure proxy (only if DOCKER_PROXY is set)
echo "[5/5] Configuring proxy..."
PROXY_CHANGED=0
if [ -n "$DOCKER_PROXY" ]; then
    # Daemon-level proxy (systemd drop-in)
    PROXY_DIR="/etc/systemd/system/docker.service.d"
    PROXY_CONF="$PROXY_DIR/proxy.conf"
    NEW_PROXY_CONF="[Service]
Environment=\"HTTP_PROXY=$DOCKER_PROXY\"
Environment=\"HTTPS_PROXY=$DOCKER_PROXY\"
Environment=\"NO_PROXY=$DOCKER_NO_PROXY\""

    OLD_PROXY_CONF=""
    [ -f "$PROXY_CONF" ] && OLD_PROXY_CONF=$(sudo cat "$PROXY_CONF" 2>/dev/null || true)

    if [ "$OLD_PROXY_CONF" != "$NEW_PROXY_CONF" ]; then
        sudo mkdir -p "$PROXY_DIR"
        printf '%s\n' "$NEW_PROXY_CONF" | sudo tee "$PROXY_CONF" > /dev/null
        PROXY_CHANGED=1
    fi
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
else
    echo "  No proxy configured (set DOCKER_PROXY to enable)."
fi

# Restart Docker only if configuration changed
if [ "$DAEMON_CHANGED" -eq 1 ] || [ "$PROXY_CHANGED" -eq 1 ]; then
    echo "  Restarting Docker to apply changes..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker
else
    echo "  Configuration unchanged, skipping restart."
fi

echo ""
echo "=== Done! ==="
echo "Docker:  $(docker --version 2>/dev/null || echo 'installed')"
if [ "$DOCKER_COMPOSE" != "0" ]; then
    echo "Compose: $(docker compose version 2>/dev/null || echo 'installed')"
fi
echo ""
echo "Run 'newgrp docker' or re-login to use Docker without sudo."
