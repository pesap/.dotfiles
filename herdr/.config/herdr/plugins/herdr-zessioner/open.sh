#!/usr/bin/env bash
set -euo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"
plugin_id="${HERDR_PLUGIN_ID:?HERDR_PLUGIN_ID is required}"

# The action is intentionally idempotent. A stale second invocation should
# close every existing Zessioner pane instead of stacking another overlay.
existing_panes=$(
  "$herdr_bin" api snapshot 2>/dev/null \
    | jq -r '.result.snapshot.panes[]? | select(.label == "Herdr Zessioner") | .pane_id' \
    || true
)

if [[ -n "$existing_panes" ]]; then
  while IFS= read -r pane_id; do
    [[ -n "$pane_id" ]] || continue
    "$herdr_bin" plugin pane close "$pane_id" >/dev/null 2>&1 || true
  done <<< "$existing_panes"
  exit 0
fi

exec "$herdr_bin" plugin pane open \
  --plugin "$plugin_id" \
  --entrypoint picker \
  --placement overlay \
  --focus
