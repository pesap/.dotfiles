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

# Git switch branch using fzf (select existing or create new)
gsb() {
    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        echo "Not in a git repository"
        return 1
    fi

    # Parse branch name from a styled fzf line:
    # - remove ANSI colors
    # - remove current-branch marker (`*`)
    # - trim leading spaces
    # - read first token as ref name
    _gsb_parse_ref() {
        local raw="$1"
        local plain ref

        plain=$(printf '%s' "$raw" | sed -E $'s/\x1B\\[[0-9;]*m//g')
        plain="${plain#\* }"
        plain="${plain#"${plain%%[![:space:]]*}"}"
        ref="${plain%%[[:space:]]*}"
        printf '%s\n' "$ref"
    }

    local current_branch
    current_branch=$(git branch --show-current)

    # Build branch list: local + remote (deduped), slim display
    local branches
    branches=$({
        # Local branches
        git for-each-ref --sort=-committerdate \
            --format='%(refname:short)§%(committerdate:relative)§local' \
            refs/heads/

        # Remote branches: skip HEAD, skip those with a local counterpart
        git for-each-ref --sort=-committerdate \
            --format='%(refname:short)§%(committerdate:relative)§remote' \
            refs/remotes/ | while IFS='§' read -r branch date type; do
            case "$branch" in */HEAD) continue;; esac
            case "$branch" in */*) ;; *) continue;; esac
            short="${branch#*/}"
            git show-ref --verify --quiet "refs/heads/$short" && continue
            printf "%s§%s§%s\n" "$branch" "$date" "$type"
        done
    } | while IFS='§' read -r branch date type; do
        if [[ "$branch" = "$current_branch" ]]; then
            printf "* \033[1;35m%-30s\033[0m  \033[0;33m%s\033[0m\n" "$branch" "$date"
        elif [[ "$type" = "remote" ]]; then
            printf "  \033[0;34m%-30s\033[0m  \033[0;33m%s\033[0m\n" "$branch" "$date"
        else
            printf "  \033[1;32m%-30s\033[0m  \033[0;33m%s\033[0m\n" "$branch" "$date"
        fi
    done)

    local fzf_opts=(
        --height=70%
        --layout=reverse
        --border=rounded
        --margin=1,2
        --padding=1
        --pointer="▶"
        --ansi
        --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
        --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
        --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
        --color="border:#a6e3a1"
        --prompt="  Branch  "
        --header=$'\n  Switch branch · type a new name to create\n  ctrl-d: diff stat · ctrl-l: log\n'
        --print-query
        --nth=1
        --preview="git log --color=always --format='%C(yellow)%h%C(reset) %C(white)%s%C(reset)%n         %C(cyan)%an%C(reset) · %C(green)%cr%C(reset)' -15 {1} 2>/dev/null"
        --preview-window="right:55%:border-left:wrap"
        --bind="ctrl-d:preview(git diff --stat --color=always {1} 2>/dev/null)"
        --bind="ctrl-l:preview(git log --color=always --format='%C(yellow)%h%C(reset) %C(white)%s%C(reset)%n         %C(cyan)%an%C(reset) · %C(green)%cr%C(reset)' -15 {1} 2>/dev/null)"
        --header-first
    )

    # Run fzf — output: line 1 = query, line 2 = selection (if any)
    local result
    result=$(echo "$branches" | fzf "${fzf_opts[@]}")
    local fzf_exit=$?

    local query selection
    query=$(echo "$result" | sed -n '1p')
    selection=$(_gsb_parse_ref "$(echo "$result" | sed -n '2p')")

    # ESC or Ctrl-C — abort
    [[ $fzf_exit -eq 130 ]] && return 0
    [[ -z "$query" && -z "$selection" ]] && return 0

    if [[ -n "$selection" ]]; then
        # Only strip remote name for true remote refs (origin/foo -> foo).
        if git show-ref --verify --quiet "refs/remotes/$selection"; then
            git switch "${selection#*/}"
        else
            git switch "$selection"
        fi
    else
        # No selection — query is a new branch name
        local new_branch="$query"

        # Check if it matches a remote branch
        local remote_match
        remote_match=$(git branch -r --format='%(refname:short)' | sed 's|^[^/]*/||' | grep -x "$new_branch")
        if [[ -n "$remote_match" ]]; then
            git switch "$new_branch"
            return
        fi

        echo "Branch '$new_branch' does not exist. Creating..."

        # Pick a base branch — slim list, same style
        local base_branches
        base_branches=$(git for-each-ref --sort=-committerdate \
            --format='%(refname:short)§%(committerdate:relative)' \
            refs/heads/ | while IFS='§' read -r branch date; do
            printf "  \033[1;32m%-30s\033[0m  \033[0;33m%s\033[0m\n" "$branch" "$date"
        done)

        local base_opts=(
            --height=50%
            --layout=reverse
            --border=rounded
            --margin=1,2
            --padding=1
            --pointer="▶"
            --ansi
            --nth=1
            --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
            --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
            --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
            --color="border:#e0af68"
            --prompt="  Base  "
            --header=$'\n  Select base branch for '"'$new_branch'"$'\n'
            --preview="git log --color=always --format='%C(yellow)%h%C(reset) %s %C(green)(%cr)%C(reset)' -10 {1} 2>/dev/null"
            --preview-window="right:50%:border-left:wrap"
            --header-first
        )

        local base
        base=$(_gsb_parse_ref "$(echo "$base_branches" | fzf "${base_opts[@]}")")
        [[ -z "$base" ]] && return 0

        git switch -c "$new_branch" "$base"
    fi
}

#=============================================================================
# Python Auto-venv
#=============================================================================

autoload -Uz add-zsh-hook

_auto_venv() {
    local venv_path="$PWD/.venv"

    # Deactivate if we left the venv directory
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        if [[ "$PWD" != "$VIRTUAL_ENV:h"/* ]]; then
            if typeset -f deactivate >/dev/null; then
                echo "Deactivating virtualenv: $VIRTUAL_ENV"
                deactivate
            else
                # hard fallback: clean env without deactivate
                unset VIRTUAL_ENV
                export PATH="${PATH#*:}"
            fi
        fi
    fi

    # If current dir has a .venv -> activate it
    if [[ -f "$venv_path/bin/activate" ]]; then
        if [[ "$VIRTUAL_ENV" != "$venv_path" ]]; then
            # echo "Auto-activating virtualenv in $venv_path"
            source "$venv_path/bin/activate"
        fi
    fi
}


add-zsh-hook chpwd _auto_venv
_auto_venv  # Run once for initial directory

#=============================================================================
# Navigation Functions
#=============================================================================

# Folder jump using fd + fzf (with worktree support)
# Searches only in dev, tmp, sandbox, work directories
fj() {
    command -v fd >/dev/null 2>&1 || { echo "fd not installed"; return 1; }
    command -v fzf >/dev/null 2>&1 || { echo "fzf not installed"; return 1; }

    local dirs=("$HOME/dev" "$HOME/tmp" "$HOME/sandbox" "$HOME/work")
    local search_dirs=()
    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] && search_dirs+=("$dir")
    done

    [[ ${#search_dirs[@]} -eq 0 ]] && { echo "No project directories found"; return 1; }

    local max_depth="${1:-1}"

    local fzf_opts=(
        --height=60%
        --layout=reverse
        --border=rounded
        --margin=5%,10%
        --padding=1
        --pointer="▶"
        --marker="●"
        --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
        --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
        --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
        --color="border:#7aa2f7"
        --prompt="   "
        --header="  Navigate to folder"
        --preview="lsd --color=always --icon=always {} 2>/dev/null || ls -la {}"
        --preview-window="right:40%:border-left"
    )

    local selected
    selected=$(fd --type d \
        --exclude node_modules --exclude .bare \
        --max-depth "$max_depth" . "${search_dirs[@]}" 2>/dev/null | \
        fzf "${fzf_opts[@]}")

    [[ -z "$selected" ]] && return 0

    # Check if it's a git repo with worktrees
    if [[ -d "$selected/.git" ]] || [[ -f "$selected/.git" ]]; then
        local worktrees
        worktrees=$(git -C "$selected" worktree list 2>/dev/null | tail -n +2)

        if [[ -n "$worktrees" ]]; then
            # Has worktrees - show picker
            local wt_opts=(
                --height=40%
                --layout=reverse
                --border=rounded
                --margin=10%,20%
                --padding=1
                --pointer="▶"
                --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
                --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
                --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
                --color="border:#a6e3a1"
                --prompt="   "
                --header="  Git worktrees found — select one (or ESC for main)"
            )

            local all_trees
            all_trees=$(git -C "$selected" worktree list 2>/dev/null)

            local wt_selected
            wt_selected=$(echo "$all_trees" | fzf "${wt_opts[@]}" | awk '{print $1}')

            if [[ -n "$wt_selected" ]]; then
                selected="$wt_selected"
            fi
        fi
    fi

    cd "$selected" && echo "  $(pwd)"
}

# Folder jump with hidden folders (Ctrl+Shift+F)
fjh() {
    command -v fd >/dev/null 2>&1 || { echo "fd not installed"; return 1; }
    command -v fzf >/dev/null 2>&1 || { echo "fzf not installed"; return 1; }

    local search_path="${1:-$HOME}"
    local max_depth="${2:-2}"

    local fzf_opts=(
        --height=60%
        --layout=reverse
        --border=rounded
        --margin=5%,10%
        --padding=1
        --pointer="▶"
        --marker="●"
        --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
        --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
        --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
        --color="border:#f5c2e7"
        --prompt="   "
        --header="  Navigate to folder (hidden)"
        --preview="lsd --color=always --icon=always {} 2>/dev/null || ls -la {}"
        --preview-window="right:40%:border-left"
    )

    local selected
    selected=$(fd --type d --hidden \
        --exclude .git --exclude node_modules --exclude .bare \
        --exclude .Trash --exclude Library --exclude Applications \
        --max-depth "$max_depth" . "$search_path" 2>/dev/null | \
        fzf "${fzf_opts[@]}")

    [[ -z "$selected" ]] && return 0

    # Same worktree support as fj()
    if [[ -d "$selected/.git" ]] || [[ -f "$selected/.git" ]]; then
        local worktrees
        worktrees=$(git -C "$selected" worktree list 2>/dev/null | tail -n +2)

        if [[ -n "$worktrees" ]]; then
            local wt_opts=(
                --height=40%
                --layout=reverse
                --border=rounded
                --margin=10%,20%
                --padding=1
                --pointer="▶"
                --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
                --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
                --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
                --color="border:#a6e3a1"
                --prompt="   "
                --header="  Git worktrees found — select one (or ESC for main)"
            )

            local all_trees
            all_trees=$(git -C "$selected" worktree list 2>/dev/null)

            local wt_selected
            wt_selected=$(echo "$all_trees" | fzf "${wt_opts[@]}" | awk '{print $1}')

            if [[ -n "$wt_selected" ]]; then
                selected="$wt_selected"
            fi
        fi
    fi

    cd "$selected" && echo "  $(pwd)"
}

# Quick project jump (searches dev, work, sandbox)
pj() {
    local dirs=("$HOME/dev" "$HOME/work" "$HOME/sandbox")
    local search_dirs=""

    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] && search_dirs="$search_dirs $dir"
    done

    [[ -z "$search_dirs" ]] && { echo "No project directories found"; return 1; }

    # Beautiful fzf options
    local fzf_opts=(
        --height=60%
        --layout=reverse
        --border=rounded
        --margin=5%,10%
        --padding=1
        --pointer="▶"
        --marker="●"
        --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
        --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
        --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
        --color="border:#fab387"
        --prompt="   "
        --header="  Jump to project"
        --delimiter="/"
        --with-nth="4.."
        --preview="lsd --color=always --icon=always {} 2>/dev/null || ls -la {}"
        --preview-window="right:40%:border-left"
    )

    local selected
    selected=$(fd --type d --max-depth 1 --min-depth 1 --exclude .bare \
        . $search_dirs 2>/dev/null | fzf "${fzf_opts[@]}")

    [[ -z "$selected" ]] && return 0

    # Check for worktrees (same logic as fj)
    if [[ -d "$selected/.git" ]] || [[ -f "$selected/.git" ]]; then
        local worktrees
        worktrees=$(git -C "$selected" worktree list 2>/dev/null | tail -n +2)

        if [[ -n "$worktrees" ]]; then
            local wt_opts=(
                --height=40%
                --layout=reverse
                --border=rounded
                --margin=10%,20%
                --padding=1
                --pointer="▶"
                --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
                --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
                --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
                --color="border:#a6e3a1"
                --prompt="   "
                --header="  Git worktrees found — select one (or ESC for main)"
            )

            local all_trees
            all_trees=$(git -C "$selected" worktree list 2>/dev/null)

            local wt_selected
            wt_selected=$(echo "$all_trees" | fzf "${wt_opts[@]}" | awk '{print $1}')

            if [[ -n "$wt_selected" ]]; then
                selected="$wt_selected"
            fi
        fi
    fi

    cd "$selected" && echo "  $(pwd)"
}

#=============================================================================
# Keybindings
#=============================================================================

# Ctrl+S - Zellij sessionizer popup
if [[ -o interactive ]]; then
    stty -ixon 2>/dev/null
fi

_zellij_sessionizer_widget() {
    zle -I
    zellij-sessionizer
    zle reset-prompt
}
zle -N _zellij_sessionizer_widget
bindkey '^s' _zellij_sessionizer_widget

# Ctrl+F - Folder jump (silent)
_fj_widget() {
    zle -I
    fj
    zle reset-prompt
}
zle -N _fj_widget
bindkey '^f' _fj_widget

# Ctrl+Shift+F - Folder jump with hidden folders
_fjh_widget() {
    zle -I
    fjh
    zle reset-prompt
}
zle -N _fjh_widget
bindkey '^[F' _fjh_widget

# Ctrl+G - Project jump (silent)
_pj_widget() {
    zle -I
    pj
    zle reset-prompt
}
zle -N _pj_widget
bindkey '^g' _pj_widget
