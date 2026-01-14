# Environment variables

export PYTHONDONTWRITEBYTECODE=1
export TERM='xterm-256color'
export EDITOR='nvim'
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --no-ignore-vcs'

# Bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
