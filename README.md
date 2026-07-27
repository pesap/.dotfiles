# .dotfiles

Personal macOS and Linux configuration managed with GNU Stow and mise.

## Install

Run this from a shell with `curl` and `sh`. It downloads the latest bootstrap
script from `main`, installs prerequisites, applies the `common` profile, and
installs `loom` under `~/.local/bin`:

```console
curl --proto '=https' --tlsv1.2 -LsSf \
  https://raw.githubusercontent.com/pesap/.dotfiles/main/bootstrap.sh \
  | sh -s -- --profile common
```

Expected result: the shared configuration is linked into your home directory.
The command may prompt before changing existing files.

To check the installed setup, run this after the bootstrap completes:

```console
loom check
```

Expected result: `loom` reports machine and repository checks.

For an existing checkout, run the following commands from the repository root.
Each command is independent; read the dry-run output before applying changes.

Preview the common profile without changing your home directory:

```console
./bin/.local/bin/loom setup --local --dry-run --profile common
```

Apply the common profile after reviewing the preview:

```console
./bin/.local/bin/loom setup --local --profile common
```

Expected result: selected configuration is linked and any replaced files are
backed up under `~/.stow-backup/<timestamp>/`.

Install the pinned mise tools:

```console
loom tools install
```

Expected result: the tool versions in the mise manifest are installed.

The desktop profiles are `linux-desktop` and `macos`. Preview Linux desktop
changes without applying them:

```console
loom setup --local --dry-run --profile linux-desktop
```

Apply the macOS profile:

```console
loom setup --local --profile macos
```

Expected result: the selected desktop configuration is applied with the normal
backup and rollback protections.

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

Run these commands from the repository root. Each command is independent and
read-only unless noted.

Check installed machine dependencies:

```console
loom check --machine
```

Expected result: the machine profile is checked without changing files.

Validate repository contents:

```console
loom check --repo
```

Expected result: shell, configuration, and repository checks pass.

Run the formatting and secret checks:

```console
prek run --all-files
```

Expected result: all local pre-commit checks pass.

Validation disables mise auto-install. Install the pinned tools with `loom tools
install` first. The full validation suite also needs the Rust WASM target:

```console
rustup target add wasm32-wasip1
```

Expected result: Rust installs the target, or reports that it is already
installed.

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
