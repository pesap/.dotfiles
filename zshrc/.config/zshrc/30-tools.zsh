# Tool integrations and hooks
if command -v mise >/dev/null 2>&1; then eval "$(mise activate zsh)"; fi

# Bun completion must load after compinit, which is initialized by 20-plugins.zsh.
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# Starship prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# fzf keybindings + completion (requires fzf >= 0.48)
# Leave Ctrl+R for Atuin history search.
command -v fzf >/dev/null && FZF_CTRL_R_COMMAND= eval "$(fzf --zsh)"

# Navi cheatsheet widget (Ctrl-G)
command -v navi >/dev/null && eval "$(navi widget zsh)"

# Atuin shell history
if command -v atuin >/dev/null 2>&1; then
    [[ -f "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"
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

# Cargo/Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

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
