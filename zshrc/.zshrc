# Zshrc loader - sources numbered config files in order

for f in ~/.config/zshrc/[0-9]*.zsh(N); do
    source "$f"
done

# Interactive-only local overrides stay outside the repository and load last.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Project-specific tools, including sparkrun, own their activation and
# completion through the project's mise configuration.
