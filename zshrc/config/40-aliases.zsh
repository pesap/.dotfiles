# Public aliases shared by Bash and Zsh.
[[ -r "$HOME/.aliases" ]] && source "$HOME/.aliases"
[[ -r "$HOME/.aliases.os" ]] && source "$HOME/.aliases.os"

# Private/sensitive aliases remain outside the repository.
[[ -r "$HOME/.private" ]] && source "$HOME/.private"
