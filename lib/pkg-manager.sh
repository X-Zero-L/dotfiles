#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Package Manager Abstraction Library
# https://github.com/X-Zero-L/rig
#
# Provides a unified interface for package operations across different
# OS families and package managers (apt, dnf, yum, pacman, brew).
#
# Must be sourced after lib/os-detect.sh and lib/pkg-maps.sh.
#
# Usage:
#   source lib/os-detect.sh
#   source lib/pkg-maps.sh
#   source lib/pkg-manager.sh
#
#   pkg_install curl git wget
#   pkg_check_installed curl && echo "curl is available"
#   pkg_remove unused-package
#
# Exported functions:
#   pkg_install <packages...>       - Install one or more packages
#   pkg_update <packages...>        - Update specific packages (or all if none given)
#   pkg_remove <packages...>        - Remove one or more packages
#   pkg_check_installed <package>   - Check if a single package is installed
#   pkg_add_repo <repo_info>        - Add a package repository (distro-specific)
# =============================================================================

# Guard against double-sourcing
if [[ -n "${_PKG_MANAGER_LOADED:-}" ]]; then
    # shellcheck disable=SC2317
    return 0 2>/dev/null || true
fi
_PKG_MANAGER_LOADED=1

# Require dependencies
if [[ -z "${OS_FAMILY:-}" ]]; then
    echo "Error: lib/pkg-manager.sh requires lib/os-detect.sh to be sourced first." >&2
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

if ! declare -f pkg_map &>/dev/null; then
    echo "Error: lib/pkg-manager.sh requires lib/pkg-maps.sh to be sourced first." >&2
    # shellcheck disable=SC2317
    return 1 2>/dev/null || exit 1
fi

# --- Internal Helpers --------------------------------------------------------

# _sudo_if_needed - Run a command with sudo if not already root.
_sudo_if_needed() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

# _map_packages <names...> - Resolve abstract names to distro-specific names.
# Filters out empty strings (packages not available on this platform).
# Prints resolved names space-separated.
_map_packages() {
    local resolved=()
    local name mapped
    for name in "$@"; do
        mapped="$(pkg_map "$name")"
        if [[ -n "$mapped" ]]; then
            resolved+=("$mapped")
        fi
    done
    echo "${resolved[*]}"
}

# --- Public API --------------------------------------------------------------

# pkg_install <packages...> - Install one or more packages.
# Package names can be abstract (mapped via pkg-maps.sh) or literal.
# Returns 0 on success, non-zero on failure.
#
# Examples:
#   pkg_install curl git wget
#   pkg_install build-tools    # → build-essential (Debian), base-devel (Arch)
pkg_install() {
    if [[ $# -eq 0 ]]; then
        echo "Error: pkg_install requires at least one package name." >&2
        return 1
    fi

    local mapped
    mapped="$(_map_packages "$@")"

    if [[ -z "$mapped" ]]; then
        echo "Warning: No installable packages resolved for this platform." >&2
        return 0
    fi

    # shellcheck disable=SC2086
    case "$PKG_MANAGER" in
        apt)
            _sudo_if_needed apt-get update -qq
            _sudo_if_needed apt-get install -y -qq $mapped
            ;;
        dnf)
            _sudo_if_needed dnf install -y $mapped
            ;;
        yum)
            _sudo_if_needed yum install -y $mapped
            ;;
        pacman)
            _sudo_if_needed pacman -Sy --noconfirm $mapped
            ;;
        brew)
            # Homebrew should not run as root
            brew install $mapped
            ;;
        *)
            echo "Error: Unsupported package manager '$PKG_MANAGER'." >&2
            return 1
            ;;
    esac
}

# pkg_update [packages...] - Update specific packages, or all packages if none given.
# Returns 0 on success, non-zero on failure.
#
# Examples:
#   pkg_update           # update all packages
#   pkg_update curl git  # update only curl and git
pkg_update() {
    if [[ $# -eq 0 ]]; then
        # Update all packages
        case "$PKG_MANAGER" in
            apt)
                _sudo_if_needed apt-get update -qq
                _sudo_if_needed apt-get upgrade -y -qq
                ;;
            dnf)
                _sudo_if_needed dnf upgrade -y
                ;;
            yum)
                _sudo_if_needed yum update -y
                ;;
            pacman)
                _sudo_if_needed pacman -Syu --noconfirm
                ;;
            brew)
                brew update && brew upgrade
                ;;
            *)
                echo "Error: Unsupported package manager '$PKG_MANAGER'." >&2
                return 1
                ;;
        esac
    else
        local mapped
        mapped="$(_map_packages "$@")"

        if [[ -z "$mapped" ]]; then
            echo "Warning: No updatable packages resolved for this platform." >&2
            return 0
        fi

        # shellcheck disable=SC2086
        case "$PKG_MANAGER" in
            apt)
                _sudo_if_needed apt-get update -qq
                _sudo_if_needed apt-get install --only-upgrade -y -qq $mapped
                ;;
            dnf)
                _sudo_if_needed dnf upgrade -y $mapped
                ;;
            yum)
                _sudo_if_needed yum update -y $mapped
                ;;
            pacman)
                _sudo_if_needed pacman -Sy --noconfirm $mapped
                ;;
            brew)
                brew upgrade $mapped
                ;;
            *)
                echo "Error: Unsupported package manager '$PKG_MANAGER'." >&2
                return 1
                ;;
        esac
    fi
}

# pkg_remove <packages...> - Remove one or more packages.
# Returns 0 on success, non-zero on failure.
#
# Example:
#   pkg_remove unused-package
pkg_remove() {
    if [[ $# -eq 0 ]]; then
        echo "Error: pkg_remove requires at least one package name." >&2
        return 1
    fi

    local mapped
    mapped="$(_map_packages "$@")"

    if [[ -z "$mapped" ]]; then
        echo "Warning: No removable packages resolved for this platform." >&2
        return 0
    fi

    # shellcheck disable=SC2086
    case "$PKG_MANAGER" in
        apt)
            _sudo_if_needed apt-get remove -y -qq $mapped
            ;;
        dnf)
            _sudo_if_needed dnf remove -y $mapped
            ;;
        yum)
            _sudo_if_needed yum remove -y $mapped
            ;;
        pacman)
            _sudo_if_needed pacman -Rs --noconfirm $mapped
            ;;
        brew)
            brew uninstall $mapped
            ;;
        *)
            echo "Error: Unsupported package manager '$PKG_MANAGER'." >&2
            return 1
            ;;
    esac
}

# pkg_check_installed <package> - Check if a package is installed.
# Accepts either an abstract name or a literal package name.
# Returns 0 if installed, 1 if not.
#
# Example:
#   if pkg_check_installed curl; then echo "curl is installed"; fi
pkg_check_installed() {
    if [[ $# -ne 1 ]]; then
        echo "Error: pkg_check_installed requires exactly one package name." >&2
        return 1
    fi

    local name="$1"
    local mapped
    mapped="$(pkg_map "$name")"

    # If mapping returned empty, the package is not applicable on this platform
    if [[ -z "$mapped" ]]; then
        return 1
    fi

    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$mapped" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$mapped" &>/dev/null
            ;;
        pacman)
            pacman -Qi "$mapped" &>/dev/null
            ;;
        brew)
            brew list "$mapped" &>/dev/null
            ;;
        *)
            # Fallback: check if a command with that name exists
            command -v "$mapped" &>/dev/null
            ;;
    esac
}

# pkg_add_repo <repo_info> - Add a package repository.
# The format of repo_info depends on the OS family:
#   - Debian/Ubuntu: a full sources.list line or PPA (e.g. "ppa:user/repo")
#   - RHEL/Fedora:   a .repo URL or repo file content
#   - Arch:          not supported (use AUR helpers)
#   - macOS:         a Homebrew tap (e.g. "user/repo")
#
# Returns 0 on success, non-zero on failure.
#
# Examples:
#   pkg_add_repo "ppa:git-core/ppa"                         # Debian/Ubuntu PPA
#   pkg_add_repo "https://example.com/repo.rpm"             # RHEL/Fedora repo RPM
#   pkg_add_repo "homebrew/cask"                             # macOS Homebrew tap
pkg_add_repo() {
    if [[ $# -ne 1 ]]; then
        echo "Error: pkg_add_repo requires exactly one argument." >&2
        return 1
    fi

    local repo_info="$1"

    case "$PKG_MANAGER" in
        apt)
            if [[ "$repo_info" == ppa:* ]]; then
                # PPA format
                if ! command -v add-apt-repository &>/dev/null; then
                    _sudo_if_needed apt-get install -y -qq software-properties-common
                fi
                _sudo_if_needed add-apt-repository -y "$repo_info"
            else
                # Direct sources.list line
                echo "$repo_info" | _sudo_if_needed tee -a /etc/apt/sources.list.d/rig-custom.list >/dev/null
            fi
            _sudo_if_needed apt-get update -qq
            ;;
        dnf)
            _sudo_if_needed dnf config-manager --add-repo "$repo_info" || \
                _sudo_if_needed dnf install -y "$repo_info"
            ;;
        yum)
            if [[ "$repo_info" == http* && "$repo_info" == *.rpm ]]; then
                _sudo_if_needed yum install -y "$repo_info"
            else
                _sudo_if_needed yum-config-manager --add-repo "$repo_info" 2>/dev/null || \
                    echo "$repo_info" | _sudo_if_needed tee -a /etc/yum.repos.d/rig-custom.repo >/dev/null
            fi
            ;;
        pacman)
            echo "Warning: pkg_add_repo is not supported on Arch. Use an AUR helper instead." >&2
            return 1
            ;;
        brew)
            brew tap "$repo_info"
            ;;
        *)
            echo "Error: Unsupported package manager '$PKG_MANAGER'." >&2
            return 1
            ;;
    esac
}
