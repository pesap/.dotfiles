# OS-specific configuration (merged from os/*.zsh)

# Julia (used on both Linux and macOS)
if [[ -d "$HOME/.juliaup/bin" ]]; then
    path=("$HOME/.juliaup/bin" $path)
    export PATH
fi

case "$OSTYPE" in
    darwin*)
        [[ -f ~/.aliases_macOS ]] && source ~/.aliases_macOS
        ;;
    linux*)
        [[ -f ~/.aliases_arch ]] && source ~/.aliases_arch
        ;;
esac
