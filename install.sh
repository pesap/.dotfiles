#!/bin/sh
# shellcheck shell=dash
#
# Licensed under the MIT license
# <LICENSE-MIT.txt or https://opensource.org/licenses/MIT>, at your
# option. This file may not be copied, modified, or distributed
# except according to those terms.
#
VERSION="${INSTALLER_VERSION:-0.0.4}"
RECEIPT_HOME="${HOME}/.dotfiles"
BASE_URL="https://github.com/pesap/.dotfiles/archive/refs/tags"
DOTFILES_REMOTE=""
DOTFILES_EXT=""
LOCAL_INSTALL=${INSTALLER_LOCAL_INSTALL:-0}
PRINT_VERBOSE=${INSTALLER_PRINT_VERBOSE:-0}
PRINT_QUIET=${INSTALLER_PRINT_QUIET:-0}
STOW_CMD=""
STOW_IGNORE="--ignore=\\.DS_Store|local.toml"
STOW_VERSION="2.4.1"
STOW_SHA256="2a671e75fc207303bfe86a9a7223169c7669df0a8108ebdf1a7fe8cd2b88780b"
FORCE_INSTALL=${INSTALLER_FORCE_INSTALL:-0}
DRY_RUN=${INSTALLER_DRY_RUN:-0}
BACKUP=${INSTALLER_BACKUP:-1}
BACKUP_DIR=""
PROFILE="${DOTFILES_PROFILE:-common}"

set -eu
_temp_dir=""
_stow_build_dir=""
cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    for cleanup_dir in "${_temp_dir:-}" "${_stow_build_dir:-}"; do
        [ -z "$cleanup_dir" ] && continue
        if ! safe_remove_temp_dir "$cleanup_dir"; then
            printf '%s\n' "ERROR: refusing to clean unexpected temporary path: $cleanup_dir" >&2
            status=1
        fi
    done
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

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
loom setup

The installer for this workstation configuration

USAGE:
    loom setup [OPTIONS]

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
    --profile PROFILE
            Select common, linux-desktop, or macos configuration
    --list-profiles
            List supported profiles and exit
    -h, --help
            Print help information
EOF
}

list_profiles() { printf '%s\n' common linux-desktop macos; }
select_profile() {
    case "$PROFILE" in
    common) ;;
    linux-desktop) [ "$(uname -s)" = Linux ] || err 'linux-desktop profile requires Linux' ;;
    macos) [ "$(uname -s)" = Darwin ] || err 'macos profile requires macOS' ;;
    *) err "unknown profile '$PROFILE'" ;;
    esac
}
parse_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
        --help | -h)
            usage
            exit 0
            ;;
        --list-profiles)
            list_profiles
            exit 0
            ;;
        --profile)
            [ "$#" -gt 1 ] || err '--profile requires a value'
            PROFILE="$2"
            shift
            ;;
        --profile=*) PROFILE="${1#--profile=}" ;; --local | -l) LOCAL_INSTALL=1 ;;
        --verbose | -v) PRINT_VERBOSE=1 ;; --yes | --force | -y) FORCE_INSTALL=1 ;;
        --dry-run | -n) DRY_RUN=1 ;; --no-backup) BACKUP=0 ;;
        *) err "unknown option: $1" ;;
        esac
        shift
    done
}
profile_packages() {
    manifest="$1/packages.conf"
    if [ ! -f "$manifest" ]; then
        script_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)"
        [ -f "$script_dir/packages.conf" ] || err "missing package manifest: $manifest"
        manifest="$script_dir/packages.conf"
    fi
    packages="$(awk -v profile="$PROFILE" '
        /^[[:space:]]*#/ || NF == 0 { next }
        $1 == profile { $1 = ""; sub(/^[[:space:]]+/, ""); print; found = 1; exit }
        END { if (!found) exit 1 }
    ' "$manifest")" || err "profile '$PROFILE' missing from $manifest"
    [ -n "$packages" ] || err "profile '$PROFILE' has no packages"
    printf '%s\n' "$packages"
}
safe_package_name() {
    case "$1" in
    *[!A-Za-z0-9_-]* | '') return 1 ;;
    *) return 0 ;;
    esac
}
install_selected_packages() {
    base="$1"
    packages="$(profile_packages "$base")"
    for folder in $packages; do
        safe_package_name "$folder" || err "unsafe package name in manifest: $folder"
        if [ "$folder" != man ] && { [ -d "$base/$folder/.local/share" ] || [ -d "$base/$folder/.cargo" ] || [ -d "$base/$folder/.rustup" ]; }; then
            err "refusing to stow runtime state from package: $folder"
        fi
        if [ -d "$base/$folder" ]; then
            link_files "$base" "$folder"
        elif [ "$folder" = work ] || [ "$folder" = personal ]; then
            say "skipping optional package unavailable: $folder"
        else err "profile package missing: $folder"; fi
    done
}
select_alacritty_overlay() {
    base="$1"
    overlay=local.linux.toml
    [ "$PROFILE" = macos ] && overlay=local.macos.toml
    source="$base/alacritty/.config/alacritty/$overlay"
    target="$HOME/.config/alacritty/local.toml"
    [ -f "$source" ] || err "missing Alacritty overlay: $source"
    if [ "$DRY_RUN" = 1 ]; then
        say "dry-run: ln -sfn $source $target"
    else
        path_reaches_symlink "$(dirname "$target")" && err "refusing to replace Alacritty overlay through symlinked path: $target"
        if { [ -e "$target" ] || [ -L "$target" ]; } && [ "$BACKUP" != 1 ]; then
            err "existing Alacritty overlay requires backups (re-run without --no-backup)"
        fi
        overlay_backup_list="$(mktemp "$_temp_dir/alacritty-backup.XXXXXX")" || err 'failed to create Alacritty rollback record'
        if [ "$BACKUP" = 1 ]; then
            init_backup_dir
            backup_target .config/alacritty/local.toml "$overlay_backup_list"
        fi
        mkdir -p "$(dirname "$target")"
        if ! ln -s "$source" "$target"; then
            restore_backups "$overlay_backup_list"
            rm -f "$overlay_backup_list"
            err "failed to install Alacritty overlay; previous target restored"
        fi
        rm -f "$overlay_backup_list"
    fi
}
download_link_dotfiles() {
    parse_args "$@"
    select_profile

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
        if [ "$DRY_RUN" = 1 ]; then
            STOW_CMD=:
        else
            install_stow
        fi
    fi

    _temp_dir="$(ensure mktemp -d /var/tmp/dotfiles-test.install.XXXXXX)" || return 1

    _file="$_temp_dir/dotfiles$DOTFILES_EXT"
    say_verbose "Temporary dir created at: $_temp_dir"

    if [ "1" = "$LOCAL_INSTALL" ]; then
        if [ -n "${LOCAL_SOURCE:-}" ]; then
            local_source="$LOCAL_SOURCE"
        else
            local_source=$(cd "$(dirname "$0")" && pwd) || err "failed to resolve local source dir"
        fi
        install_selected_packages "$local_source"
        select_alacritty_overlay "$local_source"
        [ "$DRY_RUN" = 1 ] || verify_tools
        exit 0
    fi

    if [ "$DRY_RUN" = "1" ]; then
        if [ -d "$RECEIPT_HOME" ]; then
            install_selected_packages "$RECEIPT_HOME"
            select_alacritty_overlay "$RECEIPT_HOME"
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
            [yY][eE][sS] | [yY]) ;;
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

    install_selected_packages "$RECEIPT_HOME"
    select_alacritty_overlay "$RECEIPT_HOME"

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

install_stow() {
    say "Stow not found. Installing GNU Stow ${STOW_VERSION} from source."
    _stow_build_dir="$(mktemp -d /var/tmp/dotfiles-test.stow.XXXXXX)" || err 'failed to create Stow build directory'
    (
        cd "$_stow_build_dir" || err "failed to enter Stow build directory"
        archive="stow-${STOW_VERSION}.tar.gz"
        downloader "https://ftp.gnu.org/gnu/stow/$archive" "$archive"
        verify_sha256 "$archive" "$STOW_SHA256"
        tar xzf "$archive"
        release="stow-${STOW_VERSION}"
        [ -d "$release" ] || err 'failed to find expected extracted Stow release'
        cd "$release" || err "failed to enter stow release dir"
        mkdir -p "$HOME/.local/bin"
        ./configure --prefix "$HOME/.local"
        make
        make install
    )
    STOW_CMD="$HOME/.local/bin/stow"
    safe_remove_temp_dir "$_stow_build_dir" || err "refusing to clean unexpected Stow build directory: $_stow_build_dir"
    _stow_build_dir=""
}

verify_sha256() {
    archive="$1"
    expected="$2"
    if check_cmd sha256sum; then
        actual="$(sha256sum "$archive" | awk '{print $1}')"
    elif check_cmd shasum; then
        actual="$(shasum -a 256 "$archive" | awk '{print $1}')"
    else
        err 'need sha256sum or shasum to verify GNU Stow source'
    fi
    [ "$actual" = "$expected" ] || err "GNU Stow source checksum mismatch for $archive"
}

safe_remove_temp_dir() {
    candidate="${1:-}"
    [ -n "$candidate" ] && [ -d "$candidate" ] && [ ! -L "$candidate" ] || return 1
    resolved="$(cd "$candidate" 2>/dev/null && pwd -P)" || return 1
    case "$resolved" in
    /var/tmp/dotfiles-test.*/*) return 1 ;;
    /var/tmp/dotfiles-test.*) ;;
    *) return 1 ;;
    esac
    rm -rf -- "$resolved"
}

ensure_parent_dirs() {
    # Ensure common parent directories exist as real directories
    # to prevent stow from symlinking entire trees
    for dir in ".config" ".config/alacritty" ".local" ".local/bin" ".local/share"; do
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

link_files() {
    base_dir="$1"
    shift
    cd "$base_dir" || err "failed to enter $base_dir"
    ensure_parent_dirs
    for folder in "$@"; do
        [ -d "$folder" ] || continue
        if [ "$DRY_RUN" = "1" ]; then
            say "dry-run: $STOW_CMD -D $folder"
            "$STOW_CMD" -n -D -t "$HOME" "$STOW_IGNORE" "$folder"
            say "dry-run: $STOW_CMD $folder"
            "$STOW_CMD" -n -t "$HOME" "$STOW_IGNORE" "$folder"
            continue
        fi

        need_cmd readlink
        overwrite=0
        conflict_out="$(mktemp "$_temp_dir/stow-conflict-output.XXXXXX")"
        conflict_list="$(mktemp "$_temp_dir/stow-conflict-list.XXXXXX")"
        if ! "$STOW_CMD" -n -t "$HOME" "$STOW_IGNORE" "$folder" >"$conflict_out" 2>&1; then
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
                [yY][eE][sS] | [yY])
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

        backup_list="$(mktemp "$_temp_dir/stow-backup.XXXXXX")"
        link_list="$(mktemp "$_temp_dir/stow-links.XXXXXX")"
        snapshot_stow_links "$base_dir/$folder" "$link_list"
        backup_files "$base_dir/$folder" "$backup_list"
        if [ "$overwrite" = "1" ] && [ -s "$conflict_list" ]; then
            backup_conflicts "$conflict_list" "$backup_list"
        fi

        say_verbose "$STOW_CMD $folder"
        if ! "$STOW_CMD" -D -t "$HOME" "$STOW_IGNORE" "$folder"; then
            say "unstow failed for $folder; restoring previous links"
            restore_stow_links "$link_list" || say "unable to restore every prior Stow link for $folder"
            restore_backups "$backup_list"
            rm -f "$conflict_out" "$conflict_list" "$backup_list" "$link_list"
            err "unstow failed for $folder; changes reverted"
        fi
        if ! "$STOW_CMD" -t "$HOME" "$STOW_IGNORE" "$folder"; then
            say "stow failed for $folder; reverting changes"
            "$STOW_CMD" -D -t "$HOME" "$STOW_IGNORE" "$folder" >/dev/null 2>&1 || true
            restore_stow_links "$link_list" || say "unable to restore every prior Stow link for $folder"
            restore_backups "$backup_list"
            rm -f "$conflict_out" "$conflict_list" "$backup_list" "$link_list"
            err "stow failed for $folder; changes reverted"
        fi

        rm -f "$conflict_out" "$conflict_list" "$backup_list" "$link_list"
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
    safe_relative_path "$rel" || err "refusing unsafe backup path: $rel"
    case "$rel" in
    .cargo/* | .rustup/*)
        err "refusing to manage mutable tool state: $rel"
        ;;
    .local/share/*)
        case "$rel" in
        .local/share/man/*) ;;
        *) err "refusing to manage mutable tool state: $rel" ;;
        esac
    esac
    target="$HOME/$rel"
    if path_reaches_symlink "$(dirname "$target")"; then
        return 0
    fi
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
            echo "$rel" >>"$list_file"
        fi
    fi
}

path_reaches_symlink() {
    path="$1"
    while [ "$path" != "/" ] && [ "$path" != "$HOME" ]; do
        if [ -L "$path" ]; then
            return 0
        fi
        path="$(dirname "$path")"
    done
    return 1
}

backup_files() {
    [ "$BACKUP" = "1" ] || return 0
    pkg_dir="$1"
    list_file="${2:-}"
    [ -d "$pkg_dir" ] || return 0
    init_backup_dir

    find "$pkg_dir" \( -type f -o -type l \) -print | while IFS= read -r src; do
        rel="${src#"$pkg_dir"/}"
        target="$HOME/$rel"
        if [ -e "$target" ] || [ -L "$target" ]; then
            # A stowed parent (for example ~/.config/zshrc) can make the
            # target resolve back into the checkout. Never move source files
            # while backing up a target reached through such a symlink.
            if path_reaches_symlink "$(dirname "$target")"; then
                continue
            fi
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
    done <"$conflict_list"
}

restore_backups() {
    list_file="$1"
    [ -s "$list_file" ] || return 0
    while IFS= read -r rel; do
        [ -n "$rel" ] || continue
        safe_relative_path "$rel" || err "refusing unsafe restore path: $rel"
        backup_path="$BACKUP_DIR/$rel"
        target="$HOME/$rel"
        [ -e "$backup_path" ] || continue
        if path_reaches_symlink "$(dirname "$target")"; then
            err "refusing to restore through symlinked path: $target"
        fi
        remove_restore_target "$target" || err "refusing to replace non-empty restore target: $target"
        mkdir -p "$(dirname "$target")"
        mv "$backup_path" "$target"
    done <"$list_file"
}

safe_relative_path() {
    rel="$1"
    case "$rel" in '' | /* | *'//'*) return 1 ;; esac
    case "/$rel/" in *'/../'* | *'/./'*) return 1 ;; esac
    return 0
}

remove_restore_target() {
    target="$1"
    case "$target" in "$HOME"/*) ;; *) return 1 ;; esac
    if [ -L "$target" ]; then
        rm -f "$target"
    elif [ -d "$target" ]; then
        rmdir "$target" 2>/dev/null || return 1
    elif [ -e "$target" ]; then
        return 1
    fi
}

canonical_link_target() {
    target="$1"
    link_target="$(readlink "$target")" || return 1
    case "$link_target" in
    /*) link_path="$link_target" ;;
    *) link_path="$(cd "$(dirname "$target")/$(dirname "$link_target")" 2>/dev/null && pwd -P)/$(basename "$link_target")" ;;
    esac
    printf '%s\n' "$link_path"
}

canonical_existing_path() {
    candidate="$1"
    printf '%s/%s\n' "$(cd "$(dirname "$candidate")" 2>/dev/null && pwd -P)" "$(basename "$candidate")"
}

snapshot_stow_links() {
    pkg_dir="$1"
    list_file="$2"
    find "$pkg_dir" -mindepth 1 -print | while IFS= read -r src; do
        rel="${src#"$pkg_dir"/}"
        target="$HOME/$rel"
        [ -L "$target" ] || continue
        source_path="$(canonical_existing_path "$src")"
        target_path="$(canonical_link_target "$target" 2>/dev/null || :)"
        [ "$source_path" = "$target_path" ] || continue
        printf '%s\t%s\n' "$rel" "$src" >>"$list_file"
    done
}

restore_stow_links() {
    list_file="$1"
    [ -s "$list_file" ] || return 0
    while IFS="$(printf '\t')" read -r rel src; do
        safe_relative_path "$rel" || return 1
        target="$HOME/$rel"
        path_reaches_symlink "$(dirname "$target")" && continue
        remove_restore_target "$target" || return 1
        mkdir -p "$(dirname "$target")" || return 1
        ln -s "$src" "$target" || return 1
    done <"$list_file"
}

extract_stow_conflicts() {
    awk '
        /cannot stow/ {
            if (match($0, /existing target [^ ]+/)) {
                s = substr($0, RSTART, RLENGTH)
                sub(/^existing target /, "", s)
                seen[s] = 1
            }
        }
        /existing target is not owned by stow:/ {
            if (match($0, /stow: [^ ]+/)) {
                s = substr($0, RSTART, RLENGTH)
                sub(/^stow: /, "", s)
                seen[s] = 1
            }
        }
        END { for (k in seen) print k }
    ' "$1"
}

verify_tools() {
    status=0
    for tool in stow git curl rsync mise; do
        if check_cmd "$tool"; then
            say_verbose "ok: $tool"
        else
            say "missing: $tool (required)"
            status=1
        fi
    done

    for tool in nvim rg cargo loom; do
        if check_cmd "$tool"; then
            say_verbose "ok: $tool"
        else
            say "missing: $tool (optional)"
        fi
    done
    return "$status"
}

ensure() {
    if ! "$@"; then err "command failed: $*"; fi
}

need_cmd() {
    if ! check_cmd "$1"; then err "need '$1' (command not found)"; fi
}

check_cmd() {
    command -v "$1" >/dev/null 2>&1
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
        red=""
        reset=""
        red=$(tput setaf 1 2>/dev/null || echo '')
        reset=$(tput sgr0 2>/dev/null || echo '')
        say "${red}ERROR${reset}: $1" >&2
    fi
    exit 1
}

set_dotfiles_remote

download_link_dotfiles "$@" || exit 1
