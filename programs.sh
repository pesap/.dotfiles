curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
curl -fsSL https://pixi.sh/install.sh | bash
curl -sS https://starship.rs/install.sh | sh

# Cargo tools
cargo install zoxide --locked
cargo install zellij --locked
cargo install ripgrep
cargo install bat --locked
cargo install --locked yazi-fm yazi-cli


# ZSH Plugins
plugin_root="${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins"
if [ ! -d "$plugin_root/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_root/zsh-syntax-highlighting"
fi
if [ ! -d "$plugin_root/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_root/zsh-autosuggestions"
fi
