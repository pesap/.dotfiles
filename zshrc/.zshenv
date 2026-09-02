# Keep the non-interactive shell PATH contract in one side-effect-free file.
[[ -r "$HOME/.config/zshrc/00-path.zsh" ]] && source "$HOME/.config/zshrc/00-path.zsh"

# Private provider settings are installed by the private personal package.
[[ -r "$HOME/.config/dotfiles/private.env" ]] && source "$HOME/.config/dotfiles/private.env"

# Optional Rust toolchain environment. Rustup is not required for every host.
if [[ -r "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi
