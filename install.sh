#!/bin/sh
# shellcheck shell=dash
#
# Licensed under the MIT license
# <LICENSE-MIT or https://opensource.org/licenses/MIT>, at your
# option. This file may not be copied, modified, or distributed
# except according to those terms.
#
VERSION="0.0.1"
RECEIPT_HOME="${HOME}/.dotfiles"
BASE_URL="https://github.com/pesap/.dotfiles/archive/refs/tags"
DOTFILES_REMOTE=""
DOTFILES_EXT=""
LOCAL_INSTALL=${INSTALLER_LOCAL_INSTALL:-0}
PRINT_VERBOSE=${INSTALLER_PRINT_VERBOSE:-0}
PRINT_QUIET=${INSTALLER_PRINT_QUIET:-0}
STOW_CMD=""
STOW_IGNORE="--ignore=\\.DS_Store"
FORCE_INSTALL=${INSTALLER_FORCE_INSTALL:-0}
DRY_RUN=${INSTALLER_DRY_RUN:-0}
BACKUP=${INSTALLER_BACKUP:-1}
BACKUP_DIR=""

set -eu

set_dotfiles_remote() {
    os="$(uname -s 2>/dev/null || echo unknown)"
    case "$os" in
        Darwin)
            DOTFILES_EXT=".zip"
            ;;
        Linux)
            DOTFILES_EXT=".tar.gz"
            ;;
        *)
            err "Unsupported OS: $os"
            ;;
    esac

    DOTFILES_REMOTE="${BASE_URL}/${VERSION}${DOTFILES_EXT}"
}

# NOTE: I can re-enable this if at some point I need more functionality
usage() {
    cat <<EOF
dotfiles.sh

The installer for my dotfiles

USAGE:
    dotfiles.sh [OPTIONS]

OPTIONS:
    -l, --local
            Use local checkout (no download)
    -v, --verbose
            Enable verbose output
    -y, --yes, --force
            Continue without prompting
    -n, --dry-run
            Show actions without making changes
    --no-backup
            Do not move existing files aside
    -h, --help
            Print help information
EOF
}

download_link_dotfiles(){
    for arg in "$@"; do
        case "$arg" in
                
            --help)
                usage
                exit 0
                ;;
            --local)
                LOCAL_INSTALL=1
                ;;
            --verbose)
                PRINT_VERBOSE=1
                ;;
            --yes|--force|-y)
                FORCE_INSTALL=1
                ;;
            --dry-run|-n)
                DRY_RUN=1
                ;;
            --no-backup)
                BACKUP=0
                ;;
        esac
    done

    downloader --check
    need_cmd mktemp
    need_cmd mkdir
    need_cmd rm
    need_cmd rsync

    # Check if stow is available
    if check_cmd stow; then
        say_verbose "stow command found."
        STOW_CMD="stow"
    elif [ -x "$HOME/.local/bin/stow" ]; then
        say_verbose "stow command found in ~/.local/bin."
        STOW_CMD="$HOME/.local/bin/stow"
    else
        install_stow
    fi

    _temp_dir="$(ensure mktemp -d)" || return 1

    _file="$_temp_dir/dotfiles$DOTFILES_EXT"
    say_verbose "Temporary dir created at: $_temp_dir"

    if [ "1" = "$LOCAL_INSTALL" ]; then
        if [ -n "${LOCAL_SOURCE:-}" ]; then
            local_source="$LOCAL_SOURCE"
        else
            local_source=$(cd "$(dirname "$0")" && pwd) || err "failed to resolve local source dir"
        fi
        for folder in "$local_source"/*/; do
            folder="${folder%/}"
            [ "$folder" = ".git" ] && continue
            folder="${folder##*/}"
            [ "$folder" = "docs" ] && continue
            [ "$folder" = "opencode" ] && continue
            link_files "$local_source" "$folder"
        done
        exit 0
    fi

    if [ "$DRY_RUN" = "1" ]; then
        if [ -d "$RECEIPT_HOME" ]; then
            for folder in "$RECEIPT_HOME"/*; do
                [ -d "$folder" ] || continue
                folder="${folder##*/}"
                [ "$folder" = ".git" ] && continue
                [ "$folder" = "docs" ] && continue
                [ "$folder" = "opencode" ] && continue
                link_files "$RECEIPT_HOME" "$folder"
            done
            exit 0
        fi
        err "dry-run requires --local or existing $RECEIPT_HOME"
    fi

    if ! downloader "$DOTFILES_REMOTE" "$_file"; then
        say "failed to download $DOTFILES_REMOTE"
        say "this may be a standard network error, but it may also indicate"
        say "an issue with the repository. Please check the URL or open an issue."
        exit 1
    fi

    if [ -d "$RECEIPT_HOME" ]; then
        if [ "${FORCE_INSTALL:-0}" = "1" ]; then
            say_verbose "$RECEIPT_HOME exists; continuing due to --force/--yes."
        elif [ -t 0 ]; then
            printf "%s already exists. Do you want to continue? [y/N] " "$RECEIPT_HOME"
            read -r confirm
            case "$confirm" in
                [yY][eE][sS]|[yY])
                    ;;
                *)
                    echo "Operation cancelled."
                    exit 1
                    ;;
            esac
        else
            say "$RECEIPT_HOME exists; continuing without prompt (non-interactive)."
        fi
    fi

    mkdir -p "$RECEIPT_HOME"
    _extract_dir="$_temp_dir"

    mkdir -p "$_extract_dir"

    if [ "$DOTFILES_EXT" = ".zip" ]; then
        need_cmd unzip
        ensure unzip -q "$_file" -d "$_extract_dir"
    elif [ "$DOTFILES_EXT" = ".tar.gz" ]; then
        say_verbose "Using tar to decompress $_file"
        ensure tar -xzf "$_file" --strip-components=1 -C "$_extract_dir"
    fi

    if [ "$DOTFILES_EXT" = ".zip" ]; then
        set -- "$_extract_dir"/*
        if [ -d "$1" ]; then
            rsync -ahq "$1/" "$RECEIPT_HOME"
        else
            rsync -ahq "$_extract_dir/" "$RECEIPT_HOME"
        fi
    else
        rsync -ahq "$_extract_dir/" "$RECEIPT_HOME"
    fi

    for folder in "$RECEIPT_HOME"/*; do
        [ -d "$folder" ] || continue
        folder="${folder##*/}"
        [ "$folder" = ".git" ] && continue
        [ "$folder" = "docs" ] && continue
        [ "$folder" = "opencode" ] && continue
        link_files "$RECEIPT_HOME" "$folder"
    done
    rm -rf "$_temp_dir"

    if [ -d "$HOME/.config/nvim" ]; then
        mkdir -p "$HOME/.vim/undodir"
    fi

    if [ "$DRY_RUN" != "1" ]; then
        verify_tools
    fi

    if [ -n "$BACKUP_DIR" ]; then
        say "backup: $BACKUP_DIR"
    fi
}

install_stow(){
    say "Stow not found. Installing it from source."
    _temp_dir=$(mktemp -d)
    (
        cd "$_temp_dir" || err "failed to enter temp dir"
        curl -O https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz
        tar xf stow-latest.tar.gz
        release=$(ls -Avr | grep -m1 -axEe 'stow-[0-9.]+')
        cd "$release" || err "failed to enter stow release dir"
        mkdir -p "$HOME/.local/bin"
        ./configure --prefix "$HOME/.local"
        make
        make install
    )
    STOW_CMD="$HOME/.local/bin/stow"
    rm -rf "$_temp_dir"
}

ensure_parent_dirs() {
    # Ensure common parent directories exist as real directories
    # to prevent stow from symlinking entire trees
    for dir in ".config" ".local" ".local/bin"; do
        target="$HOME/$dir"
        if [ ! -d "$target" ]; then
            if [ "$DRY_RUN" = "1" ]; then
                say "dry-run: mkdir -p $target"
            else
                mkdir -p "$target"
            fi
        fi
    done
}

link_files(){
    base_dir="$1"
    shift
    cd "$base_dir" || err "failed to enter $base_dir"
    ensure_parent_dirs
    for folder in "$@"; do
        [ -d "$folder" ] || continue
        if [ "$DRY_RUN" = "1" ]; then
            say "dry-run: $STOW_CMD -D $folder"
            "$STOW_CMD" -n -D $STOW_IGNORE "$folder"
            say "dry-run: $STOW_CMD $folder"
            "$STOW_CMD" -n $STOW_IGNORE "$folder"
            continue
        fi

        overwrite=0
        conflict_out="$(mktemp)"
        conflict_list="$(mktemp)"
        if ! "$STOW_CMD" -n $STOW_IGNORE "$folder" >"$conflict_out" 2>&1; then
            cat "$conflict_out"
            extract_stow_conflicts "$conflict_out" >"$conflict_list"
        fi

        if [ -s "$conflict_list" ]; then
            if [ "$BACKUP" != "1" ]; then
                rm -f "$conflict_out" "$conflict_list"
                err "conflicts detected; overwrite requires backups (re-run without --no-backup)"
            fi
            if [ "$FORCE_INSTALL" = "1" ]; then
                overwrite=1
            elif [ -t 0 ]; then
                printf "Conflicts detected for %s. Overwrite existing targets? [y/N] " "$folder"
                read -r confirm
                case "$confirm" in
                    [yY][eE][sS]|[yY])
                        overwrite=1
                        ;;
                    *)
                        rm -f "$conflict_out" "$conflict_list"
                        err "operation cancelled"
                        ;;
                esac
            else
                rm -f "$conflict_out" "$conflict_list"
                err "conflicts detected; run interactively or pass --force to overwrite"
            fi
        fi

        backup_list="$(mktemp)"
        backup_files "$base_dir/$folder" "$backup_list"
        if [ "$overwrite" = "1" ] && [ -s "$conflict_list" ]; then
            backup_conflicts "$conflict_list" "$backup_list"
        fi

        say_verbose "$STOW_CMD $folder"
        "$STOW_CMD" -D $STOW_IGNORE "$folder"
        if ! "$STOW_CMD" $STOW_IGNORE "$folder"; then
            say "stow failed for $folder; reverting changes"
            "$STOW_CMD" -D $STOW_IGNORE "$folder" >/dev/null 2>&1 || true
            restore_backups "$backup_list"
            rm -f "$conflict_out" "$conflict_list" "$backup_list"
            err "stow failed for $folder; changes reverted"
        fi

        rm -f "$conflict_out" "$conflict_list" "$backup_list"
    done
}

init_backup_dir() {
    if [ -n "$BACKUP_DIR" ]; then
        return 0
    fi
    need_cmd date
    ts="$(date +%Y%m%d%H%M%S)"
    BACKUP_DIR="${HOME}/.stow-backup/${ts}"
    if [ "$DRY_RUN" = "1" ]; then
        say "dry-run: mkdir -p $BACKUP_DIR"
    else
        mkdir -p "$BACKUP_DIR"
    fi
}

backup_target() {
    rel="$1"
    list_file="${2:-}"
    target="$HOME/$rel"
    if [ -e "$target" ] || [ -L "$target" ]; then
        backup_path="$BACKUP_DIR/$rel"
        if [ "$DRY_RUN" = "1" ]; then
            say "dry-run: mkdir -p $(dirname "$backup_path")"
            say "dry-run: mv $target $backup_path"
        else
            mkdir -p "$(dirname "$backup_path")"
            mv "$target" "$backup_path"
        fi
        if [ -n "$list_file" ]; then
            echo "$rel" >> "$list_file"
        fi
    fi
}

backup_files() {
    [ "$BACKUP" = "1" ] || return 0
    pkg_dir="$1"
    list_file="${2:-}"
    [ -d "$pkg_dir" ] || return 0
    init_backup_dir

    find "$pkg_dir" \( -type f -o -type l \) -print | while IFS= read -r src; do
        rel="${src#$pkg_dir/}"
        target="$HOME/$rel"
        if [ -e "$target" ] || [ -L "$target" ]; then
            if [ -L "$target" ] && check_cmd readlink; then
                link_target="$(readlink "$target" 2>/dev/null || echo '')"
                if [ "$link_target" = "$src" ]; then
                    continue
                fi
            fi
            backup_target "$rel" "$list_file"
        fi
    done
}

backup_conflicts() {
    conflict_list="$1"
    list_file="$2"
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        backup_target "$rel" "$list_file"
    done < "$conflict_list"
}

restore_backups() {
    list_file="$1"
    [ -s "$list_file" ] || return 0
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        backup_path="$BACKUP_DIR/$rel"
        target="$HOME/$rel"
        [ -e "$backup_path" ] || continue
        if [ -e "$target" ] || [ -L "$target" ]; then
            rm -rf "$target"
        fi
        mkdir -p "$(dirname "$target")"
        mv "$backup_path" "$target"
    done < "$list_file"
}

extract_stow_conflicts() {
    awk '
        /cannot stow/ {
            if (match($0, /stow: [^ ]+$/)) {
                s = substr($0, RSTART, RLENGTH)
                sub(/^stow: /, "", s)
                seen[s] = 1
            }
            next
        }
        /existing target is not owned by stow:/ {
            if (match($0, /stow: [^ ]+$/)) {
                s = substr($0, RSTART, RLENGTH)
                sub(/^stow: /, "", s)
                seen[s] = 1
            }
        }
        END { for (k in seen) print k }
    ' "$1"
}

verify_tools() {
    for tool in stow git curl rsync; do
        if check_cmd "$tool"; then
            say_verbose "ok: $tool"
        else
            say "missing: $tool"
        fi
    done

    for tool in nvim rg cargo dotcfg; do
        if check_cmd "$tool"; then
            say_verbose "ok: $tool"
        else
            say "missing: $tool (optional)"
        fi
    done
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
