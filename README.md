# .dotfiles

Personal macOS and Linux configuration managed with GNU Stow and mise.

## Install

The bootstrap installs prerequisites, applies the shared profile, and places
`loom` and the local helper scripts in `~/.local/bin`:

```console
curl --proto '=https' --tlsv1.2 -LsSf \
  https://raw.githubusercontent.com/pesap/.dotfiles/main/bootstrap.sh \
  | sh -s -- --profile common

```

To check the status:

```
loom check
```

For an existing checkout, inspect the dry run first:

```console
./bin/.local/bin/loom setup --local --dry-run --profile common
./bin/.local/bin/loom setup --local --profile common
loom tools install
loom check
```

The desktop profiles are `linux-desktop` and `macos`:

```console
loom setup --local --dry-run --profile linux-desktop
loom setup --local --profile macos
```

## Loom commands

```text
loom setup       install or update a profile
loom apply       apply packages from the checkout
loom check       check the machine and repository
loom desktop     apply desktop configuration with rollback protection
loom tools       install or inspect mise-managed tools
loom profiles    list profiles
```

Use `loom --help` and `loom COMMAND --help` for the current options.

`loom apply` always runs a Stow preflight. It accepts only packages listed in
`packages.conf` and does not support `--adopt`. Desktop changes require a clean
Git worktree, run smoke checks, and can roll back to the last-known-good state.

## Profiles

`packages.conf` is the allowlist used by setup, apply, and check.

- `common`: shell, terminal, editor, tools, Pi, Zellij, and helper scripts.
- `linux-desktop`: common configuration plus Mango, Waybar, and Linux settings.
- `macos`: common configuration plus SketchyBar, skhd, yabai, and optional personal configuration.

## Local tools

The `bin/.local/bin` package installs the small commands used by this setup,
including:

- `loom` for setup and maintenance;
- `aclui` for a simpler interface to `getfacl` and `setfacl`;
- `git-checkouts`, `pr-digest`, and `zession` for GitHub, deployment, and terminal workflows;
- Waybar, Mango, wallpaper, clipboard, and macOS helpers.

Run a command with `--help` when it provides help. Tools that depend on Linux
or macOS services are intentionally not useful on every machine.

## Validation

```console
loom check --machine
loom check --repo
prek run --all-files
```

Validation is read-only and disables mise auto-install. Install the pinned tools
with `loom tools install` first. The full validation suite also needs:

```console
rustup target add wasm32-wasip1
```

## Safety

- Read the dry-run output before applying a profile.
- Replaced files are backed up under `~/.stow-backup/<timestamp>/`.
- Runtime state under `~/.rustup`, `~/.cargo`, and `~/.local/share/mise` is not tracked.
- Installer and apply tests use isolated `/var/tmp/dotfiles-test.*` homes.

## Reference

- [Keymaps](KEYMAPS.md) for Neovim, Zellij, Mango, Alacritty, and macOS shortcuts.
- `packages.conf` for the profile/package list.
- `loom --help` for the command reference.

## License

This repository is licensed under the [MIT License](LICENSE-MIT.txt). Included
upstream projects and private configuration may have separate licenses.
