# Dotfiles

Cross-platform dotfiles for Linux and macOS with a POSIX sh installer.

Install (recommended):
```sh
curl -sSfL https://raw.githubusercontent.com/pesap/.dotfiles/0.0.1/bootstrap.sh | sh
```

Install with flags:
```sh
curl -sSfL https://raw.githubusercontent.com/pesap/.dotfiles/0.0.1/bootstrap.sh | sh -s -- --dry-run
curl -sSfL https://raw.githubusercontent.com/pesap/.dotfiles/0.0.1/bootstrap.sh | sh -s -- --yes
curl -sSfL https://raw.githubusercontent.com/pesap/.dotfiles/0.0.1/bootstrap.sh | sh -s -- --no-backup
```

Local install (from a cloned repo):
```sh
./install.sh --local
```

Health check:
```sh
dotfiles-healthcheck
```

Safe WM apply (Linux/macOS):
```sh
dotcfg run
# non-interactive
DOTFILES_SKIP_SMOKE=1 dotcfg run --yes   # testing only
```

Notes:
- The bootstrap script installs prerequisites via your package manager.
- The installer defaults to non-interactive behavior for `curl | sh`.
- Existing files are moved to `~/.dotfiles-backup/` before stowing (disable with `--no-backup`).
