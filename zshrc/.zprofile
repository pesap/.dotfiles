#================================================================================
# Login-only initialization
#================================================================================
if [[ -r /etc/profile ]]; then
    source /etc/profile
fi

if command -v brew >/dev/null; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Ensure PATH is initialized for login shells too, not just interactive shells.
[[ -f ~/.config/zshrc/00-path.zsh ]] && source ~/.config/zshrc/00-path.zsh
