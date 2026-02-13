#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   CODEX_API_URL=https://... CODEX_API_KEY=cr_... ./setup-codex.sh
#   ./setup-codex.sh --api-url https://... --api-key cr_...
#   ./setup-codex.sh --features "steer=false,collab=true"
#   ./setup-codex.sh                # install only, configure later
#
# Environment variables:
#   CODEX_API_URL     - API base URL (optional, skip config if empty)
#   CODEX_API_KEY     - API key (optional, skip config if empty)
#   CODEX_MODEL       - Model name (default: gpt-5.2)
#   CODEX_EFFORT      - Reasoning effort (default: xhigh)
#   CODEX_NPM_MIRROR  - npm registry mirror (auto-set when GH_PROXY is set)
#   CODEX_FEATURES    - Comma-separated feature flags (e.g. "steer=false,collab=true")

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-url)  CODEX_API_URL="$2"; shift 2 ;;
        --api-key)  CODEX_API_KEY="$2"; shift 2 ;;
        --model)    CODEX_MODEL="$2"; shift 2 ;;
        --effort)   CODEX_EFFORT="$2"; shift 2 ;;
        --features) CODEX_FEATURES="$2"; shift 2 ;;
        *) shift ;;
    esac
done

CODEX_API_URL="${CODEX_API_URL:-}"
CODEX_API_KEY="${CODEX_API_KEY:-}"
CODEX_MODEL="${CODEX_MODEL:-gpt-5.2}"
CODEX_EFFORT="${CODEX_EFFORT:-xhigh}"
CODEX_FEATURES="${CODEX_FEATURES:-}"
GH_PROXY="${GH_PROXY:-}"
CODEX_NPM_MIRROR="${CODEX_NPM_MIRROR:-}"
[[ -n "$GH_PROXY" && -z "$CODEX_NPM_MIRROR" ]] && CODEX_NPM_MIRROR="https://registry.npmmirror.com"
CODEX_PROVIDER="ellyecode"

HAS_KEYS=0
if [ -n "$CODEX_API_URL" ] && [ -n "$CODEX_API_KEY" ]; then
    HAS_KEYS=1
fi

echo "=== Codex CLI Setup ==="

# Ensure node is available (load nvm if present)
if ! command -v node &>/dev/null; then
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [ -f "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
fi

if ! command -v node &>/dev/null; then
    echo "Error: Node.js not found. Run setup-node.sh first."
    exit 1
fi

# Install Codex
echo "[1/4] Installing Codex CLI..."
if command -v codex &>/dev/null; then
    echo "  Already installed, skipping."
else
    npm install -g @openai/codex ${CODEX_NPM_MIRROR:+--registry="$CODEX_NPM_MIRROR"}
fi

# Write config and auth (only if API keys provided)
echo "[2/4] Writing config..."
echo "[3/4] Writing auth..."
if [ "$HAS_KEYS" -eq 1 ]; then
    CODEX_DIR="$HOME/.codex"
    mkdir -p "$CODEX_DIR"

    _CODEX_URL="$CODEX_API_URL" _CODEX_KEY="$CODEX_API_KEY" \
    _CODEX_MODEL="$CODEX_MODEL" _CODEX_EFFORT="$CODEX_EFFORT" \
    _CODEX_PROVIDER="$CODEX_PROVIDER" \
    _CODEX_FEATURES="$CODEX_FEATURES" node -e "
const fs = require('fs');
const dir = process.argv[1];
const url = process.env._CODEX_URL;
const key = process.env._CODEX_KEY;
const model = process.env._CODEX_MODEL;
const effort = process.env._CODEX_EFFORT;
const provider = process.env._CODEX_PROVIDER;
const featuresStr = process.env._CODEX_FEATURES;

// --- TOML section-based merge ---
// Parse TOML into ordered sections: [{ name, lines }]
function parseSections(text) {
    const sections = [];
    let cur = { name: '', lines: [] }; // top-level (no header)
    for (const line of text.split('\n')) {
        const m = line.match(/^\[([^\]]+)\]$/);
        if (m) {
            sections.push(cur);
            cur = { name: m[1], lines: [] };
        } else {
            cur.lines.push(line);
        }
    }
    sections.push(cur);
    return sections;
}

// Serialize sections back to TOML string
function serialize(sections) {
    const parts = [];
    for (const s of sections) {
        if (s.name) parts.push('[' + s.name + ']');
        parts.push(...s.lines);
    }
    // normalize: collapse 3+ consecutive blank lines to 2, trim trailing
    return parts.join('\n').replace(/\n{3,}/g, '\n\n').replace(/\n+$/, '\n');
}

// Build the desired content for a section (array of 'key = value' lines)
function buildLines(pairs) {
    return pairs.map(([k, v]) => k + ' = ' + v);
}

// Upsert a section: replace if exists, append if not
function upsert(sections, name, lines) {
    const idx = sections.findIndex(s => s.name === name);
    const entry = { name, lines: [...lines, ''] };
    if (idx >= 0) {
        sections[idx] = entry;
    } else {
        sections.push(entry);
    }
}

// Merge pairs into a section's lines: update existing keys, add missing, preserve unknown
function mergeLines(lines, pairs) {
    const existing = new Map();
    const order = [];
    for (const line of lines) {
        const m = line.match(/^(\S+)\s*=\s*/);
        if (m) { existing.set(m[1], line); order.push(m[1]); }
    }
    for (const [k, v] of pairs) {
        existing.set(k, k + ' = ' + v);
        if (!order.includes(k)) order.push(k);
    }
    return [...order.map(k => existing.get(k)), ''];
}

// Parse 'k=v,k=v' into [[k,v], ...], skip malformed entries
function parseKV(str) {
    return str.split(',').map(f => {
        const eq = f.indexOf('=');
        if (eq < 1) return null;
        const k = f.slice(0, eq).trim();
        const v = f.slice(eq + 1).trim();
        return (k && v) ? [k, v] : null;
    }).filter(Boolean);
}

// --- Config ---
const configPath = dir + '/config.toml';
const curConfig = fs.existsSync(configPath) ? fs.readFileSync(configPath, 'utf-8') : '';
const sections = parseSections(curConfig);

// Top-level settings: merge into existing top-level section (name === '')
const topPairs = [
    ['disable_response_storage', 'true'],
    ['model', '\"' + model + '\"'],
    ['model_provider', '\"' + provider + '\"'],
    ['model_reasoning_effort', '\"' + effort + '\"'],
    ['personality', '\"pragmatic\"'],
];
const topIdx = sections.findIndex(s => s.name === '');
if (topIdx >= 0) {
    sections[topIdx].lines = mergeLines(sections[topIdx].lines, topPairs);
} else {
    sections.unshift({ name: '', lines: [...buildLines(topPairs), ''] });
}

// Model provider section
const providerSection = 'model_providers.' + provider;
upsert(sections, providerSection, buildLines([
    ['base_url', '\"' + url + '\"'],
    ['name', '\"' + provider + '\"'],
    ['requires_openai_auth', 'true'],
    ['wire_api', '\"responses\"'],
]));

// Features section: only if CODEX_FEATURES is set
if (featuresStr) {
    const featurePairs = parseKV(featuresStr);
    if (featurePairs.length > 0) {
        const fIdx = sections.findIndex(s => s.name === 'features');
        if (fIdx >= 0) {
            sections[fIdx].lines = mergeLines(sections[fIdx].lines, featurePairs);
        } else {
            upsert(sections, 'features', buildLines(featurePairs));
        }
    }
}

const wantConfig = serialize(sections);
if (curConfig.replace(/\n+$/, '\n') === wantConfig) {
    console.log('  Config already up to date, skipping.');
} else {
    fs.writeFileSync(configPath, wantConfig);
    console.log('  Config written.');
}

// --- Auth ---
const authPath = dir + '/auth.json';
const wantAuth = JSON.stringify({ OPENAI_API_KEY: key }, null, 2) + '\n';
const curAuth = fs.existsSync(authPath) ? fs.readFileSync(authPath, 'utf-8') : '';
if (curAuth === wantAuth) {
    console.log('  Auth already up to date, skipping.');
} else {
    fs.writeFileSync(authPath, wantAuth, { mode: 0o600 });
    console.log('  Auth written.');
}
" "$CODEX_DIR"
else
    echo "  Skipped (no API keys provided). Configure later:"
    echo "    mkdir -p ~/.codex && edit ~/.codex/config.toml"
fi

# Add alias cx='codex --dangerously-bypass-approvals-and-sandbox'
echo "[4/4] Adding alias..."
ALIAS_LINE="alias cx='codex --dangerously-bypass-approvals-and-sandbox'"
for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rc" ] && ! grep -qF "$ALIAS_LINE" "$rc"; then
        echo "" >> "$rc"
        echo "$ALIAS_LINE" >> "$rc"
    fi
done

echo ""
echo "=== Done! ==="
echo "Codex: $(codex --version 2>/dev/null || echo 'installed')"
if [ "$HAS_KEYS" -eq 1 ]; then
    echo "Model: $CODEX_MODEL"
    echo "API:   $CODEX_API_URL"
fi
echo "Run 'source ~/.zshrc' or open a new terminal to use the 'cx' alias."
