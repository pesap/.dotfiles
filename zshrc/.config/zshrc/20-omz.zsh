# Oh-My-Zsh configuration

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
    # git
    gh
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"
