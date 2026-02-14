#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Rig Config Export
# https://github.com/X-Zero-L/rig
#
# Exports installed component configuration to JSON + optional secrets.env.
#
# Usage:
#   bash export-config.sh                     # Export to ~/.rig/
#   bash export-config.sh --output-dir /tmp   # Custom output directory
#   bash export-config.sh --no-secrets        # Skip sensitive data
#   bash export-config.sh --json              # Print JSON to stdout only
#
# Output files:
#   rig-config.json   - Non-sensitive configuration (safe to share)
#   secrets.env       - API keys and tokens (chmod 600, gitignored)
#   .gitignore        - Auto-generated to protect secrets.env
# =============================================================================

# --- Options -----------------------------------------------------------------

OUTPUT_DIR="$HOME/.rig"
EXPORT_SECRETS=1
JSON_ONLY=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)  OUTPUT_DIR="$2"; shift 2 ;;
        --no-secrets)  EXPORT_SECRETS=0; shift ;;
        --json)        JSON_ONLY=1; shift ;;
        --help|-h)
            echo "Usage: export-config.sh [--output-dir DIR] [--no-secrets] [--json] [--help]"
            echo "  --output-dir DIR  Output directory (default: ~/.rig)"
            echo "  --no-secrets      Skip exporting API keys and tokens"
            echo "  --json            Print JSON to stdout only (no files written)"
            exit 0
            ;;
        *) shift ;;
    esac
done

# --- Colors ------------------------------------------------------------------

setup_colors() {
    if [[ -t 1 ]] || [[ "${FORCE_COLOR:-}" == "1" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        DIM='\033[2m'
        NC='\033[0m'
        SYM_CHECK="${GREEN}✔${NC}"
        SYM_WARN="${YELLOW}▲${NC}"
        SYM_CROSS="${RED}✘${NC}"
    else
        RED='' GREEN='' YELLOW='' CYAN=''
        BOLD='' DIM='' NC=''
        SYM_CHECK='[ok]' SYM_WARN='[!]' SYM_CROSS='[fail]'
    fi
}

[[ "$JSON_ONLY" -eq 0 ]] && setup_colors

# --- Helpers -----------------------------------------------------------------

# JSON-escape a string value
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# Print a JSON key-value pair (string)
json_kv() {
    printf '    "%s": "%s"' "$1" "$(json_escape "$2")"
}

# Load nvm if available
load_nvm() {
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # shellcheck disable=SC1091
    [[ -f "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" 2>/dev/null
}

# --- Detect Installed Components ---------------------------------------------

detect_installed() {
    local components=()

    # Shell
    command -v zsh &>/dev/null && components+=("shell")

    # Tmux
    command -v tmux &>/dev/null && components+=("tmux")

    # Git
    command -v git &>/dev/null && components+=("git")

    # Essential Tools
    local tools_found=0
    for t in rg jq fd bat gh; do
        command -v "$t" &>/dev/null && tools_found=$((tools_found + 1))
        [[ "$t" == "fd" ]] && command -v fdfind &>/dev/null && tools_found=$((tools_found + 1))
        [[ "$t" == "bat" ]] && command -v batcat &>/dev/null && tools_found=$((tools_found + 1))
    done
    [[ $tools_found -gt 0 ]] && components+=("tools")

    # Node
    load_nvm
    command -v node &>/dev/null && components+=("node")

    # uv
    command -v uv &>/dev/null || [[ -x "$HOME/.local/bin/uv" ]] && components+=("uv")

    # Go
    if [[ -d "$HOME/.goenv" ]]; then
        export GOENV_ROOT="$HOME/.goenv"
        export PATH="$GOENV_ROOT/bin:$GOENV_ROOT/shims:$PATH"
    fi
    command -v go &>/dev/null && components+=("go")

    # Docker
    command -v docker &>/dev/null && components+=("docker")

    # Tailscale
    command -v tailscale &>/dev/null && components+=("tailscale")

    # SSH
    command -v ssh &>/dev/null && [[ -d "$HOME/.ssh" ]] && components+=("ssh")

    # Claude Code
    command -v claude &>/dev/null && components+=("claude-code")

    # Codex
    command -v codex &>/dev/null && components+=("codex")

    # Gemini
    command -v gemini &>/dev/null && components+=("gemini")

    # Skills
    local skill_dirs=("$HOME/.claude/agent-skills" "$HOME/.claude/skills")
    for d in "${skill_dirs[@]}"; do
        [[ -d "$d" ]] && components+=("skills") && break
    done

    printf '%s\n' "${components[@]}"
}

# --- Extract Non-Sensitive Config --------------------------------------------

extract_config() {
    local json="{\n"
    json+='  "rig_version": "0.1.0",\n'
    json+="  \"exported_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\n"

    # Installed components list
    local comps
    comps=$(detect_installed)
    json+='  "components": ['
    local first=1
    while IFS= read -r comp; do
        [[ -z "$comp" ]] && continue
        [[ $first -eq 0 ]] && json+=', '
        json+="\"$comp\""
        first=0
    done <<< "$comps"
    json+="],\n"

    # Config section
    json+='  "config": {\n'

    # Git
    local git_name git_email
    git_name=$(git config --global user.name 2>/dev/null || true)
    git_email=$(git config --global user.email 2>/dev/null || true)
    json+='    "git": {\n'
    json+="$(json_kv "user_name" "${git_name}")"
    json+=',\n'
    json+="$(json_kv "user_email" "${git_email}")"
    json+='\n    },\n'

    # Node
    local node_version="N/A"
    command -v node &>/dev/null && node_version=$(node --version 2>/dev/null | sed 's/^v//')
    json+='    "node": {\n'
    json+="$(json_kv "version" "$node_version")"
    json+='\n    },\n'

    # Go
    local go_version="N/A"
    command -v go &>/dev/null && go_version=$(go version 2>/dev/null | sed 's/go version go//' | awk '{print $1}')
    json+='    "go": {\n'
    json+="$(json_kv "version" "$go_version")"
    json+='\n    },\n'

    # Docker
    local docker_mirrors=""
    if [[ -f /etc/docker/daemon.json ]]; then
        docker_mirrors=$(grep -o '"registry-mirrors"[[:space:]]*:[[:space:]]*\[[^]]*\]' /etc/docker/daemon.json 2>/dev/null || true)
    fi
    json+='    "docker": {\n'
    if [[ -n "$docker_mirrors" ]]; then
        json+="    $docker_mirrors"
    else
        json+='    "registry-mirrors": []'
    fi
    json+='\n    },\n'

    # Claude Code (non-sensitive)
    local claude_model=""
    if [[ -f "$HOME/.claude/settings.json" ]]; then
        claude_model=$(grep -o '"model"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude/settings.json" 2>/dev/null | head -1 | sed 's/.*: *"//;s/"//' || true)
    fi
    json+='    "claude_code": {\n'
    json+="$(json_kv "model" "${claude_model}")"
    json+='\n    },\n'

    # Codex (non-sensitive)
    local codex_model="" codex_effort=""
    if [[ -f "$HOME/.codex/config.toml" ]]; then
        codex_model=$(grep '^model[[:space:]]*=' "$HOME/.codex/config.toml" 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*"//;s/".*//' || true)
        codex_effort=$(grep '^model_reasoning_effort[[:space:]]*=' "$HOME/.codex/config.toml" 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*"//;s/".*//' || true)
    fi
    json+='    "codex": {\n'
    json+="$(json_kv "model" "${codex_model}")"
    json+=',\n'
    json+="$(json_kv "reasoning_effort" "${codex_effort}")"
    json+='\n    },\n'

    # Gemini (non-sensitive)
    local gemini_model=""
    if [[ -f "$HOME/.gemini/.env" ]]; then
        gemini_model=$(grep '^GEMINI_MODEL=' "$HOME/.gemini/.env" 2>/dev/null | cut -d= -f2- || true)
    fi
    json+='    "gemini": {\n'
    json+="$(json_kv "model" "${gemini_model}")"
    json+='\n    }\n'

    json+='  }\n'
    json+='}'

    printf '%b' "$json"
}

# --- Extract Secrets ---------------------------------------------------------

extract_secrets() {
    local secrets=""

    # Claude Code API
    if [[ -f "$HOME/.claude/settings.json" ]]; then
        local claude_url claude_key
        claude_url=$(grep -o '"ANTHROPIC_BASE_URL"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude/settings.json" 2>/dev/null | sed 's/.*: *"//;s/"//' || true)
        claude_key=$(grep -o '"ANTHROPIC_AUTH_TOKEN"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.claude/settings.json" 2>/dev/null | sed 's/.*: *"//;s/"//' || true)
        [[ -n "$claude_url" ]] && secrets+="CLAUDE_API_URL=${claude_url}\n"
        [[ -n "$claude_key" ]] && secrets+="CLAUDE_API_KEY=${claude_key}\n"
    fi

    # Codex API
    if [[ -f "$HOME/.codex/auth.json" ]]; then
        local codex_key
        codex_key=$(grep -o '"OPENAI_API_KEY"[[:space:]]*:[[:space:]]*"[^"]*"' "$HOME/.codex/auth.json" 2>/dev/null | sed 's/.*: *"//;s/"//' || true)
        [[ -n "$codex_key" ]] && secrets+="CODEX_API_KEY=${codex_key}\n"
    fi
    if [[ -f "$HOME/.codex/config.toml" ]]; then
        local codex_url
        codex_url=$(grep '^base_url[[:space:]]*=' "$HOME/.codex/config.toml" 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*"//;s/".*//' || true)
        [[ -n "$codex_url" ]] && secrets+="CODEX_API_URL=${codex_url}\n"
    fi

    # Gemini API
    if [[ -f "$HOME/.gemini/.env" ]]; then
        local gemini_url gemini_key
        gemini_url=$(grep '^GOOGLE_GEMINI_BASE_URL=' "$HOME/.gemini/.env" 2>/dev/null | cut -d= -f2- || true)
        gemini_key=$(grep '^GEMINI_API_KEY=' "$HOME/.gemini/.env" 2>/dev/null | cut -d= -f2- || true)
        [[ -n "$gemini_url" ]] && secrets+="GEMINI_API_URL=${gemini_url}\n"
        [[ -n "$gemini_key" ]] && secrets+="GEMINI_API_KEY=${gemini_key}\n"
    fi

    # Tailscale auth key (if stored)
    if [[ -f "$HOME/.config/tailscale/auth_key" ]]; then
        local ts_key
        ts_key=$(cat "$HOME/.config/tailscale/auth_key" 2>/dev/null || true)
        [[ -n "$ts_key" ]] && secrets+="TAILSCALE_AUTH_KEY=${ts_key}\n"
    fi

    printf '%b' "$secrets"
}

# --- Main --------------------------------------------------------------------

main() {
    local config_json
    config_json=$(extract_config)

    # JSON-only mode: print and exit
    if [[ "$JSON_ONLY" -eq 1 ]]; then
        printf '%s\n' "$config_json"
        exit 0
    fi

    # Banner
    printf "\n"
    printf "  ${CYAN}${BOLD}┌──────────────────────────────────────────┐${NC}\n"
    printf "  ${CYAN}${BOLD}│${NC}  ${BOLD}${CYAN}Rig Config Export${NC}                        ${CYAN}${BOLD}│${NC}\n"
    printf "  ${CYAN}${BOLD}└──────────────────────────────────────────┘${NC}\n"
    printf "\n"

    # Create output directory
    mkdir -p "$OUTPUT_DIR"

    # Write config JSON
    local config_file="$OUTPUT_DIR/rig-config.json"
    printf '%s\n' "$config_json" > "$config_file"
    printf "  ${SYM_CHECK} ${GREEN}Config written to ${CYAN}%s${NC}\n" "$config_file"

    # Write secrets
    if [[ "$EXPORT_SECRETS" -eq 1 ]]; then
        local secrets
        secrets=$(extract_secrets)
        if [[ -n "$secrets" ]]; then
            local secrets_file="$OUTPUT_DIR/secrets.env"
            printf "# Rig secrets — exported %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$secrets_file"
            printf "# WARNING: This file contains sensitive API keys. Do NOT commit to git.\n\n" >> "$secrets_file"
            printf '%b' "$secrets" >> "$secrets_file"
            chmod 600 "$secrets_file"
            printf "  ${SYM_CHECK} ${GREEN}Secrets written to ${CYAN}%s${NC} ${DIM}(chmod 600)${NC}\n" "$secrets_file"

            # Auto-generate .gitignore
            local gitignore="$OUTPUT_DIR/.gitignore"
            if [[ ! -f "$gitignore" ]] || ! grep -qF 'secrets.env' "$gitignore" 2>/dev/null; then
                printf 'secrets.env\n*.env\n' > "$gitignore"
                printf "  ${SYM_CHECK} ${GREEN}Created ${CYAN}%s${NC}\n" "$gitignore"
            fi

            printf "\n"
            printf "  ${SYM_WARN} ${YELLOW}${BOLD}secrets.env contains sensitive API keys.${NC}\n"
            printf "  ${DIM}Do not commit this file to version control.${NC}\n"
        else
            printf "  ${DIM}No secrets found to export.${NC}\n"
        fi
    else
        printf "  ${DIM}Secrets export skipped (--no-secrets).${NC}\n"
    fi

    printf "\n"
    printf "  ${DIM}To import on another machine:${NC}\n"
    printf "  ${CYAN}rig import %s${NC}\n" "$config_file"
    printf "\n"
}

main
