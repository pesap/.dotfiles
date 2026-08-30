# Zshrc loader - sources numbered config files in order

for f in ~/.config/zshrc/[0-9]*.zsh(N); do
    source "$f"
done

# Machine-specific local overrides are loaded by .zshenv for all Zsh shells.

# Project-specific tools, including sparkrun, own their activation and
# completion through the project's mise configuration.
