#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Rig Status — detect and report installation state of all components
#
# Usage:
#   bash status.sh          # Full status table
#   bash status.sh --json   # Machine-readable JSON output
#   bash status.sh --short  # One-line summary
# =============================================================================

# --- Options -----------------------------------------------------------------

OUTPUT_FORMAT="table"
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)  OUTPUT_FORMAT="json"; shift ;;
        --short) OUTPUT_FORMAT="short"; shift ;;
        --help|-h)
            echo "Usage: status.sh [--json|--short|--help]"
            echo "  --json   Machine-readable JSON output"
            echo "  --short  One-line summary"
            exit 0
            ;;
        *) shift ;;
    esac
done

# --- Colors & Symbols --------------------------------------------------------

setup_colors() {
    if [[ -t 1 ]] || [[ "${FORCE_COLOR:-}" == "1" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        BOLD='\033[1m'
        DIM='\033[2m'
        NC='\033[0m'
    else
        RED='' GREEN='' YELLOW='' CYAN='' WHITE=''
        BOLD='' DIM='' NC=''
    fi
}

setup_colors

# Status symbols
sym_installed="${GREEN}✔${NC}"
sym_partial="${YELLOW}◐${NC}"
sym_missing="${RED}✘${NC}"

# --- Helper Functions --------------------------------------------------------

# Resolve a command, checking common PATH additions
resolve_cmd() {
    local cmd="$1"
    command -v "$cmd" 2>/dev/null && return 0
    # Check common non-default paths
    local extra_paths=(
        "$HOME/.local/bin"
        "$HOME/.nvm/versions/node"/*/bin
        "$HOME/.goenv/shims"
        "$HOME/.goenv/bin"
        "/usr/local/bin"
        "$HOME/.cargo/bin"
    )
    for p in "${extra_paths[@]}"; do
        [[ -x "$p/$cmd" ]] && echo "$p/$cmd" && return 0
    done
    return 1
}

# Get version from a command, return "N/A" on failure
get_version() {
    local output
    output=$("$@" 2>/dev/null) && echo "$output" | head -1 || echo "N/A"
}

# JSON-escape a string value
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

# --- Detection Functions -----------------------------------------------------
# Each function prints: status|version|config_status
#   status:        installed / partial / not_installed
#   version:       version string or "N/A"
#   config_status: configured / install-only / not-configured

detect_shell() {
    local status="not_installed" version="N/A" config="not-configured"

    local zsh_path
    if zsh_path=$(resolve_cmd zsh); then
        version=$("$zsh_path" --version 2>/dev/null | head -1 | sed 's/zsh //' | awk '{print $1}' || echo "N/A")
        status="installed"
        config="install-only"

        # Check if zsh is the default shell
        local current_shell
        current_shell=$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "$SHELL")
        local is_default=0
        [[ "$current_shell" == *zsh* ]] && is_default=1

        # Check Oh My Zsh
        local has_omz=0
        [[ -d "$HOME/.oh-my-zsh" && -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]] && has_omz=1

        # Check Starship
        local has_starship=0
        local starship_path
        starship_path=$(resolve_cmd starship) && has_starship=1

        if [[ $is_default -eq 1 && $has_omz -eq 1 && $has_starship -eq 1 ]]; then
            config="configured"
        elif [[ $has_omz -eq 1 || $has_starship -eq 1 ]]; then
            status="partial"
            config="install-only"
        fi
    fi

    echo "${status}|${version}|${config}"
}

detect_tmux() {
    local status="not_installed" version="N/A" config="not-configured"

    local tmux_path
    if tmux_path=$(resolve_cmd tmux); then
        version=$("$tmux_path" -V 2>/dev/null | head -1 | sed 's/tmux //' || echo "N/A")
        status="installed"
        config="install-only"

        # Check TPM
        local has_tpm=0
        [[ -d "$HOME/.tmux/plugins/tpm" ]] && has_tpm=1

        # Check config file
        local has_conf=0
        [[ -f "$HOME/.tmux.conf" ]] && has_conf=1

        # Check Catppuccin theme plugin
        local has_theme=0
        [[ -d "$HOME/.tmux/plugins/tmux" ]] && has_theme=1

        if [[ $has_tpm -eq 1 && $has_conf -eq 1 && $has_theme -eq 1 ]]; then
            config="configured"
        elif [[ $has_tpm -eq 1 || $has_conf -eq 1 ]]; then
            status="partial"
            config="install-only"
        fi
    fi

    echo "${status}|${version}|${config}"
}

detect_git() {
    local status="not_installed" version="N/A" config="not-configured"

    local git_path
    if git_path=$(resolve_cmd git); then
        version=$("$git_path" --version 2>/dev/null | head -1 | sed 's/git version //' || echo "N/A")
        status="installed"
        config="install-only"

        local has_name has_email
        has_name=$(git config --global user.name 2>/dev/null || true)
        has_email=$(git config --global user.email 2>/dev/null || true)

        if [[ -n "$has_name" && -n "$has_email" ]]; then
            config="configured"
        elif [[ -n "$has_name" || -n "$has_email" ]]; then
            status="partial"
            config="install-only"
        fi
    fi

    echo "${status}|${version}|${config}"
}

detect_tools() {
    local status="not_installed" version="N/A" config="not-configured"

    # Essential tools installed by setup-tools.sh
    local tools=(rg jq fd bat tree shellcheck gh wget unzip xclip)
    local found=0
    local total=${#tools[@]}
    local missing_tools=()

    for tool in "${tools[@]}"; do
        # Handle Debian renames: fd-find→fdfind, bat→batcat
        if resolve_cmd "$tool" >/dev/null 2>&1; then
            found=$((found + 1))
        elif [[ "$tool" == "fd" ]] && resolve_cmd fdfind >/dev/null 2>&1; then
            found=$((found + 1))
        elif [[ "$tool" == "bat" ]] && resolve_cmd batcat >/dev/null 2>&1; then
            found=$((found + 1))
        else
            missing_tools+=("$tool")
        fi
    done

    if [[ $found -eq $total ]]; then
        status="installed"
        config="configured"
        version="${found}/${total} tools"
    elif [[ $found -gt 0 ]]; then
        status="partial"
        config="install-only"
        version="${found}/${total} tools"
    else
        version="0/${total} tools"
    fi

    echo "${status}|${version}|${config}"
}

detect_node() {
    local status="not_installed" version="N/A" config="not-configured"

    # Load nvm if available
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # shellcheck disable=SC1091
    [[ -f "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" 2>/dev/null

    local has_nvm=0
    local has_node=0

    [[ -f "$NVM_DIR/nvm.sh" ]] && has_nvm=1

    local node_path
    if node_path=$(resolve_cmd node); then
        has_node=1
        version=$("$node_path" --version 2>/dev/null | head -1 | sed 's/^v//' || echo "N/A")
    fi

    if [[ $has_nvm -eq 1 && $has_node -eq 1 ]]; then
        status="installed"
        config="configured"
    elif [[ $has_nvm -eq 1 ]]; then
        status="partial"
        config="install-only"
        version="nvm only"
    elif [[ $has_node -eq 1 ]]; then
        status="partial"
        config="install-only"
    fi

    echo "${status}|${version}|${config}"
}

detect_uv() {
    local status="not_installed" version="N/A" config="not-configured"

    # Add common uv location to search
    export PATH="$HOME/.local/bin:$PATH"

    local uv_path
    if uv_path=$(resolve_cmd uv); then
        version=$("$uv_path" --version 2>/dev/null | head -1 | sed 's/^uv //' || echo "N/A")
        status="installed"
        config="configured"
    fi

    echo "${status}|${version}|${config}"
}

detect_go() {
    local status="not_installed" version="N/A" config="not-configured"

    # Load goenv if available
    if [[ -d "$HOME/.goenv" ]]; then
        export GOENV_ROOT="$HOME/.goenv"
        export PATH="$GOENV_ROOT/bin:$GOENV_ROOT/shims:$PATH"
    fi

    local has_goenv=0
    local has_go=0

    [[ -d "$HOME/.goenv" && -f "$HOME/.goenv/bin/goenv" ]] && has_goenv=1

    local go_path
    if go_path=$(resolve_cmd go); then
        has_go=1
        version=$("$go_path" version 2>/dev/null | head -1 | sed 's/go version go//' | awk '{print $1}' || echo "N/A")
    fi

    if [[ $has_goenv -eq 1 && $has_go -eq 1 ]]; then
        status="installed"
        config="configured"
    elif [[ $has_goenv -eq 1 ]]; then
        status="partial"
        config="install-only"
        version="goenv only"
    elif [[ $has_go -eq 1 ]]; then
        status="partial"
        config="install-only"
    fi

    echo "${status}|${version}|${config}"
}

detect_docker() {
    local status="not_installed" version="N/A" config="not-configured"

    local docker_path
    if docker_path=$(resolve_cmd docker); then
        version=$("$docker_path" --version 2>/dev/null | head -1 | sed 's/Docker version //' | cut -d, -f1 || echo "N/A")
        status="installed"
        config="install-only"

        # Check if daemon is running
        local daemon_running=0
        if docker info &>/dev/null 2>&1; then
            daemon_running=1
        fi

        # Check if user is in docker group
        local in_group=0
        if id -nG "$USER" 2>/dev/null | grep -qw docker; then
            in_group=1
        fi

        # Check daemon.json exists
        local has_config=0
        [[ -f /etc/docker/daemon.json ]] && has_config=1

        # Check compose
        local has_compose=0
        docker compose version &>/dev/null 2>&1 && has_compose=1

        if [[ $daemon_running -eq 1 && $in_group -eq 1 ]]; then
            config="configured"
            [[ $has_compose -eq 1 ]] && version="${version} +compose"
        elif [[ $in_group -eq 1 || $has_config -eq 1 ]]; then
            status="partial"
            config="install-only"
        fi
    fi

    echo "${status}|${version}|${config}"
}

detect_tailscale() {
    local status="not_installed" version="N/A" config="not-configured"

    local tailscale_path
    if tailscale_path=$(resolve_cmd tailscale); then
        version=$("$tailscale_path" version 2>/dev/null | head -1 || echo "N/A")
        status="installed"
        config="install-only"

        # Check if connected to a tailnet
        local ts_status
        ts_status=$(tailscale status --json 2>/dev/null || echo "{}")
        local backend_state
        backend_state=$(echo "$ts_status" | grep -o '"BackendState":"[^"]*"' 2>/dev/null | cut -d'"' -f4 || true)

        if [[ "$backend_state" == "Running" ]]; then
            config="configured"
        elif [[ "$backend_state" == "NeedsLogin" || "$backend_state" == "Stopped" ]]; then
            status="partial"
        fi
    fi

    echo "${status}|${version}|${config}"
}

detect_ssh() {
    local status="not_installed" version="N/A" config="not-configured"

    local ssh_path
    if ssh_path=$(resolve_cmd ssh); then
        version=$("$ssh_path" -V 2>&1 | head -1 | sed 's/,.*//' | sed 's/OpenSSH_//' || echo "N/A")
        status="installed"
        config="install-only"

        # Check for SSH keys
        local has_keys=0
        for keyfile in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa"; do
            [[ -f "$keyfile" ]] && has_keys=1 && break
        done

        # Check authorized_keys
        local has_authkeys=0
        [[ -f "$HOME/.ssh/authorized_keys" && -s "$HOME/.ssh/authorized_keys" ]] && has_authkeys=1

        # Check if sshd is running
        local sshd_running=0
        pgrep -x sshd &>/dev/null && sshd_running=1

        if [[ $has_keys -eq 1 && $sshd_running -eq 1 ]]; then
            config="configured"
        elif [[ $has_keys -eq 1 || $has_authkeys -eq 1 || $sshd_running -eq 1 ]]; then
            status="partial"
            config="install-only"
        fi
    fi

    echo "${status}|${version}|${config}"
}

detect_claude_code() {
    local status="not_installed" version="N/A" config="not-configured"

    # Load nvm for node-based CLIs
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # shellcheck disable=SC1091
    [[ -f "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" 2>/dev/null

    local claude_path
    if claude_path=$(resolve_cmd claude); then
        version=$("$claude_path" --version 2>/dev/null | head -1 || echo "N/A")
        status="installed"
        config="install-only"

        # Check settings
        local has_settings=0
        if [[ -f "$HOME/.claude/settings.json" ]]; then
            has_settings=1
        fi

        # Check API configuration
        local has_api=0
        if [[ -f "$HOME/.claude/settings.json" ]]; then
            # Check for ANTHROPIC_BASE_URL or ANTHROPIC_AUTH_TOKEN in settings
            if grep -q "ANTHROPIC_AUTH_TOKEN\|ANTHROPIC_API_KEY" "$HOME/.claude/settings.json" 2>/dev/null; then
                has_api=1
            fi
        fi

        # Check onboarding
        local has_onboarding=0
        if [[ -f "$HOME/.claude.json" ]] && grep -q '"hasCompletedOnboarding"' "$HOME/.claude.json" 2>/dev/null; then
            has_onboarding=1
        fi

        if [[ $has_api -eq 1 ]]; then
            config="configured"
        elif [[ $has_settings -eq 1 || $has_onboarding -eq 1 ]]; then
            status="partial"
            config="install-only"
        fi
    fi

    echo "${status}|${version}|${config}"
}

detect_codex() {
    local status="not_installed" version="N/A" config="not-configured"

    # Load nvm for node-based CLIs
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # shellcheck disable=SC1091
    [[ -f "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" 2>/dev/null

    local codex_path
    if codex_path=$(resolve_cmd codex); then
        version=$("$codex_path" --version 2>/dev/null | head -1 || echo "N/A")
        status="installed"
        config="install-only"

        # Check config
        local has_config=0
        [[ -f "$HOME/.codex/config.toml" ]] && has_config=1

        # Check auth
        local has_auth=0
        [[ -f "$HOME/.codex/auth.json" ]] && has_auth=1

        if [[ $has_config -eq 1 && $has_auth -eq 1 ]]; then
            config="configured"
        elif [[ $has_config -eq 1 || $has_auth -eq 1 ]]; then
            status="partial"
            config="install-only"
        fi
    fi

    echo "${status}|${version}|${config}"
}

detect_gemini() {
    local status="not_installed" version="N/A" config="not-configured"

    # Load nvm for node-based CLIs
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    # shellcheck disable=SC1091
    [[ -f "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh" 2>/dev/null

    local gemini_path
    if gemini_path=$(resolve_cmd gemini); then
        version=$("$gemini_path" --version 2>/dev/null | head -1 || echo "N/A")
        status="installed"
        config="install-only"

        # Check .env config
        local has_env=0
        [[ -f "$HOME/.gemini/.env" ]] && has_env=1

        # Check for API key in .env
        local has_api=0
        if [[ $has_env -eq 1 ]] && grep -q "GEMINI_API_KEY=" "$HOME/.gemini/.env" 2>/dev/null; then
            local key_val
            key_val=$(grep "GEMINI_API_KEY=" "$HOME/.gemini/.env" | cut -d= -f2-)
            [[ -n "$key_val" ]] && has_api=1
        fi

        if [[ $has_api -eq 1 ]]; then
            config="configured"
        elif [[ $has_env -eq 1 ]]; then
            status="partial"
            config="install-only"
        fi
    fi

    echo "${status}|${version}|${config}"
}

detect_skills() {
    local status="not_installed" version="N/A" config="not-configured"

    # Check if skills are installed by looking for known skill directories.
    # NOTE: We intentionally use filesystem-only detection here instead of
    # `npx skills list -g` because npx can download and execute npm packages
    # from the network. Status checks must be read-only with no network calls.
    local skill_dirs=(
        "$HOME/.claude/agent-skills"
        "$HOME/.claude/skills"
    )
    local found_dir=""
    for d in "${skill_dirs[@]}"; do
        if [[ -d "$d" ]]; then
            found_dir="$d"
            break
        fi
    done

    # Count known skill subdirectories via filesystem inspection.
    # Skills are installed globally and may reside under the npm global prefix
    # or in the agent-skills/skills directories.
    local skill_count=0
    local known_skills=(find-skills pdf gemini-cli context7 writing-plans executing-plans codex)

    # Check skill directories for known skill names
    for d in "${skill_dirs[@]}"; do
        [[ -d "$d" ]] || continue
        for skill_name in "${known_skills[@]}"; do
            [[ -d "$d/$skill_name" ]] && skill_count=$((skill_count + 1))
        done
    done

    # Also check npm global lib for the skills CLI package itself
    if [[ $skill_count -eq 0 ]]; then
        local npm_prefix=""
        # Check common global npm module locations without network calls
        local global_dirs=(
            "$HOME/.npm-global/lib/node_modules/@anthropic/agent-skills"
            "$HOME/.npm-global/lib/node_modules/agent-skills"
        )
        # Try npm prefix if npm is available (local operation, no network)
        local npm_path
        if npm_path=$(resolve_cmd npm); then
            npm_prefix=$("$npm_path" config get prefix 2>/dev/null || true)
            if [[ -n "$npm_prefix" ]]; then
                global_dirs+=(
                    "$npm_prefix/lib/node_modules/@anthropic/agent-skills"
                    "$npm_prefix/lib/node_modules/agent-skills"
                )
            fi
        fi
        for gd in "${global_dirs[@]}"; do
            if [[ -d "$gd" ]]; then
                # Package exists globally; count skills inside if possible
                for skill_name in "${known_skills[@]}"; do
                    [[ -d "$gd/$skill_name" ]] && skill_count=$((skill_count + 1))
                done
                [[ -z "$found_dir" ]] && found_dir="$gd"
                break
            fi
        done
    fi

    if [[ $skill_count -gt 0 ]]; then
        status="installed"
        config="configured"
        version="${skill_count} skill(s)"
    elif [[ -n "$found_dir" ]]; then
        status="partial"
        config="install-only"
        version="dir exists"
    fi

    echo "${status}|${version}|${config}"
}

detect_essential_tools() {
    # This is a meta-check for the overall Essential Tools component from setup-tools.sh
    # It checks whether the full set is properly installed with symlinks
    local status="not_installed" version="N/A" config="not-configured"

    local core_tools=(rg jq fd bat gh)
    local found=0
    local total=${#core_tools[@]}

    for tool in "${core_tools[@]}"; do
        if resolve_cmd "$tool" >/dev/null 2>&1; then
            found=$((found + 1))
        elif [[ "$tool" == "fd" ]] && resolve_cmd fdfind >/dev/null 2>&1; then
            found=$((found + 1))
        elif [[ "$tool" == "bat" ]] && resolve_cmd batcat >/dev/null 2>&1; then
            found=$((found + 1))
        fi
    done

    # Check symlinks for Debian renames
    local symlinks_ok=1
    if resolve_cmd fdfind >/dev/null 2>&1 && ! resolve_cmd fd >/dev/null 2>&1; then
        symlinks_ok=0
    fi
    if resolve_cmd batcat >/dev/null 2>&1 && ! resolve_cmd bat >/dev/null 2>&1; then
        symlinks_ok=0
    fi

    if [[ $found -eq $total ]]; then
        status="installed"
        if [[ $symlinks_ok -eq 1 ]]; then
            config="configured"
        else
            config="install-only"
            status="partial"
        fi
        # Show gh version as representative
        local gh_path gh_ver
        if gh_path=$(resolve_cmd gh); then
            gh_ver=$("$gh_path" version 2>/dev/null | head -1 | sed 's/gh version //' | awk '{print $1}' || echo "N/A")
        else
            gh_ver="N/A"
        fi
        version="gh ${gh_ver}"
    elif [[ $found -gt 0 ]]; then
        status="partial"
        config="install-only"
        version="${found}/${total} core"
    fi

    echo "${status}|${version}|${config}"
}

# --- Output Formatters -------------------------------------------------------

# Component registry (parallel to install.sh)
COMP_IDS=(shell tmux git tools essential-tools node uv go docker tailscale ssh claude-code codex gemini skills)
COMP_NAMES=(
    "Shell Environment"
    "Tmux"
    "Git"
    "Essential Tools"
    "Essential Tools Setup"
    "Node.js (nvm)"
    "uv + Python"
    "Go (goenv)"
    "Docker"
    "Tailscale"
    "SSH"
    "Claude Code"
    "Codex CLI"
    "Gemini CLI"
    "Agent Skills"
)
COMP_DETECT=(
    detect_shell
    detect_tmux
    detect_git
    detect_tools
    detect_essential_tools
    detect_node
    detect_uv
    detect_go
    detect_docker
    detect_tailscale
    detect_ssh
    detect_claude_code
    detect_codex
    detect_gemini
    detect_skills
)

# Run all detections and store results
declare -a RESULTS=()
run_detections() {
    for detect_fn in "${COMP_DETECT[@]}"; do
        RESULTS+=("$($detect_fn)")
    done
}

print_table() {
    local total=${#COMP_IDS[@]}
    local installed=0
    local partial=0
    local missing=0

    printf "\n"
    printf "  ${CYAN}${BOLD}┌──────────────────────────────────────────────────────────────────┐${NC}\n"
    printf "  ${CYAN}${BOLD}│${NC}  ${BOLD}${WHITE}Rig Status${NC}                                                    ${CYAN}${BOLD}│${NC}\n"
    printf "  ${CYAN}${BOLD}└──────────────────────────────────────────────────────────────────┘${NC}\n"
    printf "\n"

    # Header
    printf "  ${DIM}%-4s %-24s %-18s %-16s${NC}\n" "" "Component" "Version" "Config"
    printf "  ${DIM}──── ──────────────────────── ────────────────── ────────────────${NC}\n"

    for i in $(seq 0 $((total - 1))); do
        local result="${RESULTS[$i]}"
        local comp_status comp_version comp_config
        IFS='|' read -r comp_status comp_version comp_config <<< "$result"

        # Pick symbol
        local sym
        case "$comp_status" in
            installed)     sym="$sym_installed"; installed=$((installed + 1)) ;;
            partial)       sym="$sym_partial";   partial=$((partial + 1)) ;;
            not_installed) sym="$sym_missing";   missing=$((missing + 1)) ;;
            *)             sym="$sym_missing";   missing=$((missing + 1)) ;;
        esac

        # Config display
        local config_display
        case "$comp_config" in
            configured)     config_display="${GREEN}configured${NC}" ;;
            install-only)   config_display="${YELLOW}install-only${NC}" ;;
            not-configured) config_display="${DIM}not-configured${NC}" ;;
            *)              config_display="${DIM}${comp_config}${NC}" ;;
        esac

        # Version display
        local version_display
        if [[ "$comp_version" == "N/A" ]]; then
            version_display="${DIM}N/A${NC}"
        else
            version_display="${WHITE}${comp_version}${NC}"
        fi

        printf "  %b  %-24s %-27b %-25b\n" "$sym" "${COMP_NAMES[$i]}" "$version_display" "$config_display"
    done

    # Summary
    printf "\n"
    printf "  ${DIM}──────────────────────────────────────────────────────────────────${NC}\n"
    printf "  ${GREEN}${BOLD}%d${NC}${DIM} installed${NC}" "$installed"
    [[ $partial -gt 0 ]] && printf "  ${YELLOW}${BOLD}%d${NC}${DIM} partial${NC}" "$partial"
    [[ $missing -gt 0 ]] && printf "  ${RED}${BOLD}%d${NC}${DIM} missing${NC}" "$missing"
    printf "\n\n"
}

print_json() {
    local total=${#COMP_IDS[@]}

    printf '{\n  "components": [\n'
    for i in $(seq 0 $((total - 1))); do
        local result="${RESULTS[$i]}"
        local comp_status comp_version comp_config
        IFS='|' read -r comp_status comp_version comp_config <<< "$result"

        printf '    {\n'
        printf '      "id": "%s",\n' "$(json_escape "${COMP_IDS[$i]}")"
        printf '      "name": "%s",\n' "$(json_escape "${COMP_NAMES[$i]}")"
        printf '      "status": "%s",\n' "$(json_escape "$comp_status")"
        printf '      "version": "%s",\n' "$(json_escape "$comp_version")"
        printf '      "config": "%s"\n' "$(json_escape "$comp_config")"
        if [[ $i -lt $((total - 1)) ]]; then
            printf '    },\n'
        else
            printf '    }\n'
        fi
    done

    # Summary counts
    local installed=0 partial_count=0 missing=0
    for result in "${RESULTS[@]}"; do
        local s
        s=$(echo "$result" | cut -d'|' -f1)
        case "$s" in
            installed)     installed=$((installed + 1)) ;;
            partial)       partial_count=$((partial_count + 1)) ;;
            not_installed) missing=$((missing + 1)) ;;
        esac
    done

    printf '  ],\n'
    printf '  "summary": {\n'
    printf '    "installed": %d,\n' "$installed"
    printf '    "partial": %d,\n' "$partial_count"
    printf '    "missing": %d,\n' "$missing"
    printf '    "total": %d\n' "$total"
    printf '  }\n'
    printf '}\n'
}

print_short() {
    local installed=0 partial_count=0 missing=0

    for result in "${RESULTS[@]}"; do
        local s
        s=$(echo "$result" | cut -d'|' -f1)
        case "$s" in
            installed)     installed=$((installed + 1)) ;;
            partial)       partial_count=$((partial_count + 1)) ;;
            not_installed) missing=$((missing + 1)) ;;
        esac
    done

    local total=${#COMP_IDS[@]}
    printf "rig: %d/%d installed" "$installed" "$total"
    [[ $partial_count -gt 0 ]] && printf ", %d partial" "$partial_count"
    [[ $missing -gt 0 ]] && printf ", %d missing" "$missing"
    printf "\n"
}

# --- Main --------------------------------------------------------------------

main() {
    run_detections

    case "$OUTPUT_FORMAT" in
        json)  print_json ;;
        short) print_short ;;
        table) print_table ;;
    esac
}

main
