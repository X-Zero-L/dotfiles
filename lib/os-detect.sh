#!/usr/bin/env bash
# shellcheck disable=SC2034  # Variables are set here for use by consumers who source this file
set -euo pipefail

# =============================================================================
# OS Detection Library
# https://github.com/X-Zero-L/rig
#
# Detects OS family, distribution, version, and package manager.
# Exports variables and convenience functions for multi-OS scripting.
#
# Usage:
#   source lib/os-detect.sh
#
# Exported variables:
#   OS_FAMILY    - debian, rhel, fedora, arch, macos, unknown
#   OS_DISTRO    - Ubuntu, Debian, CentOS, RHEL, Fedora, Arch, macOS, unknown
#   OS_VERSION   - e.g. "22.04", "9", "40", "14.5"
#   PKG_MANAGER  - apt, dnf, yum, pacman, brew, unknown
#
# Exported functions:
#   is_debian, is_rhel, is_fedora, is_arch, is_macos
#   detect_os (re-run detection)
# =============================================================================

# Guard against double-sourcing
if [[ -n "${_OS_DETECT_LOADED:-}" ]]; then
    # shellcheck disable=SC2317
    return 0 2>/dev/null || true
fi
_OS_DETECT_LOADED=1

# --- Variables ---------------------------------------------------------------

OS_FAMILY="unknown"
OS_DISTRO="unknown"
OS_VERSION="unknown"
PKG_MANAGER="unknown"

# --- Detection ---------------------------------------------------------------

# detect_os - Detect the current OS family, distro, version, and package manager.
# Sets OS_FAMILY, OS_DISTRO, OS_VERSION, PKG_MANAGER.
# Returns 0 on success, 1 if OS could not be identified.
detect_os() {
    local uname_s
    uname_s="$(uname -s)"

    case "$uname_s" in
        Darwin)
            OS_FAMILY="macos"
            OS_DISTRO="macOS"
            OS_VERSION="$(sw_vers -productVersion 2>/dev/null || echo "unknown")"
            PKG_MANAGER="brew"
            return 0
            ;;
        Linux)
            _detect_linux
            return $?
            ;;
        *)
            OS_FAMILY="unknown"
            OS_DISTRO="unknown"
            OS_VERSION="unknown"
            PKG_MANAGER="unknown"
            return 1
            ;;
    esac
}

# _detect_linux - Internal: parse /etc/os-release to identify the Linux distro.
_detect_linux() {
    local id=""
    local id_like=""
    local version_id=""
    local name=""

    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release 2>/dev/null || true
        id="${ID:-}"
        id_like="${ID_LIKE:-}"
        version_id="${VERSION_ID:-}"
        name="${NAME:-}"
    elif [[ -f /etc/redhat-release ]]; then
        # Fallback for older RHEL/CentOS without os-release
        if grep -qi "centos" /etc/redhat-release 2>/dev/null; then
            id="centos"
        elif grep -qi "red hat" /etc/redhat-release 2>/dev/null; then
            id="rhel"
        elif grep -qi "fedora" /etc/redhat-release 2>/dev/null; then
            id="fedora"
        fi
        version_id="$(grep -oP '[0-9]+(\.[0-9]+)?' /etc/redhat-release 2>/dev/null | head -1 || echo "unknown")"
    fi

    OS_VERSION="${version_id:-unknown}"

    case "$id" in
        ubuntu)
            OS_FAMILY="debian"
            OS_DISTRO="Ubuntu"
            ;;
        debian)
            OS_FAMILY="debian"
            OS_DISTRO="Debian"
            ;;
        linuxmint|pop|elementary|zorin|neon)
            # Debian/Ubuntu derivatives
            OS_FAMILY="debian"
            OS_DISTRO="${name:-$id}"
            ;;
        centos)
            OS_FAMILY="rhel"
            OS_DISTRO="CentOS"
            ;;
        rhel|rocky|almalinux|ol)
            OS_FAMILY="rhel"
            OS_DISTRO="${name:-RHEL}"
            ;;
        fedora)
            OS_FAMILY="fedora"
            OS_DISTRO="Fedora"
            ;;
        arch|manjaro|endeavouros)
            OS_FAMILY="arch"
            OS_DISTRO="${name:-Arch}"
            ;;
        *)
            # Fallback: use ID_LIKE to guess the family
            if _id_like_contains "$id_like" "debian" || _id_like_contains "$id_like" "ubuntu"; then
                OS_FAMILY="debian"
                OS_DISTRO="${name:-$id}"
            elif _id_like_contains "$id_like" "rhel" || _id_like_contains "$id_like" "centos"; then
                OS_FAMILY="rhel"
                OS_DISTRO="${name:-$id}"
            elif _id_like_contains "$id_like" "fedora"; then
                OS_FAMILY="fedora"
                OS_DISTRO="${name:-$id}"
            elif _id_like_contains "$id_like" "arch"; then
                OS_FAMILY="arch"
                OS_DISTRO="${name:-$id}"
            else
                OS_FAMILY="unknown"
                OS_DISTRO="${name:-unknown}"
            fi
            ;;
    esac

    _detect_pkg_manager
}

# _id_like_contains <id_like_string> <target> - Check if ID_LIKE contains a target.
_id_like_contains() {
    local id_like="$1"
    local target="$2"
    [[ " $id_like " == *" $target "* ]] || [[ "$id_like" == "$target" ]]
}

# _detect_pkg_manager - Internal: determine the available package manager.
_detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
    elif command -v pacman &>/dev/null; then
        PKG_MANAGER="pacman"
    elif command -v brew &>/dev/null; then
        PKG_MANAGER="brew"
    else
        PKG_MANAGER="unknown"
    fi
}

# --- Convenience Functions ---------------------------------------------------

# is_debian - Returns 0 if the current OS is in the Debian family (Debian, Ubuntu, Mint, etc.).
is_debian() { [[ "$OS_FAMILY" == "debian" ]]; }

# is_rhel - Returns 0 if the current OS is in the RHEL family (RHEL, CentOS, Rocky, Alma, etc.).
is_rhel() { [[ "$OS_FAMILY" == "rhel" ]]; }

# is_fedora - Returns 0 if the current OS is Fedora.
is_fedora() { [[ "$OS_FAMILY" == "fedora" ]]; }

# is_arch - Returns 0 if the current OS is in the Arch family (Arch, Manjaro, etc.).
is_arch() { [[ "$OS_FAMILY" == "arch" ]]; }

# is_macos - Returns 0 if the current OS is macOS.
is_macos() { [[ "$OS_FAMILY" == "macos" ]]; }

# --- Auto-detect on source ---------------------------------------------------

detect_os
