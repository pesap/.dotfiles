# Environment variables

HISTSIZE=1000
SAVEHIST=2000
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"

setopt HIST_IGNORE_SPACE
IGNOREEOF=1  # Require 2 Ctrl+D presses to exit shell (prevents accidental exit)
setopt HIST_IGNORE_DUPS
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

zstyle ':completion:*' matcher-list \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

export PYTHONDONTWRITEBYTECODE=1
export TERM='xterm-256color'
export EDITOR='nvim'
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --no-ignore-vcs'

# Bun completions
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
