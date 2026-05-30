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
cargo install lsd --locked
cargo install fd-find --locked
cargo install --locked yazi-fm yazi-cli


# ZSH plugin manager (antidote)
# Prefer brew on macOS, fall back to a git clone everywhere else.
# Plugins themselves are declared in ~/.zsh_plugins.txt and fetched lazily by
# antidote on first shell startup.
if command -v brew >/dev/null 2>&1; then
    brew list antidote >/dev/null 2>&1 || brew install antidote
else
    ANTIDOTE_HOME="${ANTIDOTE_HOME:-$HOME/.antidote}"
    if [ ! -d "$ANTIDOTE_HOME" ]; then
        git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_HOME"
    fi
fi
