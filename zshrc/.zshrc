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
if [ -f /etc/profile ]; then
    PATH=""
    source /etc/profile
fi

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
    git
    gitfast
    pip
    python
    tmux
    vi-mode
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Remove theme from ZSH
ZSH_THEME=""

# Load Oh-My-Zsh
source $ZSH/oh-my-zsh.sh

# Load personal customization alias and functions
source ~/.aliases_unix
source ~/.aliases_macOS
source ~/.locals/scripts/functions
source ~/.private


VIM="nvim"

#================================================================================
# ENVS
#
# This section is for environment variables. Add or delete as needed.
#
#================================================================================
export MPLCONFIGDIR="$HOME/.config/matplotlib"                                                  # Matplotlib configuration file
export PYTHONDONTWRITEBYTECODE=1                                                                # Avoid duplicate python virtualenv
export TERM='xterm-256color'                                                                    # Use fuil color terminal
export EDITOR='nvim'                                                                            # Use fuil color terminal
export PATH="$HOME/.locals/scripts/:$HOME/.locals/bin:$PATH"                                    # My custom scripts
export PATH="$HOME/.cargo/bin/:$PATH"                                                           # rust
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --no-ignore-vcs --column --smart-case' # Defaults for fzf



# Select default editor
[ -z "$EDITOR" ] &&  export EDITOR="vim"

#================================================================================
# Custom programs
#
# This section is for custom programs, or other configuration,
# in this part. Include a comment at the end with the explanation.
#
#================================================================================



eval "$(/opt/homebrew/bin/brew shellenv)"

# Prompt configuration
which starship &> /dev/null && eval "$(starship init zsh)"
. "$HOME/.cargo/env"

# Zoxide
which zoxide &> /dev/null && eval "$(zoxide init zsh)"

# !! Contents within this block are managed by juliaup !!

path=('/Users/psanchez/.juliaup/bin' $path)
export PATH

# <<< juliaup initialize <<<

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/psanchez/.locals/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/psanchez/.locals/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/Users/psanchez/.locals/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/psanchez/.locals/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup

if [ -f "/Users/psanchez/.locals/miniforge3/etc/profile.d/mamba.sh" ]; then
    . "/Users/psanchez/.locals/miniforge3/etc/profile.d/mamba.sh"
fi
# <<< conda initialize <<<
export PATH=/Users/psanchez/.pixi/bin:$PATH
eval "$(pixi completion --shell zsh)"
