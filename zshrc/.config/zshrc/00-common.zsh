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

# Add Homebrew to PATH early (macOS)
if [[ -d /opt/homebrew/bin ]]; then
    path=(/opt/homebrew/bin $path)
fi
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
[[ -f ~/.local/scripts/git-functions ]] && source ~/.local/scripts/git-functions
[[ -f ~/.private ]] && source ~/.private

VIM="nvim"
alias v='nvim'

# Common aliases (both macOS and Linux)
[[ -f ~/.aliases_unix ]] && source ~/.aliases_unix

# Zellij layout aliases
alias zrust='zellij --layout rust'
alias zpy='zellij --layout py'
alias zrepl='zellij --layout repl'

# Zellij session picker (override simple alias from .aliases_unix)
unalias zel 2>/dev/null
zel() {
    local sessions layout_dir layouts selection
    layout_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/layouts"

    local fzf_opts=(
        --height=50%
        --layout=reverse
        --border=rounded
        --margin=1,2
        --padding=1
        --pointer="▶"
        --marker="●"
        --color="border:#7aa2f7,pointer:#f7768e,marker:#9ece6a,header:#e0af68"
    )

    # Get existing sessions
    sessions=$(zellij list-sessions -s 2>/dev/null)

    # Build selection menu: existing sessions + new session option
    if [[ -n "$sessions" ]]; then
        selection=$(printf "%s\n+ New Session" "$sessions" | fzf "${fzf_opts[@]}" \
            --prompt="  Session  " \
            --header="Select or create a Zellij session")
    else
        selection="+ New Session"
    fi

    [[ -z "$selection" ]] && return 0

    if [[ "$selection" == "+ New Session" ]]; then
        # Get available layouts
        layouts=$(find "$layout_dir" -name "*.kdl" -exec basename {} .kdl \; 2>/dev/null | grep -v '\.bak$' | sort)
        if [[ -z "$layouts" ]]; then
            zellij
            return
        fi

        local layout=$(echo "$layouts" | fzf "${fzf_opts[@]}" \
            --prompt="  Layout  " \
            --header="Choose a layout for new session")
        [[ -z "$layout" ]] && return 0

        zellij --layout "$layout"
    else
        zellij attach "$selection"
    fi
}
