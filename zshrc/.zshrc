# Zshrc loader - sources numbered config files in order

for f in ~/.config/zshrc/[0-9]*.zsh(N); do
    source "$f"
done

# Machine-specific local overrides are loaded by .zshenv for all Zsh shells.

# sparkrun tab-completion
eval "$(_SPARKRUN_COMPLETE=zsh_source /home/morgoth/.cache/uv/archive-v0/lp6HPryajo9rroac/bin/sparkrun)"
