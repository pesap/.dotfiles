# shellcheck shell=bash
# mise is the source of truth for managed command-line tools.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi

# Worktrunk needs shell integration to change the parent shell directory.
if command -v wt >/dev/null 2>&1; then
    eval "$(wt config shell init bash)"
fi
