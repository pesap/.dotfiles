#!/usr/bin/env bash
set -euo pipefail

# Validation must never let a mise shim install a missing tool as a side effect.
export MISE_AUTO_INSTALL=0
export MISE_EXEC_AUTO_INSTALL=0
export MISE_NOT_FOUND_AUTO_INSTALL=0
export MISE_TASK_RUN_AUTO_INSTALL=0

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
validation_temp_dir=''

log() {
    printf 'validate: %s\n' "$*"
}

fail() {
    printf 'validate: error: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    local status=$?
    trap - EXIT HUP INT TERM
    if [[ -n "$validation_temp_dir" ]]; then
        local cleanup_status=0 logical_temp_dir='' resolved_temp_dir=''
        logical_temp_dir="$(cd "$validation_temp_dir" 2>/dev/null && pwd -L)" || logical_temp_dir=''
        resolved_temp_dir="$(realpath "$validation_temp_dir")"
        case "$logical_temp_dir" in
        /var/tmp/dotfiles-test.validate.*/*) cleanup_status=1 ;;
        /var/tmp/dotfiles-test.validate.*)
            case "$resolved_temp_dir" in
            /var/tmp/dotfiles-test.validate.*/* | /private/var/tmp/dotfiles-test.validate.*/*) cleanup_status=1 ;;
            /var/tmp/dotfiles-test.validate.* | /private/var/tmp/dotfiles-test.validate.*)
                if [[ -d "$validation_temp_dir" && ! -L "$validation_temp_dir" ]]; then
                    rm -rf -- "$logical_temp_dir"
                else
                    printf 'validate: refusing to clean invalid path: %s\n' "$validation_temp_dir" >&2
                    cleanup_status=1
                fi
                ;;
            *) cleanup_status=1 ;;
            esac
            ;;
        *) cleanup_status=1 ;;
        esac
        if ((cleanup_status)); then
            printf 'validate: refusing to clean unexpected path: %s\n' "$resolved_temp_dir" >&2
            status=1
        fi
    fi
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

need_command() {
    command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

validate_shell_syntax() {
    local file=''
    local first_line=''

    while IFS= read -r -d '' file; do
        IFS= read -r first_line <"$file" || true
        case "$first_line" in
        '#!/bin/sh'* | '#!/usr/bin/env sh'*) sh -n "$file" ;;
        '#!/bin/bash'* | '#!/usr/bin/env bash'*) bash -n "$file" ;;
        '#!/bin/zsh'* | '#!/usr/bin/env zsh'*) zsh -n "$file" ;;
        esac
    done < <(
        find "$repo_root" \
            -path "$repo_root/.git" -prune -o \
            -path "$repo_root/personal" -prune -o \
            -type f -print0
    )

    while IFS= read -r -d '' file; do
        zsh -n "$file"
    done < <(find "$repo_root/zshrc" -type f \( -name '*.zsh' -o -name '.zshrc' -o -name '.zprofile' -o -name '.zshenv' \) -print0)
}

validate_json() {
    local file=''
    while IFS= read -r -d '' file; do
        jq empty "$file"
    done < <(
        find "$repo_root" \
            -path "$repo_root/.git" -prune -o \
            -path "$repo_root/personal" -prune -o \
            -type f -name '*.json' -print0
    )
}

validate_waybar_config() {
    jq empty "$repo_root/waybar/.config/waybar/config.jsonc"
}

validate_toml() {
    python3 - "$repo_root" <<'PY'
from pathlib import Path
import sys
import tomllib

root = Path(sys.argv[1])
for path in sorted(root.rglob("*.toml")):
    if ".git" in path.parts or "personal" in path.parts:
        continue
    with path.open("rb") as stream:
        tomllib.load(stream)
PY
}

validate_neovim_lua() {
    local file=''
    while IFS= read -r -d '' file; do
        XDG_CACHE_HOME="$validation_temp_dir/cache" \
            XDG_DATA_HOME="$validation_temp_dir/data" \
            XDG_STATE_HOME="$validation_temp_dir/state" \
            nvim --clean --headless -u NONE -i NONE \
            "+lua assert(loadfile([[$file]]))" +qa
    done < <(find "$repo_root/nvim/.config/nvim" -type f -name '*.lua' -print0)
}

# Markdown key names contain literal backticks, not command substitutions.
# shellcheck disable=SC2016
validate_keymap_docs() {
    local keymaps="$repo_root/KEYMAPS.md"
    grep -Fqx -- '- `<leader>gd` LSP definition' "$keymaps"
    grep -Fqx -- '- `<leader>gD` `:Gdiff`' "$keymaps"
    grep -Fqx -- '| `s` | toggle active sync + Normal mode |' "$keymaps"
    if grep -Eq 'layouts/(dev|pi|vibe)\.kdl|toggle active sync removed|open floating `zsh` pane' "$keymaps"; then
        fail 'KEYMAPS.md contains stale Zellij documentation'
    fi
}

validate_zellij() {
    local zellij_bin="${ZELLIJ_BIN:-}"
    if [[ -z "$zellij_bin" ]]; then
        zellij_bin="$(command -v zellij || true)"
    fi
    [[ -n "$zellij_bin" ]] || fail 'zellij is required (or set ZELLIJ_BIN)'

    local actual_version=''
    actual_version="$("$zellij_bin" --version)"
    [[ "$actual_version" == 'zellij 0.44.3' ]] ||
        fail "expected zellij 0.44.3, found: $actual_version; run mise install or set ZELLIJ_BIN"

    ZELLIJ_BIN="$zellij_bin" "$repo_root/zellij/.config/zellij/check-0.44.3.sh"
}

run_regression_tests() {
    local test_script=''
    [[ -d "$repo_root/tests" ]] || return 0
    while IFS= read -r -d '' test_script; do
        bash "$test_script"
    done < <(
        find "$repo_root" \
            -path "$repo_root/.git" -prune -o \
            -path "$repo_root/personal" -prune -o \
            -type f -path '*/tests/*' \( -name 'test_*.sh' -o -name '*-test.sh' \) -print0
    )
}

need_command git
need_command bash
need_command zsh
need_command jq
need_command python3
need_command nvim
need_command realpath

validation_temp_dir="$(mktemp -d /var/tmp/dotfiles-test.validate.XXXXXX)"

log 'shell syntax'
validate_shell_syntax
log 'JSON'
validate_json
log 'Waybar config'
validate_waybar_config
log 'TOML'
validate_toml
log 'Neovim Lua'
validate_neovim_lua
log 'keymap documentation'
validate_keymap_docs

if command -v mango >/dev/null 2>&1; then
    log 'Mango'
    mango -p -c "$repo_root/mango/.config/mango/config.conf"
fi

log 'Zellij'
validate_zellij
log 'regression tests'
run_regression_tests
log 'git whitespace'
git -C "$repo_root" diff --check
log 'all checks passed'
