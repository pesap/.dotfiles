#!/bin/sh
set -eu
if ! command -v mise >/dev/null 2>&1; then
    printf '%s\n' 'ERROR: mise is required; install it, then run: mise install' >&2
    exit 1
fi
exec mise install "$@"
