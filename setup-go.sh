#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-go.sh              # install goenv + Go (latest)
#   ./setup-go.sh 1.23.0       # install goenv + Go 1.23.0
#   GO_VERSION=1.23.0 ./setup-go.sh
#
# Environment variables:
#   GO_VERSION  - Go version to install (default: latest)
#   GH_PROXY    - GitHub proxy for cloning goenv (default: empty)

GO_VERSION="${GO_VERSION:-${1:-latest}}"
GH_PROXY="${GH_PROXY:-}"
GO_BUILD_MIRROR_URL="${GO_BUILD_MIRROR_URL:-}"

# Auto-set Go download mirror when behind GH_PROXY (likely in China)
if [[ -n "$GH_PROXY" && -z "$GO_BUILD_MIRROR_URL" ]]; then
    GO_BUILD_MIRROR_URL="https://mirrors.aliyun.com/golang/"
fi
export GO_BUILD_MIRROR_URL

GOENV_ROOT="$HOME/.goenv"

# Build clone URL (prevent gh-proxy content rewriting)
_GH="github.com"
GOENV_REPO="https://${_GH}/go-nv/goenv.git"
if [ -n "$GH_PROXY" ]; then
    CLONE_URL="${GH_PROXY%/}/$GOENV_REPO"
else
    CLONE_URL="$GOENV_REPO"
fi

# Ensure dependencies
for cmd in git curl; do
    if ! command -v "$cmd" &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq git curl
        break
    fi
done

echo "=== Go Environment Setup ==="

# [1/4] Install goenv
echo "[1/4] Installing goenv..."
if [ -d "$GOENV_ROOT" ] && [ -f "$GOENV_ROOT/bin/goenv" ]; then
    echo "  goenv already installed, updating..."
    git -C "$GOENV_ROOT" pull --ff-only 2>/dev/null || echo "  Update failed, continuing with existing version."
else
    # Clean up partial install
    [ -d "$GOENV_ROOT" ] && rm -rf "$GOENV_ROOT"
    git clone --depth 1 "$CLONE_URL" "$GOENV_ROOT"
fi

# [2/4] Load goenv into current shell
echo "[2/4] Loading goenv..."
export GOENV_ROOT
export PATH="$GOENV_ROOT/bin:$PATH"
# Ensure goenv shims take priority over system Go
if ! grep -q 'GOENV_PATH_ORDER' "$HOME/.goenvrc" 2>/dev/null; then
    echo 'export GOENV_PATH_ORDER=front' >> "$HOME/.goenvrc"
fi
export GOENV_PATH_ORDER=front
eval "$(goenv init -)"

# [3/4] Install Go
echo "[3/4] Installing Go ${GO_VERSION}..."
[ -n "$GO_BUILD_MIRROR_URL" ] && echo "  Download mirror: $GO_BUILD_MIRROR_URL"
if [ "$GO_VERSION" = "latest" ]; then
    # Resolve latest version number
    GO_VERSION=$(goenv install --list | grep -E '^\s*[0-9]+\.[0-9]+\.[0-9]+$' | tail -1 | tr -d ' ')
    echo "  Resolved latest: $GO_VERSION"
fi

if goenv versions --bare 2>/dev/null | grep -qxF "$GO_VERSION"; then
    echo "  Go $GO_VERSION already installed, skipping."
else
    goenv install "$GO_VERSION"
fi

goenv global "$GO_VERSION"

# [4/4] Ensure shell config
echo "[4/4] Configuring shell..."
GOENV_BLOCK='# goenv START
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
# goenv END'

for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ ! -f "$rc" ]; then
        if [ "$rc" = "$HOME/.bashrc" ]; then
            touch "$rc"
        else
            continue
        fi
    fi
    if grep -q "goenv START" "$rc"; then
        echo "  goenv block already in $(basename "$rc"), skipping."
    else
        printf '\n%s\n' "$GOENV_BLOCK" >> "$rc"
        echo "  Added goenv block to $(basename "$rc")."
    fi
done

echo ""
echo "=== Done! ==="
echo "Go:    $(go version 2>/dev/null || echo 'installed')"
echo "goenv: $(goenv --version 2>/dev/null || echo 'installed')"
echo "Run 'source ~/.zshrc' or open a new terminal to use goenv."
