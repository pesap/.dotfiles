# Aliases

# Editor
alias v='nvim'
alias vim='nvim'

# Zellij layouts
alias zrust='zellij --layout rust'
alias zpy='zellij --layout py'
alias zrepl='zellij --layout repl'

# Source personal aliases (from personal/ submodule)
if [[ -f ~/.aliases_unix ]]; then
    source ~/.aliases_unix
elif [[ -f ~/.dotfiles/personal/.aliases_unix ]]; then
    source ~/.dotfiles/personal/.aliases_unix
fi

# Private/sensitive aliases
[[ -f ~/.private ]] && source ~/.private
