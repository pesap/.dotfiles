# Shell functions

#=============================================================================
# Zellij Functions
#=============================================================================

# Session picker with layout selection (primary ze command)
ze() {
    local sessions layout_dir layouts selection
    layout_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zellij/layouts"

    local fzf_opts=(
        --height=50%
        --layout=reverse
        --border=rounded
        --margin=1,2
        --padding=1
        --pointer=">"
        --marker="*"
        --color="border:#7aa2f7,pointer:#f7768e,marker:#9ece6a,header:#e0af68"
    )

    sessions=$(zellij list-sessions -s 2>/dev/null)

    if [[ -n "$sessions" ]]; then
        selection=$(printf "%s\n+ New Session" "$sessions" | fzf "${fzf_opts[@]}" \
            --prompt="  Session  " \
            --header="Select or create a Zellij session")
    else
        selection="+ New Session"
    fi

    [[ -z "$selection" ]] && return 0

    if [[ "$selection" == "+ New Session" ]]; then
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

# Zellij edit file (renamed from ze to avoid conflict)
zed() { zellij edit "$@"; }
zedf() { zellij edit --floating "$@"; }
zedi() { zellij edit --in-place "$@"; }

# Zellij run commands
zr() { zellij run --name "$*" -- zsh -ic "$*"; }
zrf() { zellij run --name "$*" --floating -- zsh -ic "$*"; }
zri() { zellij run --name "$*" --in-place -- zsh -ic "$*"; }

# Zellij pipe
zpipe() {
    if [[ -z "$1" ]]; then
        zellij pipe
    else
        zellij pipe -p "$1"
    fi
}

#=============================================================================
# Git Functions
#=============================================================================

# Switch git worktree using fzf
swt() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Not in a git repository"
        return 1
    fi

    local worktree
    worktree=$(git worktree list | fzf \
        --height 50% \
        --layout=reverse \
        --border=rounded \
        --prompt="Switch worktree> " \
        --header="Select a worktree" \
        | awk '{print $1}')

    [[ -n "$worktree" ]] && cd "$worktree"
}

#=============================================================================
# Python Auto-venv
#=============================================================================

autoload -Uz add-zsh-hook

_auto_venv() {
    local venv_path="$PWD/.venv"

    # If we are currently in a venv but left its directory -> deactivate
    if [[ -n "$VIRTUAL_ENV" ]]; then
        if [[ "$PWD" != "$VIRTUAL_ENV:h"/* ]]; then
            echo "Deactivating virtualenv: $VIRTUAL_ENV"
            deactivate
        fi
    fi

    # If current dir has a .venv -> activate it
    if [[ -f "$venv_path/bin/activate" ]]; then
        if [[ "$VIRTUAL_ENV" != "$venv_path" ]]; then
            echo "Auto-activating virtualenv in $venv_path"
            source "$venv_path/bin/activate"
        fi
    fi
}

add-zsh-hook chpwd _auto_venv
_auto_venv  # Run once for initial directory
