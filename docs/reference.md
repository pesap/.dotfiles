# Profiles, packages, and commands

> Reference · Names and interfaces that are expected to stay stable.

## Loom

```text
loom COMMAND [OPTIONS]
```

| Command | Purpose |
| --- | --- |
| `loom setup` | Install or update a profile from the current checkout or a release |
| `loom apply` | Reapply packages from the existing checkout |
| `loom check` | Check the machine and repository |
| `loom desktop` | Apply desktop configuration with smoke checks and rollback |
| `loom tools` | Install or inspect mise-managed tools |
| `loom profiles` | List supported profiles |
| `loom version` | Show the checkout version |

`loom` is installed into `~/.local/bin` by the `bin` Stow package. Before the
package is installed, invoke it from a checkout as:

```console
$ ./bin/.local/bin/loom setup --local --dry-run --profile common
```

The root `install.sh` and remote `bootstrap.sh` remain compatibility/bootstrap
entry points; normal operations should use Loom.

### `loom setup`

```text
loom setup [OPTIONS]
```

Setup passes installer options through unchanged:

| Option | Meaning |
| --- | --- |
| `--local`, `-l` | Use the current checkout instead of downloading an archive |
| `--profile NAME` | Select `common`, `linux-desktop`, or `macos` |
| `--dry-run`, `-n` | Print and preflight actions without changing links |
| `--verbose`, `-v` | Print additional installer details |
| `--yes`, `--force`, `-y` | Continue through an existing checkout or conflict prompt |
| `--no-backup` | Disable installer backups; conflicts still require an explicit safe path |
| `--help`, `-h` | Print usage |

The installer stores downloaded checkouts at `~/.dotfiles`. `INSTALLER_VERSION`
selects the archive tag. `packages.conf` is the authoritative profile allowlist.

### `loom apply`

```text
loom apply [--dry-run] [--profile NAME] [package ...]
```

With no package arguments, `loom apply` applies the selected profile, defaulting
to `common`. With package arguments, each package must be declared in
`packages.conf`, even if it is not part of the selected profile.

`loom apply` always runs a Stow preflight first. `--adopt` is unsupported. The
`DOTFILES_DIR` environment variable changes the checkout path from its default
of `$HOME/.dotfiles`.

### `loom check`

```text
loom check [--machine|--repo] [--profile NAME]
```

With no scope, Loom runs both checks:

- the machine check reports required commands, optional commands, and selected profile packages;
- the repository check runs `scripts/validate.sh`.

Use `--machine` or `--repo` to run one scope. The selected profile defaults to
`DOTFILES_PROFILE=common`.

### `loom desktop`

```text
loom desktop [--yes]
```

`loom desktop` requires a clean Git worktree, applies only WM-scoped packages,
runs smoke checks, and rolls back to the last-known-good tag when checks fail
or interactive confirmation expires.

| Variable | Default | Purpose |
| --- | --- | --- |
| `DOTFILES_ROOT` | `~/.dotfiles` | Git checkout used for the guarded desktop apply |
| `DOTFILES_WM_PACKAGES` | `mango waybar` | WM packages to apply |
| `DOTFILES_CONFIRM_TIMEOUT` | `30` | Interactive confirmation timeout in seconds |
| `DOTFILES_SKIP_SMOKE` | `0` | Test-only smoke-check bypass |

It uses `lkg-wm-linux` on Linux and `lkg-wm-macos` on macOS as rollback anchors.
On macOS, set `DOTFILES_WM_PACKAGES='sketchybar skhd yabai'` explicitly.

### `loom tools`

```text
loom tools install
loom tools outdated [mise options]
```

`loom tools install` installs exact versions from the mise manifest.
`loom tools outdated` reports available updates without installing them.

## Profiles and packages

`packages.conf` has one profile per line. The first field is the profile name;
remaining fields are Stow package directories.

| Profile | Package directories |
| --- | --- |
| `common` | `alacritty atuin bin man nvim pi starship worktrunk zellij zshrc mise` |
| `linux-desktop` | Common + `linux mango waybar` |
| `macos` | Common + `sketchybar skhd yabai personal` |

`personal` is optional. All other packages named by a selected profile must
exist. Package names are restricted to simple letters, numbers, `_`, and `-`.

## Important paths

| Path | Role |
| --- | --- |
| `packages.conf` | Profile-to-package allowlist |
| `install.sh` | Downloading/local installer implementation |
| `bootstrap.sh` | Prerequisite installation and checksum-verified bootstrap |
| `bin/.local/bin/loom` | Installed Loom command |
| `man/.local/share/man/man1/` | Installed custom command manuals |
| `scripts/apply.sh` | Loom package-apply implementation |
| `scripts/desktop-apply.sh` | Loom guarded desktop-apply implementation |
| `scripts/validate.sh` | Read-only repository validation entry point |
| `tests/` | Isolated installer, apply, and desktop regression tests |
| `zshrc/.config/zshrc/05-man.zsh` | Adds installed manuals to `MANPATH` |
| `KEYMAPS.md` | Human-readable shortcut index |
| `.github/workflows/validate.yml` | CI validation and scheduled dependency report |
