# shellcheck shell=bash
# Bash login startup. The interactive configuration lives in .bashrc.

if [[ -r "$HOME/.bashrc" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.bashrc"
fi
