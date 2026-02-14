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
#   DOCKER_MIRROR       - Registry mirror URL(s), comma-separated (default: empty, no mirror)
#   DOCKER_PROXY        - HTTP/HTTPS proxy for daemon and containers (default: empty)
#   DOCKER_NO_PROXY     - No-proxy list for daemon (default: localhost,127.0.0.0/8)
#   DOCKER_DATA_ROOT    - Docker data root directory (default: /var/lib/docker)
#   DOCKER_LOG_SIZE     - Max size per log file (default: 20m)
#   DOCKER_LOG_FILES    - Max number of log files (default: 3)
#   DOCKER_EXPERIMENTAL - Enable experimental features: 1=yes 0=no (default: 1)
#   DOCKER_ADDR_POOLS   - Address pools, format: base/cidr:size,... (default: 172.17.0.0/12:24,192.168.0.0/16:24)
#   DOCKER_COMPOSE      - Install docker-compose-plugin: 1=yes 0=no (default: 1)

# --- Source multi-OS libraries ------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/os-detect.sh
source "$SCRIPT_DIR/lib/os-detect.sh"
# shellcheck source=lib/pkg-maps.sh
source "$SCRIPT_DIR/lib/pkg-maps.sh"
# shellcheck source=lib/pkg-manager.sh
source "$SCRIPT_DIR/lib/pkg-manager.sh"

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

DOCKER_MIRROR="${DOCKER_MIRROR:-}"
DOCKER_PROXY="${DOCKER_PROXY:-}"
DOCKER_NO_PROXY="${DOCKER_NO_PROXY:-localhost,127.0.0.0/8}"
DOCKER_DATA_ROOT="${DOCKER_DATA_ROOT:-}"
DOCKER_LOG_SIZE="${DOCKER_LOG_SIZE:-20m}"
DOCKER_LOG_FILES="${DOCKER_LOG_FILES:-3}"
DOCKER_EXPERIMENTAL="${DOCKER_EXPERIMENTAL:-1}"
DOCKER_ADDR_POOLS="${DOCKER_ADDR_POOLS:-172.17.0.0/12:24,192.168.0.0/16:24}"
DOCKER_COMPOSE="${DOCKER_COMPOSE:-1}"

# Ensure dependencies
if ! command -v curl &>/dev/null; then
    pkg_install curl
fi

echo "=== Docker Setup ==="

# [1/5] Install Docker Engine
echo "[1/5] Installing Docker Engine..."
if is_macos; then
    # macOS: Docker Desktop is the supported way to run Docker
    if command -v docker &>/dev/null; then
        echo "  Docker already installed, skipping."
    else
        echo "  macOS detected. Docker Desktop is required."
        echo "  Please install Docker Desktop from: https://www.docker.com/products/docker-desktop/"
        echo "  Or install via Homebrew: brew install --cask docker"
        echo ""
        read -r -p "  Attempt install via 'brew install --cask docker'? [y/N] " response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            brew install --cask docker
            echo "  Docker Desktop installed. Please launch it from Applications."
        else
            echo "  Skipping Docker install. Re-run this script after installing Docker Desktop."
            exit 1
        fi
    fi
else
    # Linux: Docker Engine via get.docker.com (supports multiple distros)
    if command -v docker &>/dev/null; then
        echo "  Docker already installed, skipping."
    else
        curl -fsSL https://get.docker.com | sudo sh
    fi
fi

# [2/5] Install Docker Compose plugin
echo "[2/5] Docker Compose plugin..."
if [ "$DOCKER_COMPOSE" = "0" ]; then
    echo "  Skipped (DOCKER_COMPOSE=0)."
elif docker compose version &>/dev/null 2>&1; then
    echo "  Docker Compose already installed, skipping."
elif is_macos; then
    echo "  Docker Compose is bundled with Docker Desktop on macOS."
else
    # Linux: install docker-compose-plugin via the system package manager
    if is_debian; then
        _sudo_if_needed apt-get update -qq
        _sudo_if_needed apt-get install -y -qq docker-compose-plugin
    elif is_rhel || is_fedora; then
        _sudo_if_needed "${PKG_MANAGER}" install -y docker-compose-plugin
    elif is_arch; then
        _sudo_if_needed pacman -Sy --noconfirm docker-compose
    else
        echo "  Warning: Could not determine how to install docker-compose-plugin on this OS."
        echo "  Please install it manually."
    fi
fi

# [3/5] Add current user to docker group
echo "[3/5] Adding user to docker group..."
if is_macos; then
    echo "  Docker Desktop on macOS does not use a docker group, skipping."
else
    if id -nG "$USER" | grep -qw docker; then
        echo "  User already in docker group."
    else
        sudo usermod -aG docker "$USER"
        echo "  Added $USER to docker group."
    fi
fi

# [4/5] Configure daemon.json
echo "[4/5] Configuring Docker daemon..."
if is_macos; then
    echo "  Docker Desktop on macOS manages daemon settings via its UI/settings.json."
    echo "  Skipping daemon.json configuration."
else
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

# Registry mirrors (only if provided)
if mirrors_raw.strip():
    data['registry-mirrors'] = [m.strip() for m in mirrors_raw.split(',') if m.strip()]
elif 'registry-mirrors' in data:
    del data['registry-mirrors']

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

        # Build mirrors array (only if provided)
        MIRRORS_JSON=""
        if [ -n "$DOCKER_MIRROR" ]; then
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
        fi

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
            if [ -n "$MIRRORS_JSON" ]; then
                echo "  \"registry-mirrors\": $MIRRORS_JSON,"
            fi
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

    if [ -n "$DOCKER_MIRROR" ]; then
        echo "  Mirrors:      $DOCKER_MIRROR"
    else
        echo "  Mirrors:      (none)"
    fi
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
fi

# [5/5] Configure proxy (only if DOCKER_PROXY is set)
echo "[5/5] Configuring proxy..."
PROXY_CHANGED=0
if [ -n "$DOCKER_PROXY" ]; then
    if is_macos; then
        echo "  macOS: Configure Docker Desktop proxy in Docker Desktop > Settings > Resources > Proxies."
    else
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
    fi

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

# Restart Docker only if configuration changed (Linux only)
if ! is_macos; then
    if [ "${DAEMON_CHANGED:-0}" -eq 1 ] || [ "$PROXY_CHANGED" -eq 1 ]; then
        echo "  Restarting Docker to apply changes..."
        if command -v systemctl &>/dev/null && systemctl is-system-running &>/dev/null 2>&1; then
            sudo systemctl daemon-reload
            sudo systemctl restart docker
        elif command -v service &>/dev/null; then
            sudo service docker restart
        else
            echo "  Warning: Could not detect init system. Please restart Docker manually."
        fi
    else
        echo "  Configuration unchanged, skipping restart."
    fi
fi

echo ""
echo "=== Done! ==="
echo "Docker:  $(docker --version 2>/dev/null || echo 'installed')"
if [ "$DOCKER_COMPOSE" != "0" ]; then
    echo "Compose: $(docker compose version 2>/dev/null || echo 'installed')"
fi
echo ""
if is_macos; then
    echo "Ensure Docker Desktop is running to use Docker."
else
    echo "Run 'newgrp docker' or re-login to use Docker without sudo."
fi
