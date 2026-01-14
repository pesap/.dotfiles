# Tool integrations and hooks

# Starship prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# Cargo/Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Direnv
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# Zoxide
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# lsd (better ls)
if command -v lsd >/dev/null; then
    alias ls='lsd'
    alias l='ls -l'
    alias la='ls -a'
    alias lla='ls -la'
    alias lt='ls --tree'
fi
