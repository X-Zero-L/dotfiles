#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Rig Component Uninstaller
# https://github.com/X-Zero-L/rig
#
# Usage:
#   bash uninstall.sh docker                     # Uninstall single component
#   bash uninstall.sh node --force               # Force (ignore dependents)
#   bash uninstall.sh --all                      # Uninstall everything
#   bash uninstall.sh --all --force              # Skip all prompts
#   bash uninstall.sh --components shell,tmux    # Uninstall specific components
#   bash uninstall.sh --list                     # List installed components
# =============================================================================

# --- [A] Constants -----------------------------------------------------------

FORCE=0
NON_INTERACTIVE=0
INTERACTIVE=0
VERBOSE=0
LOG_FILE=""
CURSOR_HIDDEN=0

# Pre-confirmation flags (collected before execution)
DOCKER_REMOVE_DATA=1
SSH_REMOVE_KEYS=0
CLAUDE_REMOVE_CONFIG=0

# --- [B] ANSI Colors ---------------------------------------------------------

setup_colors() {
    if [[ -t 1 ]] || [[ "${FORCE_COLOR:-}" == "1" ]]; then
        RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
        CYAN='\033[0;36m'; WHITE='\033[1;37m'; BOLD='\033[1m'
        DIM='\033[2m'; NC='\033[0m'
        HIDE_CURSOR='\033[?25l'; SHOW_CURSOR='\033[?25h'; CLEAR_LINE='\033[2K'
        SYM_CHECK="${GREEN}✔${NC}"; SYM_CROSS="${RED}✘${NC}"
        SYM_ARROW="${CYAN}▸${NC}"; SYM_DOT="${DIM}○${NC}"
        SYM_FILL="${GREEN}●${NC}"; SYM_WARN="${YELLOW}▲${NC}"
        SYM_PLAY="${CYAN}▶${NC}"
    else
        RED='' GREEN='' YELLOW='' CYAN='' WHITE=''
        BOLD='' DIM='' NC=''
        HIDE_CURSOR='' SHOW_CURSOR='' CLEAR_LINE=''
        SYM_CHECK='[ok]' SYM_CROSS='[fail]' SYM_ARROW='>' SYM_DOT='[ ]'
        SYM_FILL='[x]' SYM_WARN='[!]' SYM_PLAY='[>]'
    fi
}

# --- [C] Component Registry --------------------------------------------------

COMP_IDS=(shell tmux git tools essential-tools node uv go docker tailscale ssh claude-code codex gemini skills)

COMP_NAMES=(
    "Shell Environment" "Tmux" "Git" "CLI Tools" "Essential Tools"
    "Node.js (nvm)" "uv + Python" "Go (goenv)" "Docker" "Tailscale"
    "SSH" "Claude Code" "Codex CLI" "Gemini CLI" "Agent Skills"
)

COMP_DESCS=(
    "zsh, Oh My Zsh, plugins, Starship"
    "tmux + Catppuccin + TPM plugins"
    "git package (config preserved)"
    "rg, jq, fd, bat, tree, shellcheck"
    "build-essential, wget, unzip, gh CLI"
    "nvm + Node.js"
    "uv package manager + managed pythons"
    "goenv + Go versions"
    "Docker Engine + Compose + data"
    "Tailscale VPN"
    "SSH keys + sshd config"
    "Claude Code CLI + ~/.claude"
    "Codex CLI + ~/.codex"
    "Gemini CLI + ~/.gemini"
    "Agent skills for all coding agents"
)

# Reverse dependency map: which components depend on THIS one
# node(5) is required by claude-code(11), codex(12), gemini(13), skills(14)
COMP_DEPENDENTS=("" "" "" "" "" "11 12 13 14" "" "" "" "" "" "" "" "" "")

# Whether uninstall needs sudo
COMP_NEEDS_SUDO=(1 1 0 1 1 0 0 0 1 1 1 0 0 0 0)

# State arrays
COMP_INSTALLED=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
COMP_SELECTED=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
VISIBLE=()

# --- [D] Utility Functions ---------------------------------------------------

SUDO_KEEPALIVE_PID=""
SPINNER_PID=""

cleanup() {
    [[ "$CURSOR_HIDDEN" -eq 1 ]] && printf '\033[?25h' 2>/dev/null
    [[ -n "${SPINNER_PID:-}" ]] && kill "$SPINNER_PID" 2>/dev/null || true
    [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

start_spinner() {
    local msg="$1"
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    [[ -z "$BOLD" ]] && frames=('-' '\' '|' '/')
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

cache_sudo() {
    local needs_sudo=0
    for i in "${!COMP_SELECTED[@]}"; do
        if [[ "${COMP_SELECTED[$i]}" -eq 1 && "${COMP_NEEDS_SUDO[$i]}" -eq 1 ]]; then
            needs_sudo=1; break
        fi
    done
    if [[ $needs_sudo -eq 1 ]]; then
        printf "  ${DIM}Some components require sudo. Caching credentials...${NC}\n"
        sudo -v
        ( while true; do sudo -n true 2>/dev/null; sleep 50; done ) &
        SUDO_KEEPALIVE_PID=$!
    fi
}

print_banner() {
    printf "\n"
    printf "  ${CYAN}${BOLD}┌──────────────────────────────────────────┐${NC}\n"
    printf "  ${CYAN}${BOLD}│${NC}  ${BOLD}${WHITE}Rig Uninstaller${NC}                         ${CYAN}${BOLD}│${NC}\n"
    printf "  ${CYAN}${BOLD}│${NC}  ${DIM}github.com/X-Zero-L/rig${NC}                 ${CYAN}${BOLD}│${NC}\n"
    printf "  ${CYAN}${BOLD}└──────────────────────────────────────────┘${NC}\n"
    printf "\n"
}

hr() { printf "  ${DIM}──────────────────────────────────────────${NC}\n"; }

# Create .rig-backup before modifying a config file
backup_file() {
    local file="$1"
    [[ -f "$file" ]] || return 0
    local backup="${file}.rig-backup"
    [[ -f "$backup" ]] && backup="${file}.rig-backup.$(date +%s)"
    cp "$file" "$backup"
    echo "  Backup: $backup"
}

# Remove lines matching pattern from .bashrc and .zshrc
remove_rc_line() {
    local pattern="$1"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [[ -f "$rc" ]] || continue
        grep -qF "$pattern" "$rc" || continue
        backup_file "$rc"
        local tmp="${rc}.tmp.$$"
        grep -vF "$pattern" "$rc" > "$tmp" || true
        [[ -s "$tmp" ]] && mv "$tmp" "$rc" || rm -f "$tmp"
    done
}

# Remove a block between "# MARKER START" and "# MARKER END" from rc files
remove_rc_block() {
    local marker="$1"
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [[ -f "$rc" ]] || continue
        grep -q "# ${marker} START" "$rc" || continue
        backup_file "$rc"
        sed -i "/# ${marker} START/,/# ${marker} END/d" "$rc"
    done
}

load_env() {
    if [[ -d "$HOME/.nvm" ]]; then
        export NVM_DIR="$HOME/.nvm"
        # shellcheck disable=SC1091
        [[ -f "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
    fi
    [[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
    if [[ -d "$HOME/.goenv" ]]; then
        export GOENV_ROOT="$HOME/.goenv"
        export PATH="$GOENV_ROOT/bin:$PATH"
        eval "$(goenv init -)" 2>/dev/null || true
    fi
}

show_help() {
    cat << 'HELP'
Usage: uninstall.sh [OPTIONS] [COMPONENT]

Rig uninstaller for individual or batch component removal.

Arguments:
  COMPONENT              Single component to uninstall:
                         shell,tmux,git,tools,essential-tools,node,uv,go,
                         docker,tailscale,ssh,claude-code,codex,gemini,skills

Options:
  --all                  Uninstall all installed components
  --components LIST      Comma-separated component list
  --force                Skip dependency checks and confirmations
  --list                 List installed components and exit
  -v, --verbose          Show raw command output
  -h, --help             Show this help

Examples:
  bash uninstall.sh docker                         # Uninstall Docker
  bash uninstall.sh node --force                   # Force uninstall Node.js
  bash uninstall.sh --components codex,gemini      # Uninstall multiple
  bash uninstall.sh --all                          # Uninstall everything
  bash uninstall.sh --list                         # Show what's installed
HELP
}

# --- [E] Detection -----------------------------------------------------------

detect_installed() {
    local checks=(
        "test -d $HOME/.oh-my-zsh"
        "command -v tmux"
        "command -v git"
        "command -v rg && command -v jq"
        "dpkg -s build-essential 2>/dev/null"
        "command -v nvm 2>/dev/null || [[ -f $HOME/.nvm/nvm.sh ]]"
        "command -v uv"
        "command -v goenv 2>/dev/null || [[ -d $HOME/.goenv/bin ]]"
        "command -v docker"
        "command -v tailscale"
        "test -f /etc/ssh/sshd_config"
        "command -v claude"
        "command -v codex"
        "command -v gemini"
        "test -d $HOME/.local/share/skills || test -d $HOME/.claude/skills"
    )
    for i in "${!checks[@]}"; do
        if eval "${checks[$i]}" &>/dev/null; then
            COMP_INSTALLED[$i]=1
        fi
    done
}

# --- [F] Pre-execution Confirmations ----------------------------------------

collect_confirmations() {
    [[ "$FORCE" -eq 1 ]] && { DOCKER_REMOVE_DATA=1; SSH_REMOVE_KEYS=1; CLAUDE_REMOVE_CONFIG=1; return 0; }
    [[ ! -e /dev/tty ]] && return 0

    local needs_confirm=0
    for i in "${!COMP_SELECTED[@]}"; do
        [[ "${COMP_SELECTED[$i]}" -eq 0 ]] && continue
        case "${COMP_IDS[$i]}" in docker|ssh|claude-code) needs_confirm=1 ;; esac
    done
    [[ $needs_confirm -eq 0 ]] && return 0

    printf "  ${BOLD}Data removal confirmations${NC}\n"
    hr

    for i in "${!COMP_SELECTED[@]}"; do
        [[ "${COMP_SELECTED[$i]}" -eq 0 ]] && continue
        case "${COMP_IDS[$i]}" in
            docker)
                printf "\n  ${BOLD}${WHITE}Docker${NC}\n"
                printf "  ${YELLOW}Volumes and images at /var/lib/docker will be removed.${NC}\n"
                printf "  ${BOLD}Remove all Docker data?${NC} ${DIM}[Y/n]${NC} "
                local ans; read -r ans </dev/tty
                [[ "$ans" =~ ^[Nn] ]] && DOCKER_REMOVE_DATA=0
                ;;
            ssh)
                printf "\n  ${BOLD}${WHITE}SSH${NC}\n"
                printf "  ${YELLOW}SSH keys in ~/.ssh/ can be removed.${NC}\n"
                printf "  ${BOLD}Remove SSH keys?${NC} ${DIM}[y/N]${NC} "
                local ans; read -r ans </dev/tty
                [[ "$ans" =~ ^[Yy] ]] && SSH_REMOVE_KEYS=1
                ;;
            claude-code)
                printf "\n  ${BOLD}${WHITE}Claude Code${NC}\n"
                printf "  ${YELLOW}~/.claude (settings, history, projects) can be removed.${NC}\n"
                printf "  ${BOLD}Remove Claude Code config and data?${NC} ${DIM}[y/N]${NC} "
                local ans; read -r ans </dev/tty
                [[ "$ans" =~ ^[Yy] ]] && CLAUDE_REMOVE_CONFIG=1
                ;;
        esac
    done
    printf "\n"
}

# --- [G] Uninstall Functions -------------------------------------------------

uninstall_shell() {
    echo "=== Uninstalling Shell Environment ==="

    # Remove Starship
    if command -v starship &>/dev/null; then
        sudo rm -f /usr/local/bin/starship /usr/local/bin/starship.old 2>/dev/null || true
        rm -f "$HOME/.config/starship.toml"
        echo "  Starship removed."
    fi

    # Clean starship init from rc files
    remove_rc_line 'eval "$(starship init zsh)"'

    # Remove Oh My Zsh custom plugins
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    rm -rf "${zsh_custom:?}/plugins/zsh-autosuggestions" 2>/dev/null || true
    rm -rf "${zsh_custom:?}/plugins/zsh-syntax-highlighting" 2>/dev/null || true

    # Remove Oh My Zsh
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        rm -rf "$HOME/.oh-my-zsh"
        echo "  Oh My Zsh removed."
        # Restore pre-omz zshrc if it exists
        if [[ -f "$HOME/.zshrc.pre-oh-my-zsh" ]]; then
            backup_file "$HOME/.zshrc"
            mv "$HOME/.zshrc.pre-oh-my-zsh" "$HOME/.zshrc"
            echo "  Restored pre-Oh My Zsh .zshrc."
        fi
    fi

    # Change default shell back to bash
    if [[ "${SHELL:-}" == *"zsh"* ]] && command -v bash &>/dev/null; then
        sudo chsh -s "$(command -v bash)" "$USER" 2>/dev/null || true
        echo "  Default shell changed to bash."
    fi
}

uninstall_tmux() {
    echo "=== Uninstalling Tmux ==="

    if [[ -f "$HOME/.tmux.conf" ]]; then
        backup_file "$HOME/.tmux.conf"
        rm -f "$HOME/.tmux.conf"
    fi
    rm -rf "$HOME/.tmux"
    echo "  Config and plugins removed."

    if command -v tmux &>/dev/null; then
        sudo apt-get remove -y tmux 2>/dev/null || true
        echo "  tmux package removed."
    fi
}

uninstall_git() {
    echo "=== Uninstalling Git ==="
    echo "  Note: ~/.gitconfig will be preserved."

    if command -v git &>/dev/null; then
        sudo apt-get remove -y git 2>/dev/null || true
        echo "  Git package removed."
    fi
}

uninstall_tools() {
    echo "=== Uninstalling CLI Tools ==="

    # Remove convenience symlinks
    rm -f "$HOME/.local/bin/bat" "$HOME/.local/bin/fd"

    # Remove apt packages
    sudo apt-get remove -y \
        ripgrep jq fd-find bat tree shellcheck xclip 2>/dev/null || true
    echo "  CLI tools removed."
}

uninstall_essential_tools() {
    echo "=== Uninstalling Essential Tools ==="

    # Remove gh CLI and its apt source
    if command -v gh &>/dev/null; then
        sudo apt-get remove -y gh 2>/dev/null || true
        sudo rm -f /etc/apt/sources.list.d/github-cli.list
        sudo rm -f /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "  GitHub CLI removed."
    fi

    # Remove build tools
    sudo apt-get remove -y build-essential wget unzip 2>/dev/null || true
    echo "  Essential tools removed."
}

uninstall_node() {
    echo "=== Uninstalling Node.js (nvm) ==="

    rm -rf "$HOME/.nvm"
    echo "  nvm directory removed."

    # Clean nvm references from rc files
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [[ -f "$rc" ]] || continue
        if grep -q '\.nvm' "$rc"; then
            backup_file "$rc"
            local tmp="${rc}.tmp.$$"
            grep -v '\.nvm' "$rc" > "$tmp" || true
            [[ -s "$tmp" ]] && mv "$tmp" "$rc" || rm -f "$tmp"
        fi
    done
    echo "  RC files cleaned."
}

uninstall_uv() {
    echo "=== Uninstalling uv ==="

    rm -f "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
    rm -rf "$HOME/.local/share/uv"
    rm -rf "$HOME/.cache/uv"
    echo "  uv and managed pythons removed."
}

uninstall_go() {
    echo "=== Uninstalling Go (goenv) ==="

    rm -rf "$HOME/.goenv"
    rm -f "$HOME/.goenvrc"
    echo "  goenv removed."

    remove_rc_block "goenv"
    echo "  RC files cleaned."
}

uninstall_docker() {
    echo "=== Uninstalling Docker ==="

    # Stop services
    sudo systemctl stop docker.socket 2>/dev/null || true
    sudo systemctl stop docker 2>/dev/null || true
    sudo systemctl stop containerd 2>/dev/null || true
    echo "  Services stopped."

    # Remove packages
    sudo apt-get remove -y \
        docker-ce docker-ce-cli containerd.io \
        docker-compose-plugin docker-buildx-plugin 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true
    echo "  Packages removed."

    # Remove data (conditional)
    if [[ "$DOCKER_REMOVE_DATA" -eq 1 ]]; then
        sudo rm -rf /var/lib/docker /var/lib/containerd
        echo "  Docker data removed."
    else
        echo "  Docker data preserved at /var/lib/docker."
    fi

    # Remove config
    sudo rm -f /etc/docker/daemon.json
    sudo rm -rf /etc/systemd/system/docker.service.d
    rm -rf "$HOME/.docker"
    echo "  Config removed."

    # Remove apt source
    sudo rm -f /etc/apt/sources.list.d/docker.list
    sudo rm -f /etc/apt/keyrings/docker.asc /etc/apt/keyrings/docker.gpg
    sudo systemctl daemon-reload 2>/dev/null || true
    echo "  Apt source removed."
}

uninstall_tailscale() {
    echo "=== Uninstalling Tailscale ==="

    sudo tailscale down 2>/dev/null || true
    sudo systemctl stop tailscaled 2>/dev/null || true
    sudo systemctl disable tailscaled 2>/dev/null || true
    echo "  Disconnected and stopped."

    sudo apt-get remove -y tailscale 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true
    sudo rm -rf /var/lib/tailscale
    sudo rm -f /etc/apt/sources.list.d/tailscale*.list
    echo "  Tailscale removed."
}

uninstall_ssh() {
    echo "=== Uninstalling SSH Configuration ==="

    # Remove SSH keys (conditional)
    if [[ "$SSH_REMOVE_KEYS" -eq 1 ]]; then
        for key in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa" "$HOME/.ssh/id_ecdsa"; do
            if [[ -f "$key" ]]; then
                backup_file "$key"
                rm -f "$key" "${key}.pub"
                echo "  Removed $(basename "$key")."
            fi
        done
        if [[ -f "$HOME/.ssh/authorized_keys" ]]; then
            backup_file "$HOME/.ssh/authorized_keys"
            rm -f "$HOME/.ssh/authorized_keys"
        fi
        echo "  SSH keys removed."
    else
        echo "  SSH keys preserved."
    fi

    # Remove GitHub SSH proxy config
    if [[ -f "$HOME/.ssh/config" ]] && grep -q "^Host github\.com" "$HOME/.ssh/config" 2>/dev/null; then
        backup_file "$HOME/.ssh/config"
        # Remove the github.com Host block using awk
        awk '
            /^Host github\.com/ { skip=1; next }
            /^Host / && skip { skip=0 }
            /^[^ \t]/ && !/^Host / && skip { skip=0 }
            !skip
        ' "$HOME/.ssh/config" > "$HOME/.ssh/config.tmp.$$"
        mv "$HOME/.ssh/config.tmp.$$" "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        echo "  GitHub SSH proxy config removed."
    fi

    # Restore sshd_config from backup
    local latest_backup=""
    for f in /etc/ssh/sshd_config.bak.*; do
        [[ -f "$f" ]] && latest_backup="$f"
    done
    if [[ -n "$latest_backup" ]]; then
        sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.rig-backup 2>/dev/null || true
        sudo cp "$latest_backup" /etc/ssh/sshd_config
        sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd 2>/dev/null || true
        echo "  sshd_config restored from backup."
    fi
}

uninstall_claude_code() {
    echo "=== Uninstalling Claude Code ==="

    load_env
    if command -v claude &>/dev/null; then
        npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
        echo "  Claude Code uninstalled."
    fi

    if [[ "$CLAUDE_REMOVE_CONFIG" -eq 1 ]]; then
        rm -rf "$HOME/.claude"
        rm -f "$HOME/.claude.json"
        echo "  Config and data removed."
    else
        echo "  Config preserved (~/.claude)."
    fi

    remove_rc_line "alias cc='claude --dangerously-skip-permissions'"
}

uninstall_codex() {
    echo "=== Uninstalling Codex CLI ==="

    load_env
    if command -v codex &>/dev/null; then
        npm uninstall -g @openai/codex 2>/dev/null || true
        echo "  Codex CLI uninstalled."
    fi

    rm -rf "$HOME/.codex"
    echo "  Config removed."

    remove_rc_line "alias cx='codex --dangerously-bypass-approvals-and-sandbox'"
}

uninstall_gemini() {
    echo "=== Uninstalling Gemini CLI ==="

    load_env
    if command -v gemini &>/dev/null; then
        npm uninstall -g @google/gemini-cli 2>/dev/null || true
        echo "  Gemini CLI uninstalled."
    fi

    rm -rf "$HOME/.gemini"
    echo "  Config removed."

    remove_rc_line "alias gm='gemini -y'"
}

uninstall_skills() {
    echo "=== Uninstalling Agent Skills ==="

    rm -rf "$HOME/.local/share/skills"
    # Only remove skills subdirectory, not all of ~/.claude
    rm -rf "$HOME/.claude/skills"
    echo "  Skills removed."
}

# --- [H] Dispatcher & Dependency Checker ------------------------------------

run_uninstall() {
    local idx=$1
    case "${COMP_IDS[$idx]}" in
        shell)           uninstall_shell ;;
        tmux)            uninstall_tmux ;;
        git)             uninstall_git ;;
        tools)           uninstall_tools ;;
        essential-tools) uninstall_essential_tools ;;
        node)            uninstall_node ;;
        uv)              uninstall_uv ;;
        go)              uninstall_go ;;
        docker)          uninstall_docker ;;
        tailscale)       uninstall_tailscale ;;
        ssh)             uninstall_ssh ;;
        claude-code)     uninstall_claude_code ;;
        codex)           uninstall_codex ;;
        gemini)          uninstall_gemini ;;
        skills)          uninstall_skills ;;
    esac
}

check_dependents() {
    local idx=$1
    local deps="${COMP_DEPENDENTS[$idx]}"
    [[ -z "$deps" ]] && return 0

    local blocked=()
    for dep_idx in $deps; do
        # Only block if dependent is installed AND not also selected for removal
        if [[ "${COMP_INSTALLED[$dep_idx]}" -eq 1 && "${COMP_SELECTED[$dep_idx]}" -eq 0 ]]; then
            blocked+=("${COMP_NAMES[$dep_idx]}")
        fi
    done

    if [[ ${#blocked[@]} -gt 0 ]]; then
        printf "  ${SYM_WARN} ${YELLOW}%s${NC} is required by: ${BOLD}%s${NC}\n" \
            "${COMP_NAMES[$idx]}" "$(IFS=', '; echo "${blocked[*]}")"
        if [[ "$FORCE" -eq 1 ]]; then
            printf "  ${DIM}Forcing uninstall (--force)${NC}\n"
            return 0
        fi
        printf "  ${DIM}Use --force to override${NC}\n"
        return 1
    fi
    return 0
}

# --- [I] TUI Menu -----------------------------------------------------------

read_key() {
    local key=""
    IFS= read -rsn1 key 2>/dev/null </dev/tty || true
    if [[ "$key" == $'\x1b' ]]; then
        local seq
        IFS= read -rsn2 -t 0.1 seq 2>/dev/null </dev/tty
        case "$seq" in
            '[A') echo "UP" ;; '[B') echo "DOWN" ;; *) echo "ESC" ;;
        esac
    elif [[ "$key" == "" ]]; then echo "ENTER"
    elif [[ "$key" == " " ]]; then echo "SPACE"
    elif [[ "$key" == "a" || "$key" == "A" ]]; then echo "A"
    elif [[ "$key" == "q" || "$key" == "Q" ]]; then echo "Q"
    else echo "$key"
    fi
}

render_menu() {
    local cursor_pos=$1
    local total=${#VISIBLE[@]}
    local selected_count=0
    for vi in "${!VISIBLE[@]}"; do
        local ci="${VISIBLE[$vi]}"
        [[ "${COMP_SELECTED[$ci]}" -eq 1 ]] && ((selected_count++))
    done

    printf "\033[%dA" "$((total + 4))"
    printf "${CLEAR_LINE}\n"
    printf "${CLEAR_LINE}  ${DIM}↑↓${NC} navigate  ${DIM}space${NC} toggle  ${DIM}a${NC} all  ${DIM}enter${NC} confirm  ${DIM}q${NC} quit\n"

    for vi in $(seq 0 $((total - 1))); do
        local ci="${VISIBLE[$vi]}"
        printf "${CLEAR_LINE}"
        [[ $vi -eq $cursor_pos ]] && printf "  ${SYM_ARROW} " || printf "    "
        [[ "${COMP_SELECTED[$ci]}" -eq 1 ]] && printf "${SYM_FILL} " || printf "${SYM_DOT} "
        if [[ $vi -eq $cursor_pos ]]; then
            printf "${BOLD}${WHITE}%-22s${NC} " "${COMP_NAMES[$ci]}"
        else
            printf "${BOLD}%-22s${NC} " "${COMP_NAMES[$ci]}"
        fi
        printf "${DIM}%-34s${NC}" "${COMP_DESCS[$ci]}"
        [[ "${COMP_NEEDS_SUDO[$ci]}" -eq 1 ]] && printf " ${DIM}[${NC} ${YELLOW}sudo${NC} ${DIM}]${NC}"
        printf "\n"
    done

    printf "${CLEAR_LINE}\n"
    if [[ $selected_count -gt 0 ]]; then
        printf "${CLEAR_LINE}  ${RED}${BOLD}%d${NC}${DIM} component(s) selected for removal${NC}\n" "$selected_count"
    else
        printf "${CLEAR_LINE}  ${DIM}No components selected${NC}\n"
    fi
}

show_checkbox_menu() {
    local cursor=0 total=${#VISIBLE[@]}
    printf "${HIDE_CURSOR}"; CURSOR_HIDDEN=1

    for ((i = 0; i < total + 4; i++)); do printf "\n"; done
    render_menu $cursor

    while true; do
        local key; key=$(read_key)
        case "$key" in
            UP)    ((cursor > 0)) && ((cursor--)) ;;
            DOWN)  ((cursor < total - 1)) && ((cursor++)) ;;
            SPACE)
                local ci="${VISIBLE[$cursor]}"
                COMP_SELECTED[$ci]=$(( 1 - COMP_SELECTED[$ci] ))
                ;;
            A)
                local any=0
                for vi in "${!VISIBLE[@]}"; do
                    [[ "${COMP_SELECTED[${VISIBLE[$vi]}]}" -eq 1 ]] && any=1 && break
                done
                for vi in "${!VISIBLE[@]}"; do COMP_SELECTED[${VISIBLE[$vi]}]=$((1 - any)); done
                ;;
            ENTER) break ;;
            Q)
                printf "${SHOW_CURSOR}"; CURSOR_HIDDEN=0
                printf "\n  ${DIM}Aborted.${NC}\n\n"; exit 0
                ;;
        esac
        render_menu $cursor
    done
    printf "${SHOW_CURSOR}"; CURSOR_HIDDEN=0
}

# --- [J] Execution Engine ----------------------------------------------------

run_component_uninstall() {
    local idx=$1 step=$2 total=$3
    local comp_log="${LOG_FILE}.${COMP_IDS[$idx]}"

    load_env

    if [[ "$VERBOSE" -eq 1 ]]; then
        printf "\n"
        printf "  ${BOLD}${CYAN}[%d/%d]${NC} ${BOLD}${WHITE}%s${NC}\n" "$step" "$total" "${COMP_NAMES[$idx]}"
        printf "  ${CYAN}────────────────────────────────────────${NC}\n"
        if run_uninstall "$idx" 2>&1 | tee "$comp_log"; then
            printf "  ${CYAN}────────────────────────────────────────${NC}\n"
            printf "  ${SYM_CHECK} ${GREEN}%s${NC}\n" "${COMP_NAMES[$idx]}"
            return 0
        else
            printf "  ${CYAN}────────────────────────────────────────${NC}\n"
            printf "  ${SYM_CROSS} ${RED}%s${NC}\n" "${COMP_NAMES[$idx]}"
            return 1
        fi
    else
        start_spinner "Uninstalling ${COMP_NAMES[$idx]}..."
        run_uninstall "$idx" > "$comp_log" 2>&1
        local result=$?
        stop_spinner

        if [[ $result -eq 0 ]]; then
            printf "  ${SYM_CHECK} ${BOLD}${CYAN}[%d/%d]${NC} %s\n" "$step" "$total" "${COMP_NAMES[$idx]}"
            return 0
        else
            printf "  ${SYM_CROSS} ${BOLD}${CYAN}[%d/%d]${NC} ${RED}%s${NC}\n" "$step" "$total" "${COMP_NAMES[$idx]}"
            printf "  ${DIM}── last 15 lines ──${NC}\n"
            tail -n 15 "$comp_log" 2>/dev/null | sed 's/^/    /'
            printf "  ${DIM}── full log: %s ──${NC}\n" "$comp_log"
            return 1
        fi
    fi
}

run_all_selected() {
    local ordered=("$@")
    local total=${#ordered[@]} step=0 succeeded=0 failed=0
    local failed_names=() succeeded_names=()

    printf "\n"
    for idx in "${ordered[@]}"; do
        step=$((step + 1))
        if run_component_uninstall "$idx" "$step" "$total"; then
            succeeded=$((succeeded + 1)); succeeded_names+=("${COMP_NAMES[$idx]}")
        else
            failed=$((failed + 1)); failed_names+=("${COMP_NAMES[$idx]}")
        fi
    done

    # Summary
    printf "\n"
    printf "  ${BOLD}${CYAN}┌──────────────────────────────────────────┐${NC}\n"
    printf "  ${BOLD}${CYAN}│${NC}  ${BOLD}${WHITE}Uninstall Summary${NC}                       ${BOLD}${CYAN}│${NC}\n"
    printf "  ${BOLD}${CYAN}└──────────────────────────────────────────┘${NC}\n"
    printf "\n"

    for name in "${succeeded_names[@]}"; do printf "  ${SYM_CHECK} %s\n" "$name"; done
    for name in "${failed_names[@]}"; do printf "  ${SYM_CROSS} %s\n" "$name"; done

    printf "\n  ${DIM}Result: ${GREEN}${BOLD}%d removed${NC}" "$succeeded"
    [[ $failed -gt 0 ]] && printf " ${DIM}/${NC} ${RED}${BOLD}%d failed${NC}" "$failed"
    printf "\n"

    [[ $failed -gt 0 ]] && printf "\n  ${DIM}Logs: ${NC}${CYAN}${LOG_FILE}.*${NC}\n"
    printf "\n"
    return "$failed"
}

# --- [K] Argument Parser -----------------------------------------------------

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                NON_INTERACTIVE=1; shift ;;
            --components)
                IFS=',' read -ra REQUESTED <<< "$2"
                for req in "${REQUESTED[@]}"; do
                    req=$(echo "$req" | tr -d ' ')
                    for i in "${!COMP_IDS[@]}"; do
                        [[ "${COMP_IDS[$i]}" == "$req" ]] && COMP_SELECTED[$i]=1
                    done
                done
                NON_INTERACTIVE=1; shift 2 ;;
            --force)
                FORCE=1; shift ;;
            --list)
                setup_colors; load_env; detect_installed
                printf "\n  ${BOLD}Installed components:${NC}\n"; hr
                local count=0
                for i in "${!COMP_IDS[@]}"; do
                    if [[ "${COMP_INSTALLED[$i]}" -eq 1 ]]; then
                        printf "  ${SYM_CHECK} %-22s ${DIM}%s${NC}\n" "${COMP_NAMES[$i]}" "${COMP_DESCS[$i]}"
                        count=$((count + 1))
                    fi
                done
                [[ $count -eq 0 ]] && printf "  ${DIM}No rig components detected.${NC}\n"
                hr; printf "  ${DIM}Total: %d component(s)${NC}\n\n" "$count"
                exit 0 ;;
            --verbose|-v)
                VERBOSE=1; shift ;;
            --help|-h)
                show_help; exit 0 ;;
            -*)
                printf "${RED}Unknown option: %s${NC}\n" "$1"
                show_help; exit 1 ;;
            *)
                # Positional argument: component name
                local found=0
                for i in "${!COMP_IDS[@]}"; do
                    [[ "${COMP_IDS[$i]}" == "$1" ]] && { COMP_SELECTED[$i]=1; found=1; }
                done
                if [[ $found -eq 0 ]]; then
                    printf "${RED}Unknown component: %s${NC}\n" "$1"
                    printf "Valid: %s\n" "${COMP_IDS[*]}"
                    exit 1
                fi
                NON_INTERACTIVE=1; shift ;;
        esac
    done
}

# --- [L] Main ----------------------------------------------------------------

main() {
    setup_colors
    parse_args "$@"
    load_env

    # Determine interactive mode
    if [[ "$NON_INTERACTIVE" -eq 0 ]]; then
        if [[ -e /dev/tty ]]; then
            INTERACTIVE=1
        else
            echo "Error: No terminal available. Specify a component or use --all."
            echo "  Example: bash uninstall.sh docker"
            echo "  Example: bash uninstall.sh --all --force"
            exit 1
        fi
    fi

    LOG_FILE="/tmp/rig-uninstall-$(date +%Y%m%d-%H%M%S)"

    print_banner
    detect_installed

    local installed_count=0
    for v in "${COMP_INSTALLED[@]}"; do [[ "$v" -eq 1 ]] && installed_count=$((installed_count + 1)); done

    if [[ $installed_count -eq 0 ]]; then
        printf "  ${DIM}No rig components detected.${NC}\n\n"
        exit 0
    fi

    printf "  ${DIM}Found ${BOLD}%d${NC}${DIM} installed component(s)${NC}\n" "$installed_count"

    # Build visible mapping (only installed components)
    VISIBLE=()
    for i in "${!COMP_IDS[@]}"; do
        [[ "${COMP_INSTALLED[$i]}" -eq 1 ]] && VISIBLE+=("$i")
    done

    if [[ "$INTERACTIVE" -eq 1 ]]; then
        show_checkbox_menu
    else
        # Check if --all (no explicit selection)
        local has_explicit=0
        for s in "${COMP_SELECTED[@]}"; do [[ "$s" -eq 1 ]] && has_explicit=1 && break; done

        if [[ $has_explicit -eq 0 ]]; then
            # --all: select all installed
            for i in "${!COMP_INSTALLED[@]}"; do COMP_SELECTED[$i]=${COMP_INSTALLED[$i]}; done
        else
            # Warn about non-installed selections
            for i in "${!COMP_SELECTED[@]}"; do
                if [[ "${COMP_SELECTED[$i]}" -eq 1 && "${COMP_INSTALLED[$i]}" -eq 0 ]]; then
                    printf "  ${SYM_WARN} ${YELLOW}%s${NC} ${DIM}is not installed, skipping${NC}\n" "${COMP_NAMES[$i]}"
                    COMP_SELECTED[$i]=0
                fi
            done
        fi
    fi

    # Check at least one selected
    local any_selected=0
    for s in "${COMP_SELECTED[@]}"; do [[ "$s" -eq 1 ]] && any_selected=1 && break; done
    if [[ "$any_selected" -eq 0 ]]; then
        printf "  ${DIM}No components selected. Exiting.${NC}\n\n"
        exit 0
    fi

    # Build ordered list (reverse order: dependents before dependencies)
    local ordered=()
    for (( i=${#COMP_SELECTED[@]}-1; i>=0; i-- )); do
        [[ "${COMP_SELECTED[$i]}" -eq 1 ]] && ordered+=("$i")
    done

    # Check dependencies
    local blocked=0
    for idx in "${ordered[@]}"; do
        check_dependents "$idx" || ((blocked++))
    done
    if [[ $blocked -gt 0 && "$FORCE" -eq 0 ]]; then
        printf "\n  ${RED}${BOLD}Uninstall blocked.${NC} ${DIM}Resolve dependencies or use --force.${NC}\n\n"
        exit 1
    fi

    # Show plan
    printf "\n  ${BOLD}${SYM_PLAY} Uninstall plan${NC}\n"
    hr
    local step=0
    for idx in "${ordered[@]}"; do
        step=$((step + 1))
        local suffix=""
        [[ "${COMP_NEEDS_SUDO[$idx]}" -eq 1 ]] && suffix=" ${YELLOW}sudo${NC}"
        printf "  ${CYAN}%2d${NC} ${DIM}│${NC} %-24s${DIM}%s${NC}%b\n" \
            "$step" "${COMP_NAMES[$idx]}" "${COMP_DESCS[$idx]}" "$suffix"
    done
    hr
    printf "  ${DIM}Total: ${BOLD}%d${NC}${DIM} component(s) to remove${NC}\n\n" "${#ordered[@]}"

    # Confirm
    if [[ "$FORCE" -eq 0 && -e /dev/tty ]]; then
        printf "  ${RED}${BOLD}⚠ This action cannot be fully undone.${NC}\n"
        printf "  ${BOLD}Proceed with uninstall?${NC} ${DIM}[y/N]${NC} "
        local confirm_ans
        read -r confirm_ans </dev/tty
        if [[ ! "$confirm_ans" =~ ^[Yy] ]]; then
            printf "\n  ${DIM}Aborted.${NC}\n\n"
            exit 0
        fi
        printf "\n"
    fi

    # Collect data-removal confirmations for docker/ssh/claude-code
    collect_confirmations

    # Pre-cache sudo
    cache_sudo

    # Execute
    run_all_selected "${ordered[@]}"
    local result=$?

    printf "  ${DIM}Run ${CYAN}exec \$SHELL${NC} ${DIM}to reload your shell.${NC}\n"

    if [[ $result -eq 0 ]]; then
        printf "  ${SYM_CHECK} ${GREEN}${BOLD}All done!${NC}\n\n"
    else
        printf "  ${SYM_WARN} ${YELLOW}${BOLD}Some components failed. See logs above.${NC}\n\n"
    fi

    exit "$result"
}

main "$@"
