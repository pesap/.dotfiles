# Common shell config for macOS + Linux.

# Basic PATH setup; keep duplicates out.
typeset -U path
path=(
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    $path
)
export PATH

export PYTHONDONTWRITEBYTECODE=1
export TERM='xterm-256color'
export EDITOR='nvim'
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --no-ignore-vcs'

# Oh-My-Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(
    gitfast
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Load Oh-My-Zsh
if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# Prompt configuration
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
fi

if command -v lsd >/dev/null; then
    alias ls='lsd'
    alias l='ls -l'
    alias la='ls -a'
    alias lla='ls -la'
    alias lt='ls --tree'
fi

# Tooling hooks
if [[ -f "$HOME/.cargo/env" ]]; then
    . "$HOME/.cargo/env"
fi

if command -v direnv >/dev/null; then
    eval "$(direnv hook zsh)"
fi

if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
fi

# Local helpers
[[ -f ~/.local/scripts/functions ]] && source ~/.local/scripts/functions
[[ -f ~/.private ]] && source ~/.private

VIM="nvim"
