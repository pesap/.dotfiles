# PATH configuration - loaded first to ensure tools are available

typeset -U path  # Keep duplicates out

path=(
    "$HOME/.local/bin"
    "$HOME/.cargo/bin"
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    $path
)

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
