# Operations and recovery

> How-to · Task-focused recipes for maintaining an installed checkout.

## Preview before applying

Always scope an operation to a named profile and inspect the output:

```console
$ cd ~/.dotfiles
$ ./bin/.local/bin/loom setup --local --dry-run --profile common
$ loom apply --dry-run --profile common
```

The installer uses `--local` to read the current checkout. Without it, a normal
install downloads the version selected by `INSTALLER_VERSION` (default `0.0.2`)
into `~/.dotfiles` before applying it.

## Apply one package

When you changed one package, narrow the operation:

```console
$ loom apply --dry-run nvim
$ loom apply nvim
```

The package must be a real directory declared in `packages.conf`. `loom apply`
preflights every requested package before changing links. If a later package
fails, it restores the links it changed in that invocation.

To apply a profile instead:

```console
$ loom apply --profile linux-desktop
$ loom apply --profile macos
```

A profile is platform-checked. For example, `linux-desktop` fails on macOS
rather than partially applying a desktop configuration.

## Resolve a Stow conflict

A conflict means a target in `$HOME` is not the link Stow expects. Do not use
`--adopt`: this repository intentionally rejects it because it can turn live
configuration into tracked source without review.

1. Run the dry run and identify the target.
2. Decide whether the live file or repository version is authoritative.
3. If the live file matters, copy it to a safe location outside the checkout.
4. Run the real installer or `loom apply` with backups enabled (the default).
5. Inspect `~/.stow-backup/<timestamp>/` if you need to recover a replaced file.
6. Re-run the dry run until it is clean.

`--no-backup` is available to the installer for exceptional cases, but it is
not a safer conflict strategy. The installer refuses to overwrite a conflict
with backups disabled.

## Update pinned tools

Check for updates without installing them:

```console
$ loom tools outdated --bump
```

After reviewing the proposed versions, edit
[`mise/.config/mise/config.toml`](mise/.config/mise/config.toml), then install
and validate:

```console
$ loom tools install
$ loom check --repo
$ prek run --all-files
```

`mise install` is the only supported way to refresh the repository's managed
CLI tool set. Runtime artifacts under `~/.local/share/mise`, `~/.cargo`, and
`~/.rustup` are not Stow packages.

## Apply desktop configuration

`loom desktop` is a guarded workflow for the window-manager packages, not a
general replacement for Stow. Its default package list is `mango waybar`; on
macOS, pass the macOS packages explicitly:

Before using it:

- commit or stash all repository changes;
- ensure the current desktop config is already applied once so the LKG tag can be initialized;
- run it interactively when possible.

```console
$ loom desktop                         # Linux default: mango waybar
$ DOTFILES_WM_PACKAGES='sketchybar skhd yabai' loom desktop  # macOS
```

The command applies the WM-scoped files, runs smoke checks, and asks for
confirmation. If the checks fail or the 30-second prompt expires, it restores
the last-known-good Git tag (`lkg-wm-linux` or `lkg-wm-macos`). For automation:

```console
$ loom desktop --yes
```

Useful environment overrides:

```console
$ DOTFILES_ROOT=/path/to/checkout loom desktop
$ DOTFILES_WM_PACKAGES='mango waybar' loom desktop
$ DOTFILES_CONFIRM_TIMEOUT=60 loom desktop
```

`DOTFILES_SKIP_SMOKE=1` exists for tests only; do not use it as a normal update
shortcut.

## Re-run checks in isolation

The validation entry point is:

```console
$ ./scripts/validate.sh
# or, after the bin package is installed:
$ loom check --repo
```

It checks shell syntax, JSON/JSONC, TOML, Neovim Lua, Mango, Zellij, the Zellij
plugin artifact, keymap documentation, regression tests, and Git whitespace.
The CI workflow additionally runs `prek`, which covers formatting, ShellCheck,
and secret scanning.

If a check reports a missing command, install the pinned tools with `loom tools
install` first. Validation sets mise's auto-install flags to `0` so it cannot
silently modify the environment.
