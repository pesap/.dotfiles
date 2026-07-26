#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)
switcher="$repo_root/waybar/.config/waybar/theme-switcher"
test_dir=$(mktemp -d /var/tmp/dotfiles-test.waybar-theme.XXXXXX)
cleanup() {
    case "$test_dir" in
    /var/tmp/dotfiles-test.waybar-theme.??????) ;;
    *) return 1 ;;
    esac
    [[ -d "$test_dir" && ! -L "$test_dir" ]] || return 1
    rm -rf -- "$test_dir"
}
trap cleanup EXIT

mkdir -p "$test_dir/config/themes/good" "$test_dir/runtime"
printf '{"layer":"top"}\n' >"$test_dir/config/themes/good/config"
printf '* { color: white; }\n' >"$test_dir/config/themes/good/style.css"
printf '# theme\tprovenance\tmango_support\n*\tfixture\tmango-adapted\n' >"$test_dir/config/themes/manifest.tsv"
printf 'tracked config\n' >"$test_dir/config/config.jsonc"
printf 'tracked style\n' >"$test_dir/config/style.css"

env WAYBAR_CONFIG_DIR="$test_dir/config" WAYBAR_RUNTIME_DIR="$test_dir/runtime" WAYBAR_RESTART=0 \
    "$switcher" good
cmp "$test_dir/config/themes/good/config" "$test_dir/runtime/config.jsonc"
cmp "$test_dir/config/themes/good/style.css" "$test_dir/runtime/style.css"
grep -Fqx 'mango-adapted' "$test_dir/runtime/.mango-support"
[[ $(<"$test_dir/config/config.jsonc") == 'tracked config' ]]
[[ $(<"$test_dir/config/style.css") == 'tracked style' ]]

if env WAYBAR_CONFIG_DIR="$test_dir/config" WAYBAR_RUNTIME_DIR="$test_dir/runtime" WAYBAR_RESTART=0 \
    "$switcher" ../good; then
    printf 'path-like theme name unexpectedly succeeded\n' >&2
    exit 1
fi

rm -f -- "$test_dir/config/themes/good/style.css"
if env WAYBAR_CONFIG_DIR="$test_dir/config" WAYBAR_RUNTIME_DIR="$test_dir/runtime" WAYBAR_RESTART=0 \
    "$switcher" good; then
    printf 'missing style unexpectedly succeeded\n' >&2
    exit 1
fi
printf 'theme-switcher tests passed\n'
