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

## Windows `pil`

The Windows launcher is a single file:

```text
bin/.local/bin/pil.cmd
```

How to use it:

1. Copy `pil.cmd` to a folder on your Windows `PATH`.
2. Open a new Command Prompt, PowerShell, or Windows Terminal.
3. Run:

```powershell
pil setup
```

Then use it normally:

```powershell
pil
pil --help
```

If it is not on `PATH` yet, run it directly from the current folder:

```powershell
.\pil.cmd
```

Requirements:

- `pi` installed and on `PATH`
- `pwsh` or `powershell` on `PATH`

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
