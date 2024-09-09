#!/bin/sh
# shellcheck shell=dash
#
# Licensed under the MIT license
# <LICENSE-MIT or https://opensource.org/licenses/MIT>, at your
# option. This file may not be copied, modified, or distributed
# except according to those terms.
#
VERSION="0.0.1"
RECEIPT_HOME="${HOME}/.dotfiles_test"
BASE_URL="https://github.com/pesap/.dotfiles/archive/refs/tags"
DOTFILES_REMOTE=""
PRINT_VERBOSE=${INSTALLER_PRINT_VERBOSE:-0}
PRINT_QUIET=${INSTALLER_PRINT_QUIET:-0}

set -u

set_dotfiles_remote() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        _ext=".zip"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        _ext=".tar.gz"
    else
        err "Unsupported OS: $OSTYPE"
    fi

    DOTFILES_REMOTE="${BASE_URL}/${VERSION}${_ext}"
}

# NOTE: I can re-enable this if at some point I need more functionality
usage() {
    cat <<EOF
dotfiles.sh

The installer for my dotfiles

USAGE:
    dotfiles.sh [OPTIONS]

OPTIONS:
    -v, --verbose
            Enable verbose output
    -h, --help
            Print help information
EOF
}

download_link_dotfiles(){
    downloader --check
    need_cmd mktemp
    need_cmd mkdir
    need_cmd rm
    need_cmd rsync
    need_cmd stow || need_cmd ln  # Use stow if available, fallback to ln

    for arg in "$@"; do
        case "$arg" in
            --help)
                usage
                exit 0
                ;;
            --verbose)
                PRINT_VERBOSE=1
                ;;
        esac
    done

    local _temp_dir
    _temp_dir="$(ensure mktemp -d)" || return 1
    local _url

    local _file="$_temp_dir/dotfiles$_ext"
    say_verbose "Temporary dict created at: $_temp_dir"

    if ! downloader "$DOTFILES_REMOTE" "$_file"; then
        say "failed to download $DOTFILES_REMOTE"
        say "this may be a standard network error, but it may also indicate"
        say "an issue with the repository. Please check the URL or open an issue."
        exit 1
    fi

    if [ -d "$RECEIPT_HOME" ]; then
        read -p "$RECEIPT_HOME already exists. Do you want to continue? [y/N] " confirm
        case "$confirm" in
            [yY][eE][sS]|[yY])
                ;;
            *)
                echo "Operation cancelled."
                exit 1
                ;;
        esac
    fi

    mkdir -p "$RECEIPT_HOME"
    local _extract_dir="$_temp_dir"

    mkdir -p "$_extract_dir"

    if [[ "$_ext" == ".zip" ]]; then
        need_cmd unzip
        ensure unzip -q "$_file" -d "$_extract_dir"
    elif [[ "$_ext" == ".tar.gz" ]]; then
        ensure tar -xzf --strip-components=1  "$_file" -C "$_extract_dir"
    fi

    parent_dir=$(find "$_extract_dir" -mindepth 1 -maxdepth 1 -type d)
    say_verbose $parent_dir
    if [ -d "$parent_dir" ]; then
        rsync -ahq "$parent_dir/" "$RECEIPT_HOME"
    fi

    cd "$RECEIPT_HOME" || return 1

    pushd $RECEIPT_HOME

    folders=($(ls -d */))

    folders=("${folders[@]%/}")

    link_files $folders

    rm -rf "$_temp_dir"
}

link_files(){
    if check_cmd stow; then
        for folder in ${1}; do
            echo "stow $folder"
            stow -D $folder
            stow $folder
        done
        popd
    else
        err "Stow not found. Install it"
    fi
}

ensure() {
    if ! "$@"; then err "command failed: $*"; fi
}

need_cmd() {
    if ! check_cmd "$1"; then err "need '$1' (command not found)"; fi
}

check_cmd() {
    command -v "$1" > /dev/null 2>&1
    return $?
}

downloader() {
    if check_cmd curl; then
        _dld=curl
    elif check_cmd wget; then
        _dld=wget
    else
        err "Neither curl nor wget found"
    fi

    if [ "$1" = --check ]; then
        need_cmd "$_dld"
    elif [ "$_dld" = curl ]; then
        curl -sSfL "$1" -o "$2"
    elif [ "$_dld" = wget ]; then
        wget "$1" -O "$2"
    else
        err "Unknown downloader"
    fi
}

say() {
    echo "$1"
}
say_verbose() {
    if [ "1" = "$PRINT_VERBOSE" ]; then
        echo "$1"
    fi
}
err() {
    if [ "0" = "$PRINT_QUIET" ]; then
        local red
        local reset
        red=$(tput setaf 1 2>/dev/null || echo '')
        reset=$(tput sgr0 2>/dev/null || echo '')
        say "${red}ERROR${reset}: $1" >&2
    fi
    exit 1
}

set_dotfiles_remote

download_link_dotfiles "$@" || exit 1
