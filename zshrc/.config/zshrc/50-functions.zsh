#=============================================================================
# Herdr project sessions
#=============================================================================

# Keep Herdr subcommands native, but route a plain launch through the picker.
herdr() {
    if (( $# == 0 )); then
        herdr-project
    else
        command herdr "$@"
    fi
}

#=============================================================================
# Zellij helpers
#=============================================================================

# Zellij session picker
alias za=zession

# Delete all zellij sessions
zd() {
    zellij delete-all-sessions --force --yes 2>/dev/null
    zellij ls -n
}

# Zellij edit (renamed from `ze` to avoid conflict)
alias zed='zellij edit'
alias zedf='zellij edit --floating'
alias zedi='zellij edit --in-place'

# Zellij run: first arg is used as pane name, all args joined as the command
zr()  { zellij run --name "${1:-cmd}"            -- zsh -c "$*"; }
zrf() { zellij run --name "${1:-cmd}" --floating -- zsh -c "$*"; }
zri() { zellij run --name "${1:-cmd}" --in-place -- zsh -c "$*"; }

# Zellij pipe (forwards all args after the plugin name)
zpipe() {
    if (( $# == 0 )); then
        zellij pipe
    else
        zellij pipe -p "$1" "${@:2}"
    fi
}

#=============================================================================
# Auto-activate .venv on cd
#=============================================================================

autoload -Uz add-zsh-hook

_auto_venv() {
    local venv_path="$PWD/.venv"

    # Deactivate if we left the venv's parent tree
    if [[ -n "${VIRTUAL_ENV:-}" ]]; then
        local venv_root=${VIRTUAL_ENV:h}
        if [[ "$PWD" != "$venv_root" && "$PWD" != "$venv_root"/* ]]; then
            if typeset -f deactivate >/dev/null; then
                deactivate
            else
                # Safe fallback: scrub the venv's bin from PATH without
                # blindly stripping the first PATH entry.
                export PATH="${PATH//${VIRTUAL_ENV}\/bin:/}"
                unset VIRTUAL_ENV
            fi
        fi
    fi

    # Activate if current dir has a .venv
    if [[ -f "$venv_path/bin/activate" && "$VIRTUAL_ENV" != "$venv_path" ]]; then
        source "$venv_path/bin/activate"
    fi
}

add-zsh-hook chpwd _auto_venv
_auto_venv

#=============================================================================
# Folder/project jump (fzf-based)
#=============================================================================

# Shared catppuccin fzf theme + preview options.
_fzf_theme_opts() {
    print -r -- \
        --height=60% --layout=reverse --border=rounded \
        --margin=5%,10% --padding=1 --pointer="▶" --marker="●" \
        --color="bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8" \
        --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc" \
        --color="marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8" \
        --preview="lsd --color=always --icon=always {} 2>/dev/null || ls -la {}" \
        --preview-window="right:40%:border-left"
}

# If $1 is a git repo with extra worktrees, offer a picker.
# Prints the chosen path (worktree or original) on stdout.
_maybe_pick_worktree() {
    local dir="$1"
    if [[ ! -d "$dir/.git" && ! -f "$dir/.git" ]]; then
        print -r -- "$dir"; return
    fi

    local trees
    trees=$(git -C "$dir" worktree list 2>/dev/null) || { print -r -- "$dir"; return; }
    (( $(print -r -- "$trees" | wc -l) > 1 )) || { print -r -- "$dir"; return; }

    local pick
    pick=$(print -r -- "$trees" | fzf \
        ${(z)"$(_fzf_theme_opts)"} \
        --header="  Git worktrees — select one (ESC for main)" \
        --color="border:#a6e3a1" \
        --prompt="   " | awk '{print $1}')

    print -r -- "${pick:-$dir}"
}

# Unified folder jump.
#   fj             -> $HOME/{dev,tmp,sandbox,work}, depth 1
#   fj 2           -> same, depth 2
#   fj -H [path] [depth] -> hidden, walks $path (default $HOME) at depth 2
fj() {
    command -v fd  >/dev/null 2>&1 || { echo "fd not installed";  return 1; }
    command -v fzf >/dev/null 2>&1 || { echo "fzf not installed"; return 1; }

    local hidden=0
    if [[ "$1" == "-H" ]]; then hidden=1; shift; fi

    local -a search_dirs fd_args
    local header border

    if (( hidden )); then
        search_dirs=("${1:-$HOME}")
        local max_depth="${2:-2}"
        fd_args=(--type d --hidden
            --exclude .git --exclude node_modules --exclude .bare
            --exclude .Trash --exclude Library --exclude Applications
            --max-depth "$max_depth")
        header="  Navigate to folder (hidden)"
        border="#f5c2e7"
    else
        local -a candidates=("$HOME/dev" "$HOME/tmp" "$HOME/sandbox" "$HOME/work")
        for dir in "${candidates[@]}"; do
            [[ -d "$dir" ]] && search_dirs+=("$dir")
        done
        (( ${#search_dirs[@]} )) || { echo "No project directories found"; return 1; }
        local max_depth="${1:-1}"
        fd_args=(--type d
            --exclude node_modules --exclude .bare
            --max-depth "$max_depth")
        header="  Navigate to folder"
        border="#7aa2f7"
    fi

    local selected
    selected=$(fd "${fd_args[@]}" . "${search_dirs[@]}" 2>/dev/null | fzf \
        ${(z)"$(_fzf_theme_opts)"} \
        --header="$header" \
        --color="border:$border" \
        --prompt="   ")

    [[ -z "$selected" ]] && return 0
    selected=$(_maybe_pick_worktree "$selected")
    cd "$selected" && echo "  $(pwd)"
}

# Quick project jump: $HOME/{dev,work,sandbox}, depth 1, hides parent path
pj() {
    command -v fd  >/dev/null 2>&1 || { echo "fd not installed";  return 1; }
    command -v fzf >/dev/null 2>&1 || { echo "fzf not installed"; return 1; }

    local -a search_dirs
    for dir in "$HOME/dev" "$HOME/work" "$HOME/sandbox"; do
        [[ -d "$dir" ]] && search_dirs+=("$dir")
    done
    (( ${#search_dirs[@]} )) || { echo "No project directories found"; return 1; }

    local selected
    selected=$(fd --type d --max-depth 1 --min-depth 1 --exclude .bare \
        . "${search_dirs[@]}" 2>/dev/null | fzf \
        ${(z)"$(_fzf_theme_opts)"} \
        --header="  Jump to project" \
        --color="border:#fab387" \
        --prompt="   " \
        --delimiter="/" --with-nth="4..")

    [[ -z "$selected" ]] && return 0
    selected=$(_maybe_pick_worktree "$selected")
    cd "$selected" && echo "  $(pwd)"
}

# Hidden-folder jump alias for muscle memory
fjh() { fj -H "$@"; }

# Force emacs keymap to avoid accidental vi mode
bindkey -e

# Make Ctrl+\ usable as a binding by disabling flow-control / quit.
if [[ -o interactive ]]; then
    stty -ixon  2>/dev/null
    stty quit undef 2>/dev/null
fi

# Bind a widget across all relevant keymaps.
_bind_widget_all_keymaps() {
    local key="$1" widget="$2"
    bindkey            "$key" "$widget"
    bindkey -M emacs   "$key" "$widget"
    bindkey -M viins   "$key" "$widget"
    bindkey -M vicmd   "$key" "$widget"
}

# Run a command as a zle widget, redrawing the prompt after.
_make_cmd_widget() {
    local name="$1" cmd="$2"
    eval "
        ${name}() {
            zle -I
            ${cmd}
            zle reset-prompt
        }
        zle -N ${name}
    "
}

_make_cmd_widget _herdr_project_widget 'BUFFER=herdr-project; CURSOR=${#BUFFER}; zle accept-line; return'
_make_cmd_widget _fj_widget      'fj'
_make_cmd_widget _fjh_widget     'fjh'
_make_cmd_widget _pj_widget      'pj'

_bind_widget_all_keymaps '^\\' _herdr_project_widget # Ctrl+\ -> Herdr project picker
_bind_widget_all_keymaps '^f'  _fj_widget        # Ctrl+F  -> folder jump (shadows forward-char by design)
_bind_widget_all_keymaps '^[F' _fjh_widget       # Alt+Shift+F -> folder jump (hidden)
_bind_widget_all_keymaps '^[g' _pj_widget        # Alt+G   -> project jump
