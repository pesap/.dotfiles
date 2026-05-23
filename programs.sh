#!/usr/bin/env bash
#
# Reference: programs to install after a fresh dotfiles setup.
# This script is idempotent — safe to run multiple times.
#
set -euo pipefail

say() { printf '%s\n' "$*"; }
check_cmd() { command -v "$1" &>/dev/null; }

# --- Rust ---
if ! check_cmd rustup; then
    say "Installing rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# --- Cargo tools (skip if already installed) ---
cargo_tools=(zoxide zellij ripgrep bat lsd fd-find)
for tool in "${cargo_tools[@]}"; do
    if ! check_cmd "$tool"; then
        say "Installing $tool via cargo..."
        cargo install "$tool" --locked
    else
        say "ok: $tool already installed"
    fi
done

# yazi
if ! check_cmd yazi; then
    say "Installing yazi via cargo..."
    cargo install --locked yazi-fm yazi-cli
fi

# just (command runner, referenced in zellij keybinds)
if ! check_cmd just; then
    say "Installing just via cargo..."
    cargo install just --locked
fi

# --- Pixi ---
if ! check_cmd pixi; then
    say "Installing pixi..."
    if command -v brew >/dev/null 2>&1; then
        brew install pixi
    else
        curl -fsSL https://pixi.sh/install.sh | bash
    fi
fi

# --- Starship ---
if ! check_cmd starship; then
    say "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh
fi

# --- ZSH Plugins ---
plugin_root="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
if [ ! -d "$plugin_root/zsh-syntax-highlighting" ]; then
    say "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_root/zsh-syntax-highlighting"
fi
if [ ! -d "$plugin_root/zsh-autosuggestions" ]; then
    say "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$plugin_root/zsh-autosuggestions"
fi

say "All programs checked."
