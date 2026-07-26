#!/usr/bin/env bash
set -Eeuo pipefail

config_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
plugin_dir="$config_dir/plugins-src/zellij-layout-picker"
zellij_bin="${ZELLIJ_BIN:-zellij}"
expected_version="0.44.3"

actual_version=$("$zellij_bin" --version | awk '{print $2}')
if [[ "$actual_version" != "$expected_version" ]]; then
    printf 'zellij config requires %s; selected binary is %s\n' "$expected_version" "${actual_version:-unknown}" >&2
    exit 1
fi

"$zellij_bin" --config "$config_dir/config.kdl" --config-dir "$config_dir" setup --check
"$plugin_dir/build-wasm.sh" --check
