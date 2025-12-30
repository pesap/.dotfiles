# OS detection to load platform-specific config.

case "$OSTYPE" in
  darwin*)
    [[ -f ~/.config/zshrc/macos.zsh ]] && source ~/.config/zshrc/macos.zsh
    ;;
  linux*)
    [[ -f ~/.config/zshrc/linux.zsh ]] && source ~/.config/zshrc/linux.zsh
    ;;
esac
