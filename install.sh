#!/bin/sh
# Install mise and bootstrap the public dotfiles repository.
# Usage: curl -LsSf https://pikki.cc/install.sh | sh

set -eu

if [ -z "${HOME:-}" ]; then
    printf '%s\n' 'dotfiles-install: error: HOME is not set' >&2
    exit 1
fi

repository_url=${DOTFILES_REPOSITORY_URL:-https://github.com/pesap/.dotfiles.git}
dotfiles_dir=${DOTFILES_DIR:-$HOME/.dotfiles}
mise_bin=${MISE_BIN:-$HOME/.local/bin/mise}
force_dotfiles=false

log() {
    printf 'dotfiles-install: %s\n' "$*"
}

fail() {
    printf 'dotfiles-install: error: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Install mise and bootstrap the dotfiles repository.

Options:
  --force   overwrite conflicting dotfiles
  --help    show this help

Environment:
  DOTFILES_DIR               checkout directory (default: ~/.dotfiles)
  DOTFILES_REPOSITORY_URL    repository URL
  MISE_BIN                   mise executable path
EOF
}

for argument do
    case "$argument" in
    --force) force_dotfiles=true ;;
    --help|-h) usage; exit 0 ;;
    *) fail "unknown option: $argument" ;;
    esac
done

command -v git >/dev/null 2>&1 || fail 'git is required'

if [ ! -x "$mise_bin" ]; then
    command -v curl >/dev/null 2>&1 || fail 'curl is required to install mise'
    log 'installing mise'
    curl --proto '=https' --tlsv1.2 -LsSf https://mise.run | sh
    [ -x "$mise_bin" ] || fail "mise installer did not create $mise_bin"
fi

if [ -e "$dotfiles_dir" ] || [ -L "$dotfiles_dir" ]; then
    [ -d "$dotfiles_dir/.git" ] || fail "$dotfiles_dir exists but is not a Git checkout"
    git -C "$dotfiles_dir" remote get-url origin >/dev/null 2>&1 ||
        fail "$dotfiles_dir has no origin remote"
    log 'updating dotfiles checkout'
    git -C "$dotfiles_dir" pull --ff-only
else
    log "cloning dotfiles into $dotfiles_dir"
    git clone "$repository_url" "$dotfiles_dir"
fi

case "$(uname -s)" in
Darwin) environment=macos ;;
Linux) environment=linux ;;
*) fail "unsupported operating system: $(uname -s)" ;;
esac

log "applying $environment dotfiles"
if [ "$force_dotfiles" = true ]; then
    "$mise_bin" -C "$dotfiles_dir" -E "$environment" bootstrap --yes --force-dotfiles
else
    "$mise_bin" -C "$dotfiles_dir" -E "$environment" bootstrap --yes
fi

log 'complete'
