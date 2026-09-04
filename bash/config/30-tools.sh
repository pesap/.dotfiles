# shellcheck shell=bash
# mise is the source of truth for managed command-line tools.
if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
fi

# Worktrunk shell integration handles explicit --cd switches and execution.
if command -v wt >/dev/null 2>&1; then
    eval "$(wt config shell init bash)"
fi
