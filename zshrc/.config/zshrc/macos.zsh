# macOS-specific shell config.

path=(/opt/homebrew/bin $path)
export PATH

if [[ -d "$HOME/.juliaup/bin" ]]; then
    path=("$HOME/.juliaup/bin" $path)
    export PATH
fi

[[ -f ~/.aliases_macOS ]] && source ~/.aliases_macOS
