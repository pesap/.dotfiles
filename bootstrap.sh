#!/bin/sh
# POSIX bootstrap for prerequisites + installer.

set -eu

VERSION="${INSTALLER_VERSION:-0.0.4}"
REPO_RAW_BASE="https://raw.githubusercontent.com/pesap/.dotfiles"
INSTALLER_URL="${REPO_RAW_BASE}/${VERSION}/install.sh"
INSTALLER_SHA256="${INSTALLER_SHA256:-}"

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

expected_installer_sha256() {
    if [ -n "$INSTALLER_SHA256" ]; then
        printf '%s\n' "$INSTALLER_SHA256"
        return
    fi

    case "$VERSION" in
    0.0.4) printf '%s\n' '30d49bab146a082bbb347419a4a2ae31360da20312d174b638fb39f9dc567659' ;;
    *) err "no installer checksum recorded for version '$VERSION'; set INSTALLER_SHA256 explicitly" ;;
    esac
}

verify_sha256() {
    file="$1"
    expected="$2"

    if check_cmd sha256sum; then
        actual="$(sha256sum "$file" | awk '{print $1}')"
    elif check_cmd shasum; then
        actual="$(shasum -a 256 "$file" | awk '{print $1}')"
    else
        err "need 'sha256sum' or 'shasum' to verify the installer"
    fi

    [ "$actual" = "$expected" ] ||
        err "installer checksum mismatch for version '$VERSION'"
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
        # shellcheck disable=SC2086
        brew install $pkgs
        return 0
    fi
    if check_cmd apt-get; then
        maybe_sudo apt-get update
        # shellcheck disable=SC2086
        maybe_sudo apt-get install -y $pkgs
        return 0
    fi
    if check_cmd dnf; then
        # shellcheck disable=SC2086
        maybe_sudo dnf install -y $pkgs
        return 0
    fi
    if check_cmd pacman; then
        # shellcheck disable=SC2086
        maybe_sudo pacman -Syu --noconfirm $pkgs
        return 0
    fi
    if check_cmd zypper; then
        # shellcheck disable=SC2086
        maybe_sudo zypper install -y $pkgs
        return 0
    fi

    err "No supported package manager found"
}

ensure_prereqs() {
    missing=""
    for tool in git curl rsync stow tar unzip mise; do
        if ! check_cmd "$tool"; then
            missing="$missing $tool"
        fi
    done

    if [ -n "$missing" ]; then
        say "Installing prerequisites:$missing"
        install_packages "$missing"
    fi
}

run_installer() {
    need_cmd mktemp
    bootstrap_temp_dir="$(mktemp -d /var/tmp/dotfiles-test.bootstrap.XXXXXX)"
    cleanup() {
        status=$?
        trap - 0 HUP INT TERM
        resolved_bootstrap_temp_dir="$(cd "$bootstrap_temp_dir" 2>/dev/null && pwd -P)" || resolved_bootstrap_temp_dir=""
        case "$resolved_bootstrap_temp_dir" in
        /var/tmp/dotfiles-test.bootstrap.*)
            if [ -n "$resolved_bootstrap_temp_dir" ] && [ -d "$resolved_bootstrap_temp_dir" ] && [ ! -L "$bootstrap_temp_dir" ]; then
                rm -rf -- "$resolved_bootstrap_temp_dir"
            else
                printf '%s\n' "ERROR: refusing to clean unexpected temporary path: $resolved_bootstrap_temp_dir" >&2
                status=1
            fi
            ;;
        *)
            printf '%s\n' "ERROR: refusing to clean unexpected temporary path: $resolved_bootstrap_temp_dir" >&2
            status=1
            ;;
        esac
        exit "$status"
    }
    trap cleanup 0 HUP INT TERM
    installer="$bootstrap_temp_dir/install.sh"
    download "$INSTALLER_URL" "$installer"
    verify_sha256 "$installer" "$(expected_installer_sha256)"
    sh "$installer" "$@"
}

ensure_prereqs
run_installer "$@"
