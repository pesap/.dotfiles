#!/usr/bin/env bash
# Herdr adapter for project-picker.
set -uo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"

usage() {
  cat <<'EOF'
Usage: backend.sh --rows|--select KIND ID PATH NAME|--close ID NAME
EOF
}

snapshot_json() {
  "$herdr_bin" api snapshot 2>/dev/null
}

rows() {
  snapshot_json | jq -r '
    .result.snapshot as $snapshot
    | $snapshot.workspaces[] as $workspace
    | ($snapshot.panes
       | map(select(.workspace_id == $workspace.workspace_id))
       | map(.foreground_cwd // .cwd // empty)
       | map(select(length > 0))
       | .[0] // "") as $path
    | ($workspace.label // "workspace") as $label
    | ["herdr", $workspace.workspace_id, $path, $label,
       (if $workspace.focused then "current" else "active" end),
       (if $workspace.focused then "0" else "1" end),
       ($label | ascii_downcase)]
    | @tsv'
}

select_row() {
  local kind="${1:-}" id="${2:-}" path="${3:-}" name="${4:-}"
  case "$kind" in
    herdr)
      [[ -n "$id" ]] || return 1
      "$herdr_bin" workspace focus "$id" >/dev/null
      ;;
    project)
      [[ -d "$path" && -n "$name" ]] || return 1
      "$herdr_bin" workspace create --cwd "$path" --label "$name" --focus >/dev/null
      ;;
    *)
      printf 'herdr workspace picker: unsupported row kind: %s\n' "$kind" >&2
      return 1
      ;;
  esac
}

close_row() {
  local id="${1:-}"
  [[ -n "$id" ]] || return 1
  "$herdr_bin" workspace close "$id" >/dev/null
}

case "${1:-}" in
  --rows) rows ;;
  --select) select_row "${2:-}" "${3:-}" "${4:-}" "${5:-}" ;;
  --close) close_row "${2:-}" "${3:-}" ;;
  --help|-h) usage ;;
  *) usage >&2; exit 2 ;;
esac
