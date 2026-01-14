# Linux-specific shell config.

if [[ -d "$HOME/.juliaup/bin" ]]; then
    path=("$HOME/.juliaup/bin" $path)
    export PATH
fi

[[ -f ~/.aliases_arch ]] && source ~/.aliases_arch
