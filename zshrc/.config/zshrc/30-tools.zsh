# Tool integrations and hooks

# Starship prompt
command -v starship >/dev/null && eval "$(starship init zsh)"

# fzf keybindings + completion (requires fzf >= 0.48)
# Leave Ctrl+R for Atuin history search.
command -v fzf >/dev/null && FZF_CTRL_R_COMMAND= eval "$(fzf --zsh)"

# Atuin shell history
[[ -r "$HOME/.atuin/bin/env" ]] && source "$HOME/.atuin/bin/env"
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# GitHub CLI completion
command -v gh >/dev/null && eval "$(gh completion -s zsh)"

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
