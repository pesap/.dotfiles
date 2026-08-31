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

# Trust certificates installed in the macOS keychain. NREL's Netskope TLS
# inspection certificate is trusted by macOS, but not by Node's bundled CA set.
# Pi runs on Node and needs this for pi.dev updates and provider OAuth flows.
export NODE_USE_SYSTEM_CA=1

[[ -d "$HOME/.cargo/bin" ]] && path=("$HOME/.cargo/bin" $path)

# Homebrew (macOS)
[[ -d /opt/homebrew/bin ]] && path=(/opt/homebrew/bin $path)

export PATH
