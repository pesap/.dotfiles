# OS-specific configuration

case "$OSTYPE" in
    darwin*)
        [[ -f ~/.config/zshrc/os/macos.zsh ]] && source ~/.config/zshrc/os/macos.zsh
        ;;
    linux*)
        [[ -f ~/.config/zshrc/os/linux.zsh ]] && source ~/.config/zshrc/os/linux.zsh
        ;;
esac
