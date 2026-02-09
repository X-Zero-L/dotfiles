#!/usr/bin/env bash
set -uo pipefail

# =============================================================================
# Dotfiles All-in-One Installer
# https://github.com/X-Zero-L/dotfiles
#
# Usage:
#   bash install.sh                              # Interactive TUI
#   bash install.sh --all                        # Install everything
#   bash install.sh --components shell,node,docker
#   curl -fsSL <url>/install.sh | bash           # Interactive via pipe
#   curl -fsSL <url>/install.sh | bash -s -- --all
#
# Environment variables:
#   GH_PROXY          - GitHub proxy URL (e.g. https://gh-proxy.org)
#   CLAUDE_API_URL    - API URL for Claude Code
#   CLAUDE_API_KEY    - API key for Claude Code
#   CODEX_API_URL     - API URL for Codex CLI
#   CODEX_API_KEY     - API key for Codex CLI
#   GEMINI_API_URL    - API URL for Gemini CLI
#   GEMINI_API_KEY    - API key for Gemini CLI
# =============================================================================

# --- [A] Constants -----------------------------------------------------------

# Prevent gh-proxy.org from rewriting these URLs in proxied content
_GH="github.com"
_RAW="raw.githubusercontent.com"
REPO="X-Zero-L/dotfiles"
BRANCH="master"
BASE_URL="https://${_RAW}/${REPO}/${BRANCH}"

export GH_PROXY="${GH_PROXY:-}"
NON_INTERACTIVE=0
INTERACTIVE=0
VERBOSE=0
TMPDIR_INSTALL=""
LOG_FILE=""
CURSOR_HIDDEN=0

# --- [B] ANSI Colors ---------------------------------------------------------

setup_colors() {
    if [[ -t 1 ]] || [[ "${FORCE_COLOR:-}" == "1" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        WHITE='\033[1;37m'
        BOLD='\033[1m'
        DIM='\033[2m'
        ITALIC='\033[3m'
        NC='\033[0m'
        HIDE_CURSOR='\033[?25l'
        SHOW_CURSOR='\033[?25h'
        CLEAR_LINE='\033[2K'
        # Symbols
        SYM_CHECK="${GREEN}✔${NC}"
        SYM_CROSS="${RED}✘${NC}"
        SYM_ARROW="${CYAN}▸${NC}"
        SYM_DOT="${DIM}○${NC}"
        SYM_FILL="${GREEN}●${NC}"
        SYM_WARN="${YELLOW}▲${NC}"
        SYM_DOWN="${CYAN}↓${NC}"
        SYM_PLAY="${CYAN}▶${NC}"
        SYM_KEY="${MAGENTA}🔑${NC}"
        SYM_LOCK="${DIM}🔒${NC}"
    else
        RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN='' WHITE=''
        BOLD='' DIM='' ITALIC='' NC=''
        HIDE_CURSOR='' SHOW_CURSOR='' CLEAR_LINE=''
        SYM_CHECK='[ok]' SYM_CROSS='[fail]' SYM_ARROW='>' SYM_DOT='[ ]'
        SYM_FILL='[x]' SYM_WARN='[!]' SYM_DOWN='[-]' SYM_PLAY='[>]'
        SYM_KEY='[key]' SYM_LOCK='[*]'
    fi
}

# --- [C] Component Registry --------------------------------------------------

COMP_IDS=(shell tmux clash node uv go docker tailscale claude-code codex gemini skills)

COMP_NAMES=(
    "Shell Environment"
    "Tmux"
    "Clash Proxy"
    "Node.js (nvm)"
    "uv + Python"
    "Go (goenv)"
    "Docker"
    "Tailscale"
    "Claude Code"
    "Codex CLI"
    "Gemini CLI"
    "Agent Skills"
)

COMP_DESCS=(
    "zsh, Oh My Zsh, plugins, Starship"
    "tmux + Catppuccin + TPM plugins"
    "clash-for-linux with subscription"
    "nvm + Node.js 24"
    "uv package manager"
    "goenv + Go"
    "Docker Engine + Compose + mirrors"
    "Tailscale VPN mesh network"
    "Claude Code CLI"
    "OpenAI Codex CLI"
    "Gemini CLI"
    "Skills for all coding agents"
)

COMP_SCRIPTS=(
    setup-shell.sh
    setup-tmux.sh
    setup-clash.sh
    setup-node.sh
    setup-uv.sh
    setup-go.sh
    setup-docker.sh
    setup-tailscale.sh
    setup-claude-code.sh
    setup-codex.sh
    setup-gemini.sh
    setup-skills.sh
)

# Dependencies: space-separated indices that must run first (empty = none)
COMP_DEPS=("" "" "" "" "" "" "" "" "3" "3" "3" "3")

# Whether component needs API keys (2 = token-only, 1 = url+key)
COMP_NEEDS_KEYS=(0 0 0 0 0 0 0 2 1 1 1 0)

# Whether component needs sudo
COMP_NEEDS_SUDO=(1 1 0 0 0 0 1 1 0 0 0 0)

# Selection state
COMP_SELECTED=(0 0 0 0 0 0 0 0 0 0 0 0)

# Install-only mode: tool installed but API not configured (keys missing)
COMP_INSTALL_ONLY=(0 0 0 0 0 0 0 0 0 0 0 0)

# --- [D] Utility Functions ----------------------------------------------------

SUDO_KEEPALIVE_PID=""

cleanup() {
    [[ "$CURSOR_HIDDEN" -eq 1 ]] && printf '\033[?25h' 2>/dev/null
    [[ -n "${SPINNER_PID:-}" ]] && kill "$SPINNER_PID" 2>/dev/null || true
    [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    [[ -n "${TMPDIR_INSTALL:-}" && -d "${TMPDIR_INSTALL:-}" ]] && rm -rf "$TMPDIR_INSTALL"
}
trap cleanup EXIT INT TERM

# Spinner animation (runs in background, caller must kill it)
# Usage: start_spinner "message"  →  SPINNER_PID is set
#        stop_spinner
SPINNER_PID=""

start_spinner() {
    local msg="$1"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

    # Fallback for non-unicode terminals
    if [[ -z "$BOLD" ]]; then
        frames=('-' '\' '|' '/')
    fi

    printf "${HIDE_CURSOR}" 2>/dev/null
    (
        local i=0
        while true; do
            printf "\r  ${CYAN}%s${NC} ${DIM}%s${NC}  " "${frames[$i]}" "$msg"
            i=$(( (i + 1) % ${#frames[@]} ))
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
}

stop_spinner() {
    if [[ -n "${SPINNER_PID:-}" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null || true
        SPINNER_PID=""
    fi
    printf "\r${CLEAR_LINE}"
    printf "${SHOW_CURSOR}" 2>/dev/null
}

# Pre-cache sudo credentials to avoid password prompts mid-installation
cache_sudo() {
    local needs_sudo=0
    for i in "${!COMP_SELECTED[@]}"; do
        if [[ "${COMP_SELECTED[$i]}" -eq 1 && "${COMP_NEEDS_SUDO[$i]}" -eq 1 ]]; then
            needs_sudo=1
            break
        fi
    done

    if [[ $needs_sudo -eq 1 ]]; then
        printf "  ${DIM}Some components require sudo. Caching credentials...${NC}\n"
        sudo -v
        # Keep sudo alive in background
        ( while true; do sudo -n true 2>/dev/null; sleep 50; done ) &
        SUDO_KEEPALIVE_PID=$!
    fi
}

print_banner() {
    printf "\n"
    printf "  ${CYAN}${BOLD}┌──────────────────────────────────────────┐${NC}\n"
    printf "  ${CYAN}${BOLD}│${NC}  ${BOLD}${WHITE}Dotfiles Installer${NC}                      ${CYAN}${BOLD}│${NC}\n"
    printf "  ${CYAN}${BOLD}│${NC}  ${DIM}${_GH}/${REPO}${NC}            ${CYAN}${BOLD}│${NC}\n"
    printf "  ${CYAN}${BOLD}└──────────────────────────────────────────┘${NC}\n"
    printf "\n"
}

hr() {
    printf "  ${DIM}──────────────────────────────────────────${NC}\n"
}

show_help() {
    cat << 'HELP'
Usage: install.sh [OPTIONS]

Interactive dotfiles installer with checkbox selection.

Options:
  --all                  Install all components
  --components LIST      Comma-separated component list:
                         shell,tmux,clash,node,uv,go,docker,tailscale,claude-code,codex,gemini,skills
  --gh-proxy URL         GitHub proxy URL (e.g., https://gh-proxy.org)
  -v, --verbose          Show raw script output (default: clean spinner)
  -h, --help             Show this help

Environment variables:
  GH_PROXY               Same as --gh-proxy
  TAILSCALE_AUTH_KEY     Auth key for Tailscale auto-connect
  CLAUDE_API_URL/KEY     API credentials for Claude Code
  CODEX_API_URL/KEY      API credentials for Codex CLI
  GEMINI_API_URL/KEY     API credentials for Gemini CLI

Examples:
  bash install.sh                                    # Interactive
  bash install.sh --all                              # Install everything
  bash install.sh --components shell,node,docker     # Specific components
  bash install.sh --all --gh-proxy https://gh-proxy.org

  # Via curl
  curl -fsSL URL/install.sh | bash
  curl -fsSL URL/install.sh | bash -s -- --all
HELP
}

download_script() {
    local script_name="$1"
    local target="${TMPDIR_INSTALL}/${script_name}"
    local url

    if [[ -n "$GH_PROXY" ]]; then
        url="${GH_PROXY%/}/${BASE_URL}/${script_name}"
    else
        url="${BASE_URL}/${script_name}"
    fi

    [[ -s "$target" ]] && return 0

    if curl -fsSL --retry 3 --retry-delay 2 --retry-all-errors -o "$target" "$url"; then
        chmod +x "$target"
        return 0
    else
        return 1
    fi
}

download_all_needed() {
    local indices=("$@")
    local failed=0
    local total=${#indices[@]}
    local current=0

    printf "\n"
    printf "  ${BOLD}${SYM_DOWN} Downloading scripts${NC}\n"
    hr
    for idx in "${indices[@]}"; do
        ((current++))
        printf "  ${DIM}[%d/%d]${NC} %-24s" "$current" "$total" "${COMP_SCRIPTS[$idx]}"
        if download_script "${COMP_SCRIPTS[$idx]}"; then
            printf "${SYM_CHECK}\n"
        else
            printf "${SYM_CROSS}\n"
            ((failed++))
        fi
    done
    hr
    printf "\n"

    return "$failed"
}

# --- [E] TUI Engine ----------------------------------------------------------

read_key() {
    local key=""
    IFS= read -rsn1 key 2>/dev/null </dev/tty || true

    if [[ "$key" == $'\x1b' ]]; then
        local seq
        IFS= read -rsn2 -t 0.1 seq 2>/dev/null </dev/tty
        case "$seq" in
            '[A') echo "UP" ;;
            '[B') echo "DOWN" ;;
            *)    echo "ESC" ;;
        esac
    elif [[ "$key" == "" ]]; then
        echo "ENTER"
    elif [[ "$key" == " " ]]; then
        echo "SPACE"
    elif [[ "$key" == "a" || "$key" == "A" ]]; then
        echo "A"
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then
        echo "Q"
    else
        echo "$key"
    fi
}

# Read a secret with * feedback, result stored in REPLY_SECRET
read_secret() {
    REPLY_SECRET=""
    local char=""
    while true; do
        IFS= read -rsn1 char </dev/tty || break
        # Enter
        if [[ "$char" == "" ]]; then
            break
        fi
        # Backspace (0x7f or 0x08)
        if [[ "$char" == $'\x7f' || "$char" == $'\x08' ]]; then
            if [[ ${#REPLY_SECRET} -gt 0 ]]; then
                REPLY_SECRET="${REPLY_SECRET%?}"
                printf '\b \b' >&2
            fi
            continue
        fi
        # Ignore escape sequences
        if [[ "$char" == $'\x1b' ]]; then
            IFS= read -rsn2 -t 0.1 _ </dev/tty
            continue
        fi
        REPLY_SECRET+="$char"
        printf '*' >&2
    done
    printf '\n' >&2
}

render_menu() {
    local cursor_pos=$1
    local total=${#COMP_IDS[@]}
    local selected_count=0

    for s in "${COMP_SELECTED[@]}"; do
        [[ "$s" -eq 1 ]] && ((selected_count++))
    done

    # Move cursor to top of menu area
    local menu_height=$((total + 4))
    printf "\033[%dA" "$menu_height"

    # Header
    printf "${CLEAR_LINE}\n"
    printf "${CLEAR_LINE}  ${DIM}↑↓${NC} navigate  ${DIM}space${NC} toggle  ${DIM}a${NC} all  ${DIM}enter${NC} confirm  ${DIM}q${NC} quit\n"

    # Component lines
    for i in $(seq 0 $((total - 1))); do
        printf "${CLEAR_LINE}"

        # Cursor indicator
        if [[ $i -eq $cursor_pos ]]; then
            printf "  ${SYM_ARROW} "
        else
            printf "    "
        fi

        # Checkbox
        if [[ "${COMP_SELECTED[$i]}" -eq 1 ]]; then
            printf "${SYM_FILL} "
        else
            printf "${SYM_DOT} "
        fi

        # Name (padded) - highlight current row
        if [[ $i -eq $cursor_pos ]]; then
            printf "${BOLD}${WHITE}%-22s${NC} " "${COMP_NAMES[$i]}"
        else
            printf "${BOLD}%-22s${NC} " "${COMP_NAMES[$i]}"
        fi

        # Description
        printf "${DIM}%-34s${NC}" "${COMP_DESCS[$i]}"

        # Tags
        local tags=""
        if [[ "${COMP_NEEDS_SUDO[$i]}" -eq 1 ]]; then
            tags+=" ${YELLOW}sudo${NC}"
        fi
        if [[ "${COMP_NEEDS_KEYS[$i]}" -ge 1 ]]; then
            tags+=" ${MAGENTA}key${NC}"
        fi
        [[ -n "$tags" ]] && printf " ${DIM}[${NC}${tags} ${DIM}]${NC}"

        printf "\n"
    done

    # Footer
    printf "${CLEAR_LINE}\n"
    if [[ $selected_count -gt 0 ]]; then
        printf "${CLEAR_LINE}  ${GREEN}${BOLD}%d${NC}${DIM} component(s) selected${NC}\n" "$selected_count"
    else
        printf "${CLEAR_LINE}  ${DIM}No components selected${NC}\n"
    fi
}

show_checkbox_menu() {
    local cursor=0
    local total=${#COMP_IDS[@]}

    printf "${HIDE_CURSOR}"
    CURSOR_HIDDEN=1

    # Reserve space
    local menu_height=$((total + 4))
    for ((i = 0; i < menu_height; i++)); do
        printf "\n"
    done

    render_menu $cursor

    while true; do
        local key
        key=$(read_key)

        case "$key" in
            UP)
                ((cursor > 0)) && ((cursor--))
                ;;
            DOWN)
                ((cursor < total - 1)) && ((cursor++))
                ;;
            SPACE)
                if [[ "${COMP_SELECTED[$cursor]}" -eq 1 ]]; then
                    COMP_SELECTED[$cursor]=0
                else
                    COMP_SELECTED[$cursor]=1
                fi
                ;;
            A)
                local any_selected=0
                for s in "${COMP_SELECTED[@]}"; do
                    [[ "$s" -eq 1 ]] && any_selected=1 && break
                done
                local new_val=$((1 - any_selected))
                for i in "${!COMP_SELECTED[@]}"; do
                    COMP_SELECTED[$i]=$new_val
                done
                ;;
            ENTER)
                break
                ;;
            Q)
                printf "${SHOW_CURSOR}"; CURSOR_HIDDEN=0
                printf "\n  ${DIM}Aborted.${NC}\n\n"
                exit 0
                ;;
        esac

        render_menu $cursor
    done

    printf "${SHOW_CURSOR}"; CURSOR_HIDDEN=0
}

# --- [F] Dependency Resolver --------------------------------------------------

resolve_dependencies() {
    local changed=1
    local auto_added=()

    while [[ $changed -eq 1 ]]; do
        changed=0
        for i in "${!COMP_SELECTED[@]}"; do
            if [[ "${COMP_SELECTED[$i]}" -eq 1 && -n "${COMP_DEPS[$i]}" ]]; then
                for dep_idx in ${COMP_DEPS[$i]}; do
                    if [[ "${COMP_SELECTED[$dep_idx]}" -eq 0 ]]; then
                        COMP_SELECTED[$dep_idx]=1
                        auto_added+=("${COMP_NAMES[$dep_idx]}")
                        changed=1
                    fi
                done
            fi
        done
    done

    # Report auto-added (to stderr so it's not captured by $())
    if [[ ${#auto_added[@]} -gt 0 ]]; then
        for name in "${auto_added[@]}"; do
            printf "  ${SYM_WARN} Auto-added ${BOLD}%s${NC} ${DIM}(dependency)${NC}\n" "$name" >&2
        done
    fi

    # Build ordered list by index
    local ordered=()
    for i in "${!COMP_SELECTED[@]}"; do
        [[ "${COMP_SELECTED[$i]}" -eq 1 ]] && ordered+=("$i")
    done

    echo "${ordered[*]}"
}

show_plan() {
    # shellcheck disable=SC2206
    local ordered=($1)
    local total=${#ordered[@]}

    printf "\n"
    printf "  ${BOLD}${SYM_PLAY} Installation plan${NC}\n"
    hr

    local step=0
    for idx in "${ordered[@]}"; do
        ((step++))
        local suffix=""
        if [[ "${COMP_NEEDS_SUDO[$idx]}" -eq 1 ]]; then
            suffix+=" ${YELLOW}sudo${NC}"
        fi
        if [[ "${COMP_NEEDS_KEYS[$idx]}" -ge 1 ]]; then
            if [[ "${COMP_INSTALL_ONLY[$idx]}" -eq 1 ]]; then
                suffix+=" ${DIM}install only${NC}"
            else
                suffix+=" ${MAGENTA}key${NC}"
            fi
        fi
        printf "  ${CYAN}%2d${NC} ${DIM}│${NC} %-24s${DIM}%s${NC}%b\n" \
            "$step" "${COMP_NAMES[$idx]}" "${COMP_DESCS[$idx]}" "$suffix"
    done

    hr
    printf "  ${DIM}Total: ${BOLD}%d${NC}${DIM} component(s)${NC}\n" "$total"
    printf "\n"
}

# --- [G] Configuration Collector ----------------------------------------------

get_env_names() {
    local idx=$1
    case "${COMP_IDS[$idx]}" in
        tailscale)   ENV_URL_NAME="";               ENV_KEY_NAME="TAILSCALE_AUTH_KEY" ;;
        claude-code) ENV_URL_NAME="CLAUDE_API_URL"; ENV_KEY_NAME="CLAUDE_API_KEY" ;;
        codex)       ENV_URL_NAME="CODEX_API_URL";  ENV_KEY_NAME="CODEX_API_KEY" ;;
        gemini)      ENV_URL_NAME="GEMINI_API_URL"; ENV_KEY_NAME="GEMINI_API_KEY" ;;
    esac
}

collect_api_keys() {
    local needs_input=0
    for i in "${!COMP_SELECTED[@]}"; do
        if [[ "${COMP_SELECTED[$i]}" -eq 1 && "${COMP_NEEDS_KEYS[$i]}" -ge 1 ]]; then
            local ENV_URL_NAME="" ENV_KEY_NAME=""
            get_env_names "$i"
            local current_key="${!ENV_KEY_NAME:-}"
            if [[ "${COMP_NEEDS_KEYS[$i]}" -eq 1 ]]; then
                local current_url="${!ENV_URL_NAME:-}"
                if [[ -z "$current_url" || -z "$current_key" ]]; then
                    needs_input=1; break
                fi
            else
                if [[ -z "$current_key" ]]; then
                    needs_input=1; break
                fi
            fi
        fi
    done

    [[ $needs_input -eq 0 ]] && return 0

    printf "  ${BOLD}${SYM_KEY} API Configuration${NC}\n"
    printf "  ${DIM}Leave blank to install without configuring (can configure later)${NC}\n"
    hr
    printf "\n"

    for i in "${!COMP_SELECTED[@]}"; do
        if [[ "${COMP_SELECTED[$i]}" -eq 1 && "${COMP_NEEDS_KEYS[$i]}" -ge 1 ]]; then
            local ENV_URL_NAME="" ENV_KEY_NAME=""
            get_env_names "$i"
            local current_key="${!ENV_KEY_NAME:-}"
            local key_type="${COMP_NEEDS_KEYS[$i]}"

            printf "  ${BOLD}${WHITE}${COMP_NAMES[$i]}${NC}\n"

            # URL prompt (only for url+key components)
            local current_url=""
            if [[ "$key_type" -eq 1 ]]; then
                current_url="${!ENV_URL_NAME:-}"
                if [[ -z "$current_url" ]]; then
                    printf "  ${DIM}API URL:${NC} "
                    read -r current_url </dev/tty
                    if [[ -n "$current_url" ]]; then
                        export "$ENV_URL_NAME=$current_url"
                    fi
                else
                    printf "  ${DIM}API URL:${NC} ${GREEN}%s${NC}\n" "$current_url"
                fi
            fi

            # Key/token prompt
            local key_label="API Key"
            [[ "$key_type" -eq 2 ]] && key_label="Auth Key"

            if [[ -z "$current_key" ]]; then
                printf "  ${DIM}%s:${NC} " "$key_label"
                read_secret
                current_key="$REPLY_SECRET"
                if [[ -n "$current_key" ]]; then
                    export "$ENV_KEY_NAME=$current_key"
                fi
            else
                printf "  ${DIM}%s:${NC} ${GREEN}%s${NC}\n" "$key_label" "${current_key:0:8}••••••••"
            fi

            # Check completeness
            local is_complete=1
            if [[ "$key_type" -eq 1 && ( -z "$current_url" || -z "$current_key" ) ]]; then
                is_complete=0
            elif [[ "$key_type" -eq 2 && -z "$current_key" ]]; then
                is_complete=0
            fi

            if [[ $is_complete -eq 0 ]]; then
                printf "  ${SYM_WARN} ${YELLOW}Install only${NC} ${DIM}(configure later)${NC}\n"
                COMP_INSTALL_ONLY[$i]=1
            else
                printf "  ${SYM_CHECK} ${DIM}Configured${NC}\n"
            fi
            printf "\n"
        fi
    done
}

validate_api_keys() {
    for i in "${!COMP_SELECTED[@]}"; do
        if [[ "${COMP_SELECTED[$i]}" -eq 1 && "${COMP_NEEDS_KEYS[$i]}" -ge 1 ]]; then
            local ENV_URL_NAME="" ENV_KEY_NAME=""
            get_env_names "$i"
            local current_key="${!ENV_KEY_NAME:-}"
            local key_type="${COMP_NEEDS_KEYS[$i]}"

            if [[ "$key_type" -eq 1 ]]; then
                local current_url="${!ENV_URL_NAME:-}"
                if [[ -z "$current_url" || -z "$current_key" ]]; then
                    printf "  ${SYM_WARN} ${YELLOW}%s${NC} ${DIM}install only (set %s and %s to configure)${NC}\n" \
                        "${COMP_NAMES[$i]}" "$ENV_URL_NAME" "$ENV_KEY_NAME"
                    COMP_INSTALL_ONLY[$i]=1
                fi
            elif [[ "$key_type" -eq 2 && -z "$current_key" ]]; then
                printf "  ${SYM_WARN} ${YELLOW}%s${NC} ${DIM}install only (set %s to configure)${NC}\n" \
                    "${COMP_NAMES[$i]}" "$ENV_KEY_NAME"
                COMP_INSTALL_ONLY[$i]=1
            fi
        fi
    done
}

# --- [H] Execution Engine ----------------------------------------------------

load_env() {
    # Load nvm if available (critical after setup-node.sh runs in subprocess)
    if [[ -d "$HOME/.nvm" ]]; then
        export NVM_DIR="$HOME/.nvm"
        # shellcheck disable=SC1091
        [[ -f "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
    fi
    # Add uv to PATH
    [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
    # Load goenv if available
    if [[ -d "$HOME/.goenv" ]]; then
        export GOENV_ROOT="$HOME/.goenv"
        export PATH="$GOENV_ROOT/bin:$PATH"
        eval "$(goenv init -)" 2>/dev/null || true
    fi
}

run_component() {
    local idx=$1
    local step=$2
    local total=$3
    local script="${COMP_SCRIPTS[$idx]}"
    local script_path="${TMPDIR_INSTALL}/${script}"
    local comp_log="${LOG_FILE}.${COMP_IDS[$idx]}"

    # Reload env between components
    load_env

    # Wire GH_PROXY to CLASH_GH_PROXY for clash script
    if [[ "${COMP_IDS[$idx]}" == "clash" && -n "$GH_PROXY" ]]; then
        export CLASH_GH_PROXY="$GH_PROXY"
    fi

    # Auto-set Docker mirror when behind GH_PROXY (likely in China)
    if [[ "${COMP_IDS[$idx]}" == "docker" && -n "$GH_PROXY" && -z "${DOCKER_MIRROR:-}" ]]; then
        export DOCKER_MIRROR="https://docker.1ms.run"
    fi

    # Check script exists
    if [[ ! -f "$script_path" ]]; then
        printf "  ${SYM_CROSS} ${BOLD}${CYAN}[%d/%d]${NC} ${RED}%s${NC} ${DIM}(script not found)${NC}\n" "$step" "$total" "${COMP_NAMES[$idx]}"
        return 1
    fi

    if [[ "$VERBOSE" -eq 1 ]]; then
        # Verbose: show raw output
        printf "\n"
        printf "  ${BOLD}${CYAN}[%d/%d]${NC} ${BOLD}${WHITE}%s${NC}\n" "$step" "$total" "${COMP_NAMES[$idx]}"
        printf "  ${CYAN}────────────────────────────────────────${NC}\n"

        if bash "$script_path" 2>&1 | tee "$comp_log"; then
            printf "  ${CYAN}────────────────────────────────────────${NC}\n"
            printf "  ${SYM_CHECK} ${GREEN}%s${NC}\n" "${COMP_NAMES[$idx]}"
            return 0
        else
            printf "  ${CYAN}────────────────────────────────────────${NC}\n"
            printf "  ${SYM_CROSS} ${RED}%s${NC}\n" "${COMP_NAMES[$idx]}"
            return 1
        fi
    else
        # Clean mode: script in foreground, spinner in background
        start_spinner "Installing ${COMP_NAMES[$idx]}..."

        bash "$script_path" > "$comp_log" 2>&1
        local result=$?

        stop_spinner

        if [[ $result -eq 0 ]]; then
            printf "  ${SYM_CHECK} ${BOLD}${CYAN}[%d/%d]${NC} %s\n" "$step" "$total" "${COMP_NAMES[$idx]}"
            return 0
        else
            printf "  ${SYM_CROSS} ${BOLD}${CYAN}[%d/%d]${NC} ${RED}%s${NC}\n" "$step" "$total" "${COMP_NAMES[$idx]}"
            # Show last lines of log on failure
            printf "  ${DIM}── last 15 lines ──${NC}\n"
            tail -n 15 "$comp_log" 2>/dev/null | sed 's/^/    /'
            printf "  ${DIM}── full log: %s ──${NC}\n" "$comp_log"
            return 1
        fi
    fi
}

run_all_selected() {
    # shellcheck disable=SC2206
    local ordered=($1)
    local total=${#ordered[@]}
    local step=0
    local succeeded=0
    local failed=0
    local failed_names=()
    local succeeded_names=()
    local installed_ids=()

    printf "\n"
    for idx in "${ordered[@]}"; do
        ((step++))
        if run_component "$idx" "$step" "$total"; then
            ((succeeded++))
            succeeded_names+=("${COMP_NAMES[$idx]}")
            installed_ids+=("${COMP_IDS[$idx]}")
        else
            ((failed++))
            failed_names+=("${COMP_NAMES[$idx]}")
        fi
    done

    # Summary
    printf "\n"
    printf "  ${BOLD}${CYAN}┌──────────────────────────────────────────┐${NC}\n"
    printf "  ${BOLD}${CYAN}│${NC}  ${BOLD}${WHITE}Installation Summary${NC}                    ${BOLD}${CYAN}│${NC}\n"
    printf "  ${BOLD}${CYAN}└──────────────────────────────────────────┘${NC}\n"
    printf "\n"

    if [[ $succeeded -gt 0 ]]; then
        for name in "${succeeded_names[@]}"; do
            printf "  ${SYM_CHECK} %s\n" "$name"
        done
    fi
    if [[ $failed -gt 0 ]]; then
        for name in "${failed_names[@]}"; do
            printf "  ${SYM_CROSS} %s\n" "$name"
        done
    fi

    printf "\n"
    printf "  ${DIM}Result: ${GREEN}${BOLD}%d passed${NC}" "$succeeded"
    if [[ $failed -gt 0 ]]; then
        printf " ${DIM}/${NC} ${RED}${BOLD}%d failed${NC}" "$failed"
    fi
    printf "\n"

    # Post-install hints
    local has_hints=0

    local needs_reload=0
    local has_shell=0

    for id in "${installed_ids[@]}"; do
        case "$id" in
            docker)
                if [[ $has_hints -eq 0 ]]; then
                    printf "\n  ${BOLD}${SYM_WARN} Post-install${NC}\n"
                    has_hints=1
                fi
                printf "  ${DIM}•${NC} Run ${CYAN}newgrp docker${NC} or re-login to use Docker without sudo\n"
                ;;
            shell)
                has_shell=1
                needs_reload=1
                ;;
            node|uv|go|clash|tmux|claude-code|codex|gemini|skills)
                needs_reload=1
                ;;
        esac
    done

    if [[ $needs_reload -eq 1 ]]; then
        if [[ $has_hints -eq 0 ]]; then
            printf "\n  ${BOLD}${SYM_WARN} Post-install${NC}\n"
            has_hints=1
        fi
        if [[ $has_shell -eq 1 ]]; then
            printf "  ${DIM}•${NC} Run ${CYAN}exec zsh${NC} to switch to your new shell and load all changes\n"
        else
            printf "  ${DIM}•${NC} Run ${CYAN}exec \$SHELL${NC} to reload your shell\n"
        fi
    fi

    # Show hints for unconfigured API components
    for i in "${!COMP_INSTALL_ONLY[@]}"; do
        if [[ "${COMP_INSTALL_ONLY[$i]}" -eq 1 ]]; then
            # Only hint if the component actually succeeded
            local comp_id="${COMP_IDS[$i]}"
            local was_installed=0
            for id in "${installed_ids[@]}"; do
                [[ "$id" == "$comp_id" ]] && was_installed=1 && break
            done
            if [[ $was_installed -eq 1 ]]; then
                if [[ $has_hints -eq 0 ]]; then
                    printf "\n  ${BOLD}${SYM_WARN} Post-install${NC}\n"
                    has_hints=1
                fi
                local ENV_URL_NAME="" ENV_KEY_NAME=""
                get_env_names "$i"
                if [[ -n "$ENV_URL_NAME" ]]; then
                    printf "  ${DIM}•${NC} ${BOLD}%s${NC}: configure with ${CYAN}%s${NC} and ${CYAN}%s${NC}\n" \
                        "${COMP_NAMES[$i]}" "$ENV_URL_NAME" "$ENV_KEY_NAME"
                else
                    printf "  ${DIM}•${NC} ${BOLD}%s${NC}: run ${CYAN}sudo tailscale up${NC} to connect\n" \
                        "${COMP_NAMES[$i]}"
                fi
            fi
        fi
    done

    if [[ $failed -gt 0 ]]; then
        printf "\n  ${DIM}Logs: ${NC}${CYAN}${LOG_FILE}.*${NC}\n"
    fi

    printf "\n"
    return "$failed"
}

# --- [I] Argument Parser -----------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                for i in "${!COMP_SELECTED[@]}"; do
                    COMP_SELECTED[$i]=1
                done
                NON_INTERACTIVE=1
                shift
                ;;
            --components)
                IFS=',' read -ra REQUESTED <<< "$2"
                for req in "${REQUESTED[@]}"; do
                    req=$(echo "$req" | tr -d ' ')
                    for i in "${!COMP_IDS[@]}"; do
                        if [[ "${COMP_IDS[$i]}" == "$req" ]]; then
                            COMP_SELECTED[$i]=1
                        fi
                    done
                done
                NON_INTERACTIVE=1
                shift 2
                ;;
            --gh-proxy)
                GH_PROXY="$2"
                shift 2
                ;;
            --verbose|-v)
                VERBOSE=1
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                printf "${RED}Unknown option: %s${NC}\n" "$1"
                show_help
                exit 1
                ;;
        esac
    done
}

# --- [J] Main ----------------------------------------------------------------

main() {
    setup_colors

    # Check prerequisites
    if ! command -v curl &>/dev/null; then
        printf "  ${SYM_CROSS} ${RED}curl is required but not found.${NC}\n"
        exit 1
    fi

    # Parse CLI arguments
    parse_args "$@"

    # Determine interactive mode
    if [[ "$NON_INTERACTIVE" -eq 0 ]]; then
        if [[ -e /dev/tty ]]; then
            INTERACTIVE=1
        else
            echo "Error: No terminal available. Use --all or --components to specify what to install."
            echo "  Example: curl ... | bash -s -- --all"
            echo "  Example: curl ... | bash -s -- --components shell,node,docker"
            exit 1
        fi
    fi

    # Create temp directory for downloads
    TMPDIR_INSTALL=$(mktemp -d)
    LOG_FILE="/tmp/dotfiles-install-$(date +%Y%m%d-%H%M%S)"

    # Banner
    print_banner

    # Interactive selection or validate non-interactive
    if [[ "$INTERACTIVE" -eq 1 ]]; then
        show_checkbox_menu
    fi

    # Check that at least one component is selected
    local any_selected=0
    for s in "${COMP_SELECTED[@]}"; do
        [[ "$s" -eq 1 ]] && any_selected=1 && break
    done
    if [[ "$any_selected" -eq 0 ]]; then
        printf "  ${DIM}No components selected. Exiting.${NC}\n\n"
        exit 0
    fi

    # Resolve dependencies
    local ordered
    ordered=$(resolve_dependencies)

    # Show plan
    show_plan "$ordered"

    # Confirm in interactive mode
    if [[ "$INTERACTIVE" -eq 1 ]]; then
        printf "  ${BOLD}Proceed?${NC} ${DIM}[Y/n]${NC} "
        local confirm
        read -r confirm </dev/tty
        if [[ "$confirm" =~ ^[Nn] ]]; then
            printf "\n  ${DIM}Aborted.${NC}\n\n"
            exit 0
        fi
        printf "\n"
    fi

    # Collect API keys (components stay selected even without keys — install only)
    if [[ "$INTERACTIVE" -eq 1 ]]; then
        collect_api_keys
    else
        validate_api_keys
    fi

    # Pre-cache sudo credentials before noisy installation begins
    cache_sudo

    # Download all needed scripts
    # shellcheck disable=SC2086
    if ! download_all_needed $ordered; then
        printf "  ${SYM_CROSS} ${RED}Some downloads failed. Aborting.${NC}\n\n"
        exit 1
    fi

    # Execute
    run_all_selected "$ordered"
    local result=$?

    # Final message (post-install hints are already in the summary box)
    if [[ $result -eq 0 ]]; then
        printf "  ${SYM_CHECK} ${GREEN}${BOLD}All done!${NC}\n\n"
    else
        printf "  ${SYM_WARN} ${YELLOW}${BOLD}Some components failed. See logs above.${NC}\n\n"
    fi

    exit "$result"
}

main "$@"
