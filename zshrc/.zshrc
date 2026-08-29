# Zshrc loader - sources numbered config files in order

for f in ~/.config/zshrc/[0-9]*.zsh(N); do
    source "$f"
done

# Machine-specific local overrides (not in git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.zshrc_local ]] && source ~/.zshrc_local

# sparkrun tab-completion
eval "$(_SPARKRUN_COMPLETE=zsh_source /home/morgoth/.cache/uv/archive-v0/lp6HPryajo9rroac/bin/sparkrun)"
