# Optional Rust toolchain environment. Rustup is not required for every host.
if [[ -r "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi
