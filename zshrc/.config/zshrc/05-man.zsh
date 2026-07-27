# User-installed man pages from the dotfiles package.
if [[ -d "$HOME/.local/share/man" ]]; then
    if [[ -n "${MANPATH:-}" ]]; then
        export MANPATH="$HOME/.local/share/man:$MANPATH"
    else
        export MANPATH="$HOME/.local/share/man:"
    fi
fi
