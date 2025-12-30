#!/bin/sh
# POSIX bootstrap for prerequisites + installer.

set -u

VERSION="${INSTALLER_VERSION:-0.0.1}"
REPO_RAW_BASE="https://raw.githubusercontent.com/pesap/.dotfiles"
INSTALLER_URL="${REPO_RAW_BASE}/${VERSION}/install.sh"

say() {
    echo "$1"
}

err() {
    say "ERROR: $1" >&2
    exit 1
}

check_cmd() {
    command -v "$1" >/dev/null 2>&1
}

need_cmd() {
    if ! check_cmd "$1"; then
        err "need '$1' (command not found)"
    fi
}

download() {
    if check_cmd curl; then
        curl -sSfL "$1" -o "$2"
    elif check_cmd wget; then
        wget "$1" -O "$2"
    else
        err "Neither curl nor wget found"
    fi
}

maybe_sudo() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif check_cmd sudo; then
        sudo "$@"
    else
        err "sudo not found; run as root to install packages"
    fi
}

install_packages() {
    pkgs="$*"
    if check_cmd brew; then
        brew install $pkgs
        return 0
    fi
    if check_cmd apt-get; then
        maybe_sudo apt-get update
        maybe_sudo apt-get install -y $pkgs
        return 0
    fi
    if check_cmd dnf; then
        maybe_sudo dnf install -y $pkgs
        return 0
    fi
    if check_cmd pacman; then
        maybe_sudo pacman -Syu --noconfirm $pkgs
        return 0
    fi
    if check_cmd zypper; then
        maybe_sudo zypper install -y $pkgs
        return 0
    fi

    err "No supported package manager found"
}

ensure_prereqs() {
    missing=""
    for tool in git curl rsync stow tar unzip; do
        if ! check_cmd "$tool"; then
            missing="$missing $tool"
        fi
    done

    if [ -n "$missing" ]; then
        say "Installing prerequisites:$missing"
        install_packages $missing
    fi
}

run_installer() {
    need_cmd mktemp
    tmp_dir="$(mktemp -d)"
    installer="$tmp_dir/install.sh"
    download "$INSTALLER_URL" "$installer"
    sh "$installer" "$@"
    rm -rf "$tmp_dir"
}

ensure_prereqs
run_installer "$@"
