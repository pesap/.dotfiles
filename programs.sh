curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
curl -fsSL https://pixi.sh/install.sh | bash
curl -sS https://starship.rs/install.sh | sh

# Cargo tools
cargo install zoxide --locked
cargo install zellij --locked
cargo install ripgrep



# ZSH Plugins
cd ~/.locals/
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

