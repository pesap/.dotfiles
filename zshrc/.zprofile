#================================================================================
# Login-only initialization
#================================================================================
if [[ -r /etc/profile ]]; then
    source /etc/profile
fi

if command -v brew >/dev/null; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
