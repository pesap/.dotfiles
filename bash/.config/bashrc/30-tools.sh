# shellcheck shell=bash
# mise is the source of truth for managed command-line tools.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi
