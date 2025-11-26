#================================================================================
# My .zshrc config file
#
# Written by pesap
#
# Last update: 2023-10-15
#
# This is my personal zshrc configuration. Use at your own risk!
#
#================================================================================
#================================================================================
# PATH
#
# This section is for PATH configuration. If more executables are needed they go
# in this section.
#
#================================================================================
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:$PATH"

# Specify ZSH location from oh-my-zsh
export ZSH=$HOME/.oh-my-zsh

# Plugins from ZSH
plugins=(
    gitfast
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Remove theme from ZSH
ZSH_THEME=""

# Load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

#================================================================================
# ENVS
#
# This section is for environment variables. Add or delete as needed.
#
#================================================================================
export PYTHONDONTWRITEBYTECODE=1                                                                # Avoid duplicate python virtualenv
export TERM='xterm-256color'                                                                    # Use fuil color terminal
export EDITOR='nvim'                                                                            # Use fuil color terminal
export PATH="$HOME/.locals/scripts/functions:$PATH"                                             # My custom scripts
export PATH="$HOME/.local/bin:$PATH"                                                            # My custom scripts
export PATH="$HOME/.cargo/bin/:$PATH"                                                           # rust
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --no-ignore-vcs --column --smart-case' # Defaults for fzf



# Select default editor
[ -z "$EDITOR" ] &&  export EDITOR="nvim"
#================================================================================
# Custom programs
#
# This section is for custom programs, or other configuration,
# in this part. Include a comment at the end with the explanation.
#
#================================================================================



# Prompt configuration
if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
fi

if [[ -f "$HOME/.cargo/env" ]]; then
    . "$HOME/.cargo/env"
fi

if command -v direnv >/dev/null; then
    eval "$(direnv hook zsh)"
fi

# Zoxide
if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
fi

path=('/Users/psanchez/.juliaup/bin' $path)
export PATH

# Load personal customization alias and functions
[[ -f ~/.aliases_unix ]] && source ~/.aliases_unix
[[ -f ~/.aliases_macOS ]] && source ~/.aliases_macOS
[[ -f ~/.locals/scripts/functions ]] && source ~/.locals/scripts/functions
[[ -f ~/.private ]] && source ~/.private


VIM="nvim"
