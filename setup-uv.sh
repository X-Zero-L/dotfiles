#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./setup-uv.sh
#   UV_PYTHON=3.12 ./setup-uv.sh

UV_PYTHON="${UV_PYTHON:-${1:-}}"

echo "=== uv Setup ==="

# Install uv
echo "[1/2] Installing uv..."
if command -v uv &>/dev/null; then
    echo "  uv already installed, upgrading..."
    uv self update || echo "  Warning: uv self update failed, continuing with existing version."
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Load uv into current shell
export PATH="$HOME/.local/bin:$PATH"

# Install Python if requested
if [ -n "$UV_PYTHON" ]; then
    echo "[2/2] Installing Python ${UV_PYTHON}..."
    uv python install "$UV_PYTHON"
else
    echo "[2/2] Skipping Python install (set UV_PYTHON to install a version)."
fi

echo ""
echo "=== Done! ==="
echo "uv: $(uv --version)"
[ -n "$UV_PYTHON" ] && echo "Python: $(uv python find "$UV_PYTHON" 2>/dev/null || echo "$UV_PYTHON installed")"
echo "Run 'source ~/.zshrc' or open a new terminal to use uv."
