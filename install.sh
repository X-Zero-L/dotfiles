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

GH_PROXY="${GH_PROXY:-}"
NON_INTERACTIVE=0
INTERACTIVE=0
TMPDIR_INSTALL=""

# --- [B] ANSI Colors ---------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'
CLEAR_LINE='\033[2K'

# --- [C] Component Registry --------------------------------------------------

COMP_IDS=(shell clash node uv docker claude-code codex gemini skills)

COMP_NAMES=(
    "Shell Environment"
    "Clash Proxy"
    "Node.js (nvm)"
    "uv + Python"
    "Docker"
    "Claude Code"
    "Codex CLI"
    "Gemini CLI"
    "Agent Skills"
)

COMP_DESCS=(
    "zsh, Oh My Zsh, plugins, Starship"
    "clash-for-linux with subscription"
    "nvm + Node.js 24"
    "uv package manager"
    "Docker Engine + Compose + mirrors"
    "Claude Code CLI"
    "OpenAI Codex CLI"
    "Gemini CLI"
    "Skills for all coding agents"
)

COMP_SCRIPTS=(
    setup-shell.sh
    setup-clash.sh
    setup-node.sh
    setup-uv.sh
    setup-docker.sh
    setup-claude-code.sh
    setup-codex.sh
    setup-gemini.sh
    setup-skills.sh
)

# Dependencies: space-separated indices that must run first (empty = none)
COMP_DEPS=("" "" "" "" "" "2" "2" "2" "2")

# Whether component needs API keys
COMP_NEEDS_KEYS=(0 0 0 0 0 1 1 1 0)

# Whether component needs sudo
COMP_NEEDS_SUDO=(1 0 0 0 1 0 0 0 0)

# Selection state
COMP_SELECTED=(0 0 0 0 0 0 0 0 0)

# --- [D] Utility Functions ----------------------------------------------------

CURSOR_HIDDEN=0

cleanup() {
    [[ "$CURSOR_HIDDEN" -eq 1 ]] && printf "${SHOW_CURSOR}" 2>/dev/null
    [[ -n "${TMPDIR_INSTALL:-}" && -d "${TMPDIR_INSTALL:-}" ]] && rm -rf "$TMPDIR_INSTALL"
}
trap cleanup EXIT INT TERM

print_banner() {
    printf "\n"
    printf "  ${BOLD}${CYAN}╔══════════════════════════════════════╗${NC}\n"
    printf "  ${BOLD}${CYAN}║       Dotfiles Installer             ║${NC}\n"
    printf "  ${BOLD}${CYAN}║       ${_GH}/${REPO}  ${CYAN}║${NC}\n"
    printf "  ${BOLD}${CYAN}╚══════════════════════════════════════╝${NC}\n"
    printf "\n"
}

show_help() {
    cat << 'HELP'
Usage: install.sh [OPTIONS]

Interactive dotfiles installer with checkbox selection.

Options:
  --all                  Install all components
  --components LIST      Comma-separated component list:
                         shell,clash,node,uv,docker,claude-code,codex,gemini,skills
  --gh-proxy URL         GitHub proxy URL (e.g., https://gh-proxy.org)
  -h, --help             Show this help

Environment variables:
  GH_PROXY               Same as --gh-proxy
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

    # Skip if already downloaded
    [[ -f "$target" ]] && return 0

    if curl -fsSL --retry 3 --retry-delay 2 -o "$target" "$url"; then
        chmod +x "$target"
        return 0
    else
        return 1
    fi
}

download_all_needed() {
    local indices=("$@")
    local failed=0

    printf "  ${BOLD}Downloading scripts...${NC}\n"
    for idx in "${indices[@]}"; do
        printf "    ${COMP_SCRIPTS[$idx]}... "
        if download_script "${COMP_SCRIPTS[$idx]}"; then
            printf "${GREEN}ok${NC}\n"
        else
            printf "${RED}failed${NC}\n"
            ((failed++))
        fi
    done

    return "$failed"
}

# --- [E] TUI Engine ----------------------------------------------------------

read_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null </dev/tty

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
    printf "${CLEAR_LINE}  ${BOLD}${CYAN}Dotfiles Installer${NC}\n"
    printf "${CLEAR_LINE}  ${DIM}arrows: navigate | space: toggle | a: toggle all | enter: confirm | q: quit${NC}\n"

    # Component lines
    for i in $(seq 0 $((total - 1))); do
        printf "${CLEAR_LINE}"

        # Cursor indicator
        if [[ $i -eq $cursor_pos ]]; then
            printf "  ${CYAN}>${NC} "
        else
            printf "    "
        fi

        # Checkbox
        if [[ "${COMP_SELECTED[$i]}" -eq 1 ]]; then
            printf "${GREEN}[x]${NC} "
        else
            printf "[ ] "
        fi

        # Name (padded)
        printf "${BOLD}%-22s${NC} " "${COMP_NAMES[$i]}"

        # Description
        printf "${DIM}%-38s${NC}" "${COMP_DESCS[$i]}"

        # Tags
        if [[ "${COMP_NEEDS_SUDO[$i]}" -eq 1 ]]; then
            printf " ${YELLOW}[sudo]${NC}"
        fi
        if [[ "${COMP_NEEDS_KEYS[$i]}" -eq 1 ]]; then
            printf " ${MAGENTA}[key]${NC}"
        fi

        printf "\n"
    done

    # Footer
    printf "${CLEAR_LINE}\n"
    printf "${CLEAR_LINE}  ${DIM}[%d selected]${NC}\n" "$selected_count"
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
                printf "\n  Aborted.\n\n"
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
        printf "\n" >&2
        for name in "${auto_added[@]}"; do
            printf "  ${YELLOW}+${NC} Auto-added: ${BOLD}%s${NC} (required dependency)\n" "$name" >&2
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
    local ordered=($1)
    local total=${#ordered[@]}

    printf "\n  ${BOLD}Installation plan:${NC}\n"
    local step=0
    for idx in "${ordered[@]}"; do
        ((step++))
        printf "    ${CYAN}%d.${NC} %s\n" "$step" "${COMP_NAMES[$idx]}"
    done
    printf "\n"
}

# --- [G] Configuration Collector ----------------------------------------------

get_env_names() {
    local idx=$1
    case "${COMP_IDS[$idx]}" in
        claude-code) ENV_URL_NAME="CLAUDE_API_URL"; ENV_KEY_NAME="CLAUDE_API_KEY" ;;
        codex)       ENV_URL_NAME="CODEX_API_URL";  ENV_KEY_NAME="CODEX_API_KEY" ;;
        gemini)      ENV_URL_NAME="GEMINI_API_URL"; ENV_KEY_NAME="GEMINI_API_KEY" ;;
    esac
}

collect_api_keys() {
    local needs_input=0
    for i in "${!COMP_SELECTED[@]}"; do
        if [[ "${COMP_SELECTED[$i]}" -eq 1 && "${COMP_NEEDS_KEYS[$i]}" -eq 1 ]]; then
            local ENV_URL_NAME="" ENV_KEY_NAME=""
            get_env_names "$i"
            local current_url="${!ENV_URL_NAME:-}"
            local current_key="${!ENV_KEY_NAME:-}"
            if [[ -z "$current_url" || -z "$current_key" ]]; then
                needs_input=1
                break
            fi
        fi
    done

    [[ $needs_input -eq 0 ]] && return 0

    printf "  ${BOLD}API Configuration${NC}\n\n"

    for i in "${!COMP_SELECTED[@]}"; do
        if [[ "${COMP_SELECTED[$i]}" -eq 1 && "${COMP_NEEDS_KEYS[$i]}" -eq 1 ]]; then
            local ENV_URL_NAME="" ENV_KEY_NAME=""
            get_env_names "$i"
            local current_url="${!ENV_URL_NAME:-}"
            local current_key="${!ENV_KEY_NAME:-}"

            printf "  ${BOLD}${COMP_NAMES[$i]}${NC}\n"

            if [[ -z "$current_url" ]]; then
                printf "    API URL: "
                read -r current_url </dev/tty
                if [[ -n "$current_url" ]]; then
                    export "$ENV_URL_NAME=$current_url"
                fi
            else
                printf "    API URL: ${DIM}(from env)${NC}\n"
            fi

            if [[ -z "$current_key" ]]; then
                printf "    API Key: "
                read -rs current_key </dev/tty
                printf "\n"
                if [[ -n "$current_key" ]]; then
                    export "$ENV_KEY_NAME=$current_key"
                fi
            else
                printf "    API Key: ${DIM}(from env)${NC}\n"
            fi

            if [[ -z "$current_url" || -z "$current_key" ]]; then
                printf "    ${YELLOW}Skipped (missing credentials)${NC}\n"
                COMP_SELECTED[$i]=0
            fi
            printf "\n"
        fi
    done
}

validate_api_keys() {
    for i in "${!COMP_SELECTED[@]}"; do
        if [[ "${COMP_SELECTED[$i]}" -eq 1 && "${COMP_NEEDS_KEYS[$i]}" -eq 1 ]]; then
            local ENV_URL_NAME="" ENV_KEY_NAME=""
            get_env_names "$i"
            local current_url="${!ENV_URL_NAME:-}"
            local current_key="${!ENV_KEY_NAME:-}"

            if [[ -z "$current_url" || -z "$current_key" ]]; then
                printf "  ${YELLOW}Warning: %s skipped (set %s and %s)${NC}\n" \
                    "${COMP_NAMES[$i]}" "$ENV_URL_NAME" "$ENV_KEY_NAME"
                COMP_SELECTED[$i]=0
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
}

run_component() {
    local idx=$1
    local step=$2
    local total=$3
    local script="${COMP_SCRIPTS[$idx]}"
    local script_path="${TMPDIR_INSTALL}/${script}"

    printf "\n${BOLD}${CYAN}[%d/%d] %s${NC}\n" "$step" "$total" "${COMP_NAMES[$idx]}"
    printf "${DIM}──────────────────────────────────────────────────────────────${NC}\n"

    # Reload env between components
    load_env

    # Wire GH_PROXY to CLASH_GH_PROXY for clash script
    if [[ "${COMP_IDS[$idx]}" == "clash" && -n "$GH_PROXY" ]]; then
        export CLASH_GH_PROXY="$GH_PROXY"
    fi

    if bash "$script_path"; then
        printf "${DIM}──── ${NC}${GREEN}[OK]${NC} %s\n" "${COMP_NAMES[$idx]}"
        return 0
    else
        printf "${DIM}──── ${NC}${RED}[FAILED]${NC} %s\n" "${COMP_NAMES[$idx]}"
        return 1
    fi
}

run_all_selected() {
    local ordered=($1)
    local total=${#ordered[@]}
    local step=0
    local succeeded=0
    local failed=0
    local failed_names=()

    for idx in "${ordered[@]}"; do
        ((step++))
        if run_component "$idx" "$step" "$total"; then
            ((succeeded++))
        else
            ((failed++))
            failed_names+=("${COMP_NAMES[$idx]}")
        fi
    done

    # Summary
    printf "\n${BOLD}══════════════════════════════════════════════════════════════${NC}\n"
    printf "  ${BOLD}Installation Summary${NC}\n"
    printf "${BOLD}══════════════════════════════════════════════════════════════${NC}\n"
    printf "  ${GREEN}Succeeded: %d${NC}\n" "$succeeded"
    if [[ $failed -gt 0 ]]; then
        printf "  ${RED}Failed:    %d${NC}\n" "$failed"
        for name in "${failed_names[@]}"; do
            printf "    ${RED}- %s${NC}\n" "$name"
        done
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
    # Check prerequisites
    if ! command -v curl &>/dev/null; then
        echo "Error: 'curl' is required but not found."
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
        printf "  No components selected. Exiting.\n\n"
        exit 0
    fi

    # Resolve dependencies
    local ordered
    ordered=$(resolve_dependencies)

    # Show plan
    show_plan "$ordered"

    # Confirm in interactive mode
    if [[ "$INTERACTIVE" -eq 1 ]]; then
        printf "  Proceed? [Y/n] "
        local confirm
        read -r confirm </dev/tty
        if [[ "$confirm" =~ ^[Nn] ]]; then
            printf "\n  Aborted.\n\n"
            exit 0
        fi
        printf "\n"
    fi

    # Collect API keys
    if [[ "$INTERACTIVE" -eq 1 ]]; then
        collect_api_keys
    else
        validate_api_keys
    fi

    # Rebuild ordered list after possible skips from missing API keys
    ordered=""
    for i in "${!COMP_SELECTED[@]}"; do
        [[ "${COMP_SELECTED[$i]}" -eq 1 ]] && ordered+="$i "
    done
    ordered="${ordered% }"

    # Check again after API key validation
    any_selected=0
    for s in "${COMP_SELECTED[@]}"; do
        [[ "$s" -eq 1 ]] && any_selected=1 && break
    done
    if [[ "$any_selected" -eq 0 ]]; then
        printf "  No components remaining after validation. Exiting.\n\n"
        exit 0
    fi

    # Download all needed scripts
    printf "\n"
    if ! download_all_needed $ordered; then
        printf "\n  ${RED}Some downloads failed. Aborting.${NC}\n\n"
        exit 1
    fi

    # Execute
    run_all_selected "$ordered"
    local result=$?

    # Final message
    if [[ $result -eq 0 ]]; then
        printf "  ${GREEN}${BOLD}All components installed successfully!${NC}\n"
    else
        printf "  ${YELLOW}${BOLD}Some components failed. Check output above.${NC}\n"
    fi
    printf "  Run ${CYAN}source ~/.zshrc${NC} or open a new terminal to apply changes.\n\n"

    exit "$result"
}

main "$@"
