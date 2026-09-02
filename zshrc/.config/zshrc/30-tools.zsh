# Tool integrations and hooks
if command -v mise >/dev/null 2>&1; then eval "$(mise activate zsh)"; fi

# Starship prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# fzf keybindings + completion (requires fzf >= 0.48)
# Leave Ctrl+R for Atuin history search.
command -v fzf >/dev/null && FZF_CTRL_R_COMMAND= eval "$(fzf --zsh)"

# Navi cheatsheet widget (Ctrl-G)
command -v navi >/dev/null && eval "$(navi widget zsh)"

# Atuin shell history
if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh --disable-up-arrow)"
fi

# GitHub CLI completion. Prefer a static completion function already on fpath;
# generating it from gh on every shell costs extra startup time.
if (( $+commands[gh] )); then
    typeset -i _gh_completion_available=0
    for _gh_completion_dir in $fpath; do
        if [[ -r "$_gh_completion_dir/_gh" ]]; then
            _gh_completion_available=1
            break
        fi
    done
    (( _gh_completion_available )) || eval "$(gh completion -s zsh)"
    unset _gh_completion_available _gh_completion_dir
fi

# Worktrunk shell integration changes the parent shell directory after wt switch.
# Keep it after compinit so its lazy completions can register, and source the
# generated integration instead of letting wt edit this managed Zsh config.
if command -v wt >/dev/null 2>&1; then
    eval "$(wt config shell init zsh)"

    # A plain switch from a terminal should enter the resulting worktree in
    # Herdr. Keep the generated function intact so Worktrunk still owns the
    # picker, worktree lifecycle, and cd operation. The Herdr plugin invokes wt
    # with --no-cd inside a Herdr pane, so delegate all nested calls unchanged.
    if (( $+functions[wt] )); then
        functions -c wt _wt_worktrunk_shell
        unfunction wt
        wt() {
            if [[ "${HERDR_ENV:-}" != 1 && "${1:-}" == switch ]]; then
                _wt_worktrunk_shell "$@"
                local status=$?
                (( status == 0 )) || return "$status"
                herdr-project "$PWD"
                return $?
            fi
            _wt_worktrunk_shell "$@"
        }
    fi
fi

# Direnv
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# Zoxide
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# GitButler completions
command -v but >/dev/null && eval "$(but completions zsh)"

# lsd (better ls)
if command -v lsd >/dev/null; then
    alias ls='lsd'
    alias l='ls -l'
    alias la='ls -a'
    alias lla='ls -la'
    alias lt='ls --tree'
fi
