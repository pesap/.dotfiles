# PATH configuration - loaded first to ensure tools are available

typeset -U path  # Keep duplicates out

path=(
    "$HOME/.local/bin"
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    $path
)

# Make mise-managed tools available to login, SSH, IDE, and non-interactive
# Zsh shells. This file is sourced from .zshenv and is safe to repeat.
[[ -d "$HOME/.local/share/mise/shims" ]] && path=("$HOME/.local/share/mise/shims" $path)

# Trust certificates installed in the macOS keychain. NREL's Netskope TLS
# inspection certificate is trusted by macOS, but not by Node's bundled CA set.
# Pi runs on Node and needs this for pi.dev updates and provider OAuth flows.
export NODE_USE_SYSTEM_CA=1

[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)

# Homebrew (macOS)
[[ -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin $path)

# Bun
if [[ -d "$HOME/.bun" ]]; then
    export BUN_INSTALL="$HOME/.bun"
    path=("$BUN_INSTALL/bin" $path)
fi

# OpenCode
[[ -d "$HOME/.opencode/bin" ]] && path=("$HOME/.opencode/bin" $path)

# Pixi
[[ -d "$HOME/.pixi/bin" ]] && path=("$HOME/.pixi/bin" $path)

# Juliaupt
[[ -d "$HOME/.juliaup/bin" ]] &&  path=("$HOME/.juliaup/bin" $path)

export PATH
