# Oh-My-Zsh configuration
#
# Speed-ups via https://scottspence.com/posts/speeding-up-my-zsh-shell
# (+ https://gist.github.com/ctechols/ca1035271ad134841284 for compinit cache)

# Tell OMZ to skip the slow stuff
DISABLE_AUTO_UPDATE="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_COMPFIX="true"

# Daily-cached compinit: rebuild the dump at most once per day, otherwise -C.
# Runs BEFORE sourcing OMZ; OMZ will still call compinit, but the dump is fresh.
autoload -Uz compinit
if [[ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]]; then
    compinit
else
    compinit -C
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
    gh
    fzf
    zsh-autosuggestions
    zsh-syntax-highlighting   # must be last
)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# zsh-autosuggestions perf tweaks
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1
