# .dotfiles

Personal macOS and Linux workstation configuration managed with [GNU Stow](https://www.gnu.org/software/stow/) and [mise](https://mise.jdx.dev/). Stow links configuration from this repository into `$HOME`; mise installs the pinned command-line tools.

`loom` is the command-line interface for installing, applying, checking, and maintaining the configuration.

## Quick start

Use this on a new macOS or Linux machine. The bootstrap script downloads the current `main` branch, installs missing foundational tools, installs mise when needed, applies the `common` profile, and installs `loom` in `~/.local/bin`.

Review [`bootstrap.sh`](bootstrap.sh) before running the streamed installer:

```console
curl --proto '=https' --tlsv1.2 -LsSf \
  https://raw.githubusercontent.com/pesap/.dotfiles/main/bootstrap.sh \
  | sh -s -- --profile common
```

The command changes your home directory and may prompt before replacing existing files. Replaced files are backed up under `~/.stow-backup/<timestamp>/`. It may use `sudo` to install missing system prerequisites; it does not need `sudo` when those prerequisites are already installed.

Install the versions pinned in the mise manifest:

```sh
"$HOME/.local/bin/loom" tools install
```

This downloads the configured tools, including Pi, and can take several minutes.

Check the installed machine:

```sh
"$HOME/.local/bin/loom" check --machine
```

The check succeeds when required dependencies and the selected profile are available. Optional tools may still be reported as missing. Use the absolute path until a new shell loads the configuration that adds `~/.local/bin` to `PATH`.

## Existing checkout

Run these commands from the repository root. Preview changes before applying them:

```sh
./bin/.local/bin/loom setup --local --dry-run --profile common
```

The preview does not change your home directory. Apply the profile after reviewing it:

```sh
./bin/.local/bin/loom setup --local --profile common
```

Install or update the pinned tools:

```sh
./bin/.local/bin/loom tools install
```

Check both the machine and repository:

```sh
./bin/.local/bin/loom check
```

Use `loom check --machine` for only the installed-machine check or `loom check --repo` for repository validation. Run the formatting and secret checks separately when needed:

```sh
prek run --all-files
```

## Profiles

Profiles are defined in [`packages.conf`](packages.conf):

| Profile | Includes |
| --- | --- |
| `common` | Shell, terminal, editor, tools, Pi, Zellij, helper scripts, and optional personal configuration. |
| `linux-desktop` | `common` plus Linux settings, Mango, and Waybar. |
| `macos` | `common` plus SketchyBar, skhd, and yabai. |

The desktop profiles are available only on their matching operating system. The optional `personal` package is skipped when it is not present.

## Loom commands

Run `loom --help` or `loom COMMAND --help` for the current options.

| Command | Purpose |
| --- | --- |
| `loom setup` | Install or update a profile from a release or an existing checkout. Use `--local` for the current checkout and `--dry-run` to preview it. |
| `loom apply` | Apply packages from an existing checkout. It always runs a Stow preflight and accepts only packages declared in `packages.conf`. |
| `loom check` | Check the installed machine, the repository, or both. |
| `loom desktop` | Apply desktop-window-manager configuration with smoke checks and rollback. It requires a clean Git worktree. |
| `loom tools install` | Install the tool versions pinned in the mise manifest. |
| `loom tools outdated` | Report available tool updates without installing them. |
| `loom profiles` | List supported profiles. |
| `loom version` | Show the checkout version. |

## Safety and limits

- Read the `--dry-run` output before applying a profile.
- Setup backs up replaced files under `~/.stow-backup/<timestamp>/`.
- `loom apply` refuses `--adopt`; existing files are not copied into the repository.
- Runtime state under `~/.rustup`, `~/.cargo`, and `~/.local/share/mise` is not tracked.
- `loom desktop` requires a clean worktree. It runs smoke checks and rolls back when the checks fail or the confirmation gate expires.
- The streamed installer follows `main`. For a reproducible tagged install, set both `INSTALLER_VERSION` and `INSTALLER_SHA256`; see [`bootstrap.sh`](bootstrap.sh).

## Further reading

- [Project workflows](docs/project-workflows.md) — shared project picker and multiplexer launchers.
- [Keymaps](KEYMAPS.md) — Neovim, Zellij, Mango, Alacritty, and macOS shortcuts.
- [Neovim configuration](nvim/.config/nvim/README.md) — structure, plugins, LSP, and key mappings.
- [`packages.conf`](packages.conf) — profile package allowlist.
- [`loom`](bin/.local/bin/loom) — command implementation and help text.

## License

This repository is licensed under the [MIT License](LICENSE-MIT.txt). Included upstream projects and private configuration may have separate licenses.
