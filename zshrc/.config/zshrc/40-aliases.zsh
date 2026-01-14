# Aliases

# Editor
alias v='nvim'
alias vim='nvim'

# Zellij layouts
alias zrust='zellij --layout rust'
alias zpy='zellij --layout py'
alias zrepl='zellij --layout repl'

# Source personal aliases (from personal/ submodule)
[[ -f ~/.aliases_unix ]] && source ~/.aliases_unix

# Private/sensitive aliases
[[ -f ~/.private ]] && source ~/.private
