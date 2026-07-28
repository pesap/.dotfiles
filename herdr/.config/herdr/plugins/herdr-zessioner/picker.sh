#!/usr/bin/env bash
set -euo pipefail

picker_bin="${ZESSIONER_BIN:-$HOME/.local/bin/zessioner}"
adapter="${HERDR_PLUGIN_ROOT:?HERDR_PLUGIN_ROOT is required}/backend.sh"

if [[ ! -x "$picker_bin" ]]; then
  picker_bin=$(command -v zessioner 2>/dev/null || true)
fi
[[ -x "$picker_bin" ]] || {
  printf 'herdr-zessioner: zessioner is not installed\n' >&2
  exit 1
}
roots="${HERDR_PROJECT_ROOTS:-${ZESSION_ROOTS:-$HOME/dev:$HOME/sandbox:$HOME/work:$HOME/.dotfiles}}"

exec "$picker_bin" \
  --adapter "$adapter" \
  --roots "$roots" \
  --prompt 'workspace › ' \
  --title 'workspace picker' \
  --header $'enter focus/create  ·  ctrl-r refresh  ·  ctrl-d close  ·  ctrl-/ details  ·  esc close'
