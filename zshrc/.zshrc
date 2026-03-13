# Zshrc loader - sources numbered config files in order

for f in ~/.config/zshrc/[0-9]*.zsh(N); do
    source "$f"
done

# Machine-specific local overrides (not in git)
[[ -f ~/.zshrc_local ]] && source ~/.zshrc_local

eval "$(/Users/psanchez/.local/bin/mise activate zsh)" # added by https://mise.run/zsh
