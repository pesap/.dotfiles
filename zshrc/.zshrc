# Zshrc loader - sources numbered config files in order

for f in ~/.config/zshrc/[0-9]*.zsh(N); do
    source "$f"
done

# Machine-specific local overrides (not in git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.zshrc_local ]] && source ~/.zshrc_local

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

# Added by GitButler installer
eval "$(but completions zsh)"

# JJ version control completions
command -v jj >/dev/null 2>&1 && source <(jj util completion zsh 2>/dev/null)
