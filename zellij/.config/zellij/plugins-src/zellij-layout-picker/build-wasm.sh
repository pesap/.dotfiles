#!/usr/bin/env bash
set -Eeuo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
artifact="$script_dir/../../plugins/zellij-layout-picker.wasm"
target="wasm32-wasip1"
mode="build"
created_target_dir=0

fail() {
    printf 'zellij-layout-picker: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    local status=$?
    trap - EXIT HUP INT TERM
    if [[ "$created_target_dir" == "1" ]]; then
        local resolved_target_dir=""
        resolved_target_dir=$(realpath "$target_dir")
        if [[ -d "$resolved_target_dir" && ! -L "$resolved_target_dir" &&
            "$resolved_target_dir" == /var/tmp/dotfiles-test.zellij-layout-picker.* ]]; then
            rm -rf -- "$resolved_target_dir"
        else
            printf 'zellij-layout-picker: refusing to clean unexpected target directory: %s\n' "$resolved_target_dir" >&2
            status=1
        fi
    fi
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

if [[ "${1:-}" == "--check" ]]; then
    mode="check"
elif [[ $# -ne 0 ]]; then
    printf 'usage: %s [--check]\n' "${0##*/}" >&2
    exit 2
fi

command -v cargo >/dev/null 2>&1 || fail 'cargo is required'
command -v rustc >/dev/null 2>&1 || fail 'rustc is required'
grep -Fqx 'host_version = "0.44.3"' "$script_dir/plugin-version.toml" ||
    fail 'plugin-version.toml must pin Zellij host 0.44.3'
grep -Fqx 'crate_version = "0.44.3"' "$script_dir/plugin-version.toml" ||
    fail 'plugin-version.toml must pin zellij-tile 0.44.3'
grep -Fqx 'target = "wasm32-wasip1"' "$script_dir/plugin-version.toml" ||
    fail 'plugin-version.toml must pin wasm32-wasip1'
grep -Fqx 'zellij-tile = "=0.44.3"' "$script_dir/Cargo.toml" ||
    fail 'Cargo.toml must pin zellij-tile 0.44.3'
grep -A1 -F 'name = "zellij-tile"' "$script_dir/Cargo.lock" |
    grep -Fqx 'version = "0.44.3"' ||
    fail 'Cargo.lock does not resolve zellij-tile 0.44.3'

target_libdir=$(rustc --print target-libdir --target "$target")
compgen -G "$target_libdir/libcore-*.rlib" >/dev/null ||
    fail "Rust target $target is unavailable; run: rustup target add $target"

if [[ -n "${CARGO_TARGET_DIR:-}" ]]; then
    target_dir=$CARGO_TARGET_DIR
else
    target_dir=$(mktemp -d /var/tmp/dotfiles-test.zellij-layout-picker.XXXXXX)
    created_target_dir=1
fi

mkdir -p -- "$target_dir"
cargo build --locked --release --target "$target" --target-dir "$target_dir" --manifest-path "$script_dir/Cargo.toml"
built_artifact="$target_dir/$target/release/zellij-layout-picker.wasm"

if [[ ! -f "$built_artifact" ]]; then
    fail "build did not produce $built_artifact"
fi

if [[ "$mode" == "check" ]]; then
    cmp -- "$built_artifact" "$artifact"
    printf 'zellij-layout-picker: checked-in WASM matches zellij-tile 0.44.3\n'
else
    install -m 0644 -- "$built_artifact" "$artifact"
    printf 'zellij-layout-picker: wrote %s\n' "$artifact"
fi
