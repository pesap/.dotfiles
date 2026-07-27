<div align="center">

# `.dotfiles`

### A reproducible shell, editor, terminal, and window-manager setup for macOS and Linux.

[![Validation](https://github.com/pesap/.dotfiles/actions/workflows/validate.yml/badge.svg)](https://github.com/pesap/.dotfiles/actions/workflows/validate.yml)

[Install](#quickstart) · [Profiles](#profiles) · [Daily workflow](#daily-workflow) · [Documentation](#documentation)

</div>

> [!IMPORTANT]
> This repository manages files in a live home directory. Read the dry-run output
> before applying a profile. The installer backs up conflicts by default and
> intentionally refuses Stow's `--adopt` mode.

## What this is

This is a personal, cross-platform workstation setup built around three ideas:

- Stow packages keep configuration in the repository while linking it into `$HOME`.
- mise installs pinned user tools reproducibly, without checking tool state into Git.
- Profiles make the safe, shared baseline separate from Linux and macOS desktop configuration.

The result is a small set of commands for rebuilding a machine, checking its health,
and keeping changes reviewable:

```console
$ loom tools install
$ loom check
```

## Quickstart

### Existing checkout

```console
$ git clone https://github.com/pesap/.dotfiles.git ~/.dotfiles
$ cd ~/.dotfiles

# Inspect exactly what Loom would do.
$ ./bin/.local/bin/loom setup --local --dry-run --profile common

# Apply the shared configuration.
$ ./bin/.local/bin/loom setup --local --profile common

# Install the pinned CLI tools and validate the checkout.
$ loom tools install
$ loom check
```

Use `--profile linux-desktop` on Linux or `--profile macos` on macOS when you
also want the platform-specific desktop packages. See [Profiles](#profiles).

### Install Loom with curl

The bootstrap installs missing prerequisites, installs the selected profile,
and places the `loom` CLI in `~/.local/bin`. Review the script before piping it
to a shell:

```console
$ curl --proto '=https' --tlsv1.2 -LsSf \
    https://raw.githubusercontent.com/pesap/.dotfiles/main/bootstrap.sh \
  | sh -s -- --profile common
$ loom check
```

The bootstrap is suitable for a fresh machine and verifies the pinned installer
checksum before running the installer.

For maximum control, install the prerequisites yourself and use the existing
checkout flow above. The bootstrap supports Homebrew, `apt-get`, `dnf`,
`pacman`, and `zypper`.

## Profiles

Profiles are declared in [`packages.conf`](packages.conf), the single allowlist
used by Loom's setup, apply, and check commands.

| Profile         | Platform      | Includes                                                                              | Best for                   |
| --------------- | ------------- | ------------------------------------------------------------------------------------- | -------------------------- |
| `common`        | macOS + Linux | Alacritty, Atuin, shell, Neovim, Pi, Starship, Zellij, Worktrunk, mise, man pages, local scripts | The safe baseline; default |
| `linux-desktop` | Linux         | `common` + Linux settings, Mango, Waybar                                              | A Mango/Wayland desktop    |
| `macos`         | macOS         | `common` + SketchyBar, skhd, yabai, optional personal config                          | A yabai/skhd desktop       |

Inspect the available profiles without changing anything:

```console
$ loom profiles
common
linux-desktop
macos
```

## What is managed

| Area          | Package(s)                    | Highlights                                                               |
| ------------- | ----------------------------- | ------------------------------------------------------------------------ |
| Shell         | `zshrc`, `starship`, `atuin`  | Prompt, history, completions, navigation, aliases                        |
| Terminal      | `alacritty`, `zellij`         | Cross-platform terminal settings and a locked-first multiplexer workflow |
| Editor        | `nvim`                        | Native LSP, lazy.nvim, FFF/fzf-lua, Git tooling, format-on-save          |
| Tools         | `mise`, `bin`, `man`          | Pinned CLI versions, manuals, and small workflow helpers                 |
| Linux desktop | `mango`, `waybar`, `linux`    | Window manager, status bar, and platform settings                        |
| macOS desktop | `sketchybar`, `skhd`, `yabai` | Bar, hotkeys, spaces, and window management                              |
| AI workflow   | `pi`                          | Pi configuration and local agent workflow files                          |

The repository stores configuration, not mutable runtime state. Rustup/Cargo
artifacts and mise's installed tools remain in `~/.rustup`, `~/.cargo`, and
`~/.local/share/mise`; Stow never traverses those directories.

## Daily workflow

### Apply a change safely

```console
$ cd ~/.dotfiles
$ git pull --ff-only
$ loom apply --dry-run --profile common
$ loom apply --profile common
```

Loom apply accepts only packages declared in `packages.conf`, always preflights
with GNU Stow, and rolls back its own links if an apply fails. It never adopts
live files into the repository.

For a desktop-only change, use the guarded workflow:

```console
$ loom desktop
# or, for a non-interactive deployment after smoke checks:
$ loom desktop --yes
```

`loom desktop` requires a clean Git tree, applies only the configured WM
packages, runs smoke checks, and rolls back to the last-known-good tag when the
checks fail or the interactive confirmation times out. See [desktop
configuration](docs/operations.md#apply-desktop-configuration).

### Check the machine

```console
$ loom check                # machine health and repository validation
$ loom check --machine      # required tools and selected profile
$ loom check --repo         # read-only syntax, config, and regression checks
$ loom tools outdated --bump # report mise pins with available updates
$ prek run --all-files       # formatting, ShellCheck, and secret scanning
```

Validation disables mise auto-install, so a missing tool fails clearly instead
of changing the machine while it runs. Install the pinned tools first with
`loom tools install`; the validation suite also needs `rustup target add wasm32-wasip1`.

## Safety model

The install path is deliberately conservative:

1. Dry run first. Stow preflight output shows conflicts before links change.
2. Backups by default. Replaced files move to `~/.stow-backup/<timestamp>/`.
3. No adoption. `loom apply --adopt` is rejected so live-home files cannot silently replace tracked files.
4. Named packages only. Inputs are checked against `packages.conf`; runtime-state directories are refused.
5. Isolated tests. Installer and apply tests use validated `/var/tmp/dotfiles-test.*` homes, never the live home.

If a dry run reports a conflict, stop and decide what should be kept. Back up
any real file you want to preserve, resolve the conflict deliberately, then
run the dry run again. Do not use `--no-backup` unless you have an independent,
recoverable backup.

## Documentation

The full documentation index is [`docs/README.md`](docs/README.md):

- [Setup reference](docs/setup.md): repeatable installation sequence for a future machine.
- [Operations and recovery](docs/operations.md): apply changes, update tools, and recover from conflicts.
- [Profiles and commands](docs/reference.md): Loom commands, profiles, environment variables, and paths.
- [Design and safety](docs/design.md): why Stow, profiles, Loom, and desktop rollback are separate.
- [Man pages](docs/man-pages.md): install and use manuals for custom commands.
- [Keymaps](KEYMAPS.md): Neovim, Zellij, Alacritty, Mango, and macOS shortcuts.

## Compatibility notes

> [!NOTE]
> - Bare `loom apply` targets the `common` profile. Select desktop packages explicitly with `--profile linux-desktop` or `--profile macos`.
> - `personal` is optional and may be unavailable in a fresh checkout; private submodules are not required for the common profile.

## Licensing

This repository is licensed under the [MIT License](LICENSE-MIT.txt). Included
upstream projects and private configuration may have separate licenses.
