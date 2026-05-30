#================================================================================
# Login-only initialization
#================================================================================
if [[ -r /etc/profile ]]; then
    source /etc/profile
fi

if command -v brew >/dev/null; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Ensure PATH is initialized for non-interactive login shells (eg `ssh host cmd`).
# Interactive shells will re-source this via .zshrc, so skip the duplicate work.
if [[ ! -o interactive ]]; then
    [[ -f ~/.config/zshrc/00-path.zsh ]] && source ~/.config/zshrc/00-path.zsh
fi
