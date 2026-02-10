#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   GIT_USER_NAME="Your Name" GIT_USER_EMAIL="you@example.com" ./setup-git.sh
#   ./setup-git.sh   # install only, skip config if env vars not set
#
# Environment variables:
#   GIT_USER_NAME  - git config --global user.name
#   GIT_USER_EMAIL - git config --global user.email

GIT_USER_NAME="${GIT_USER_NAME:-}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

# Ensure dependencies
if ! command -v git &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq git
fi

echo "=== Git Setup ==="

# [1/2] Configure user
echo "[1/2] Configuring user..."
if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
    echo "  user.name = $GIT_USER_NAME"
else
    echo "  Skipped user.name (GIT_USER_NAME not set)."
fi

if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
    echo "  user.email = $GIT_USER_EMAIL"
else
    echo "  Skipped user.email (GIT_USER_EMAIL not set)."
fi

# [2/2] Sensible defaults
echo "[2/2] Setting defaults..."
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global push.autoSetupRemote true
git config --global core.autocrlf input
echo "  init.defaultBranch = main"
echo "  pull.rebase = true"
echo "  push.autoSetupRemote = true"
echo "  core.autocrlf = input"

echo ""
echo "=== Done! ==="
echo "Git: $(git --version)"
[ -n "$GIT_USER_NAME" ] && echo "Name:  $GIT_USER_NAME" || echo "Name:  (not set)"
[ -n "$GIT_USER_EMAIL" ] && echo "Email: $GIT_USER_EMAIL" || echo "Email: (not set)"
