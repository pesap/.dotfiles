#!/usr/bin/env bash
# Loom's package-apply implementation. Existing user files are never adopted.

set -Eeuo pipefail

usage() {
    cat <<'EOF'
Usage: loom apply [OPTIONS] [package ...]

Apply declared packages. With no package arguments, apply the selected
profile (common by default). A Stow dry-run is always completed before
any links are changed.

Options:
  -n, --dry-run          Preflight only; do not change links
      --profile PROFILE  Select common, linux-desktop, or macos
  -h, --help             Show this help

--adopt is intentionally unsupported: it can overwrite tracked dotfiles.
EOF
}

fail() {
    printf 'loom apply: %s\n' "$*" >&2
    exit 1
}

repo_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
manifest="$repo_dir/packages.conf"
profile="${DOTFILES_PROFILE:-common}"
dry_run=0
declare -a requested=()
declare -a packages=()
declare -a applied=()
declare -a snapshot_packages=()
declare -a snapshot_files=()

while (($#)); do
    case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    -n | --dry-run) dry_run=1 ;;
    --profile)
        (($# >= 2)) || fail '--profile requires a value'
        profile="$2"
        shift
        ;;
    --profile=*) profile="${1#--profile=}" ;;
    --adopt) fail '--adopt is refused; it could overwrite tracked dotfiles' ;;
    --)
        shift
        requested+=("$@")
        break
        ;;
    -*) fail "unknown option: $1" ;;
    *) requested+=("$1") ;;
    esac
    shift
done

[[ -d "$repo_dir" && ! -L "$repo_dir" ]] || fail "dotfiles directory is not a real directory: $repo_dir"
[[ -f "$manifest" ]] || fail "missing package manifest: $manifest"
command -v stow >/dev/null 2>&1 || fail 'stow is required'
command -v readlink >/dev/null 2>&1 || fail 'readlink is required for rollback'

case "$profile" in
common) ;;
linux-desktop) [[ "$(uname -s)" == Linux ]] || fail 'linux-desktop profile requires Linux' ;;
macos) [[ "$(uname -s)" == Darwin ]] || fail 'macos profile requires macOS' ;;
*) fail "unknown profile: $profile" ;;
esac

profile_packages() {
    awk -v profile="$profile" '
        /^[[:space:]]*#/ || NF == 0 { next }
        $1 == profile { $1 = ""; sub(/^[[:space:]]+/, ""); print; found = 1; exit }
        END { if (!found) exit 1 }
    ' "$manifest"
}

all_declared_packages() {
    awk '
        /^[[:space:]]*#/ || NF == 0 { next }
        { for (i = 2; i <= NF; i++) print $i }
    ' "$manifest" | sort -u
}

safe_package_name() {
    [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]]
}

is_declared_package() {
    local candidate="$1"
    all_declared_packages | grep -Fqx -- "$candidate"
}

if ((${#requested[@]} == 0)); then
    profile_line="$(profile_packages)" || fail "unknown profile: $profile"
    read -r -a packages <<<"$profile_line"
else
    packages=("${requested[@]}")
fi
((${#packages[@]} > 0)) || fail "profile '$profile' has no packages"

for package in "${packages[@]}"; do
    safe_package_name "$package" || fail "unsafe package name: $package"
    is_declared_package "$package" || fail "package is not declared in packages.conf: $package"
    [[ -d "$repo_dir/$package" && ! -L "$repo_dir/$package" ]] || fail "package not found: $package"
    if [[ "$package" != man ]] && { [[ -d "$repo_dir/$package/.local/share" ]] || [[ -d "$repo_dir/$package/.cargo" ]] || [[ -d "$repo_dir/$package/.rustup" ]]; }; then
        fail "refusing mutable runtime-state package: $package"
    fi
done

cd "$repo_dir"
stow_opts=(--ignore='\.DS_Store|local.toml' -t "$HOME")

for package in "${packages[@]}"; do
    printf 'Preflight: %s\n' "$package"
    stow -n -R "${stow_opts[@]}" "$package"
done

if ((dry_run)); then
    printf 'Dry run complete; no links changed.\n'
    exit 0
fi

canonical_existing_path() {
    local candidate="$1"
    printf '%s/%s\n' "$(cd "$(dirname "$candidate")" && pwd -P)" "$(basename "$candidate")"
}

canonical_link_target() {
    local target="$1" link_target link_path
    link_target="$(readlink "$target")" || return 1
    if [[ "$link_target" = /* ]]; then
        link_path="$link_target"
    else
        link_path="$(cd "$(dirname "$target")/$(dirname "$link_target")" 2>/dev/null && pwd -P)/$(basename "$link_target")"
    fi
    printf '%s\n' "$link_path"
}

snapshot_package_links() {
    local package="$1" snapshot="$2" src rel target source_path target_path
    while IFS= read -r src; do
        rel="${src#"$repo_dir/$package/"}"
        target="$HOME/$rel"
        [[ -L "$target" ]] || continue
        source_path="$(canonical_existing_path "$src")"
        target_path="$(canonical_link_target "$target" 2>/dev/null || true)"
        [[ "$source_path" = "$target_path" ]] || continue
        printf '%s\t%s\n' "$rel" "$src" >>"$snapshot"
    done < <(find "$repo_dir/$package" -mindepth 1 -print)
}

safe_relative_path() {
    local rel="$1"
    [[ -n "$rel" && "$rel" != /* && "$rel" != *'//' && "/$rel/" != *'/../'* && "/$rel/" != *'/./'* ]]
}

remove_managed_target() {
    local target="$1"
    [[ "$target" == "$HOME"/* ]] || return 1
    if [[ -L "$target" ]]; then
        rm -f -- "$target"
    elif [[ -d "$target" ]]; then
        rmdir -- "$target" 2>/dev/null || return 1
    elif [[ -e "$target" ]]; then
        return 1
    fi
}

snapshot_for_package() {
    local package="$1"
    local index=0
    while ((index < ${#snapshot_packages[@]})); do
        if [[ "${snapshot_packages[$index]}" = "$package" ]]; then
            printf '%s\n' "${snapshot_files[$index]}"
            return 0
        fi
        index=$((index + 1))
    done
    return 1
}

restore_snapshot() {
    local package="$1"
    local snapshot
    local rel src target
    snapshot="$(snapshot_for_package "$package")" || return 1
    stow -D "${stow_opts[@]}" "$package" >/dev/null 2>&1 || true
    [[ -s "$snapshot" ]] || return 0
    while IFS=$'\t' read -r rel src; do
        safe_relative_path "$rel" || return 1
        target="$HOME/$rel"
        if [[ -L "$target" ]] && [[ "$(canonical_link_target "$target" 2>/dev/null || true)" == "$(canonical_existing_path "$src")" ]]; then
            continue
        fi
        remove_managed_target "$target" || return 1
        mkdir -p -- "$(dirname "$target")" || return 1
        ln -s -- "$src" "$target" || return 1
    done <"$snapshot"
}

cleanup() {
    local snapshot
    for snapshot in "${snapshot_files[@]:-}"; do
        [[ -n "$snapshot" && -f "$snapshot" ]] && rm -f -- "$snapshot"
    done
}
trap cleanup EXIT

for current_package in "${packages[@]}"; do
    snapshot_file="$(mktemp /var/tmp/dotfiles-test.restow.XXXXXX)" ||
        fail 'failed to create rollback record'
    snapshot_packages+=("$current_package")
    snapshot_files+=("$snapshot_file")
    snapshot_package_links "$current_package" "$snapshot_file"
    printf 'Applying: %s\n' "$current_package"
    if ! stow -R "${stow_opts[@]}" "$current_package"; then
        printf 'Apply failed for %s; restoring the prior link state.\n' "$current_package" >&2
        restore_snapshot "$current_package" ||
            fail "could not restore prior links for $current_package"
        for applied_package in "${applied[@]}"; do
            restore_snapshot "$applied_package" ||
                fail "could not restore prior links for $applied_package"
        done
        fail 'apply failed; prior package links restored'
    fi
    applied+=("$current_package")
done

printf 'Done.\n'
