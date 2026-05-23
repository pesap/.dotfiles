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

# bun completions
[ -s "/home/morgoth/.bun/_bun" ] && source "/home/morgoth/.bun/_bun"

# Added by GitButler installer
export PATH="$HOME/.local/bin:$PATH"
eval "$(but completions zsh)"
