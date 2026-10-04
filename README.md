# .dotfiles

Personal macOS and Linux workstation configuration managed with [mise](https://mise.jdx.dev/). Mise applies configuration files and installs the pinned command-line tools.

`mise` is the registry and provisioning interface; shell integrations, Neovim tooling, CI checks, and Worktrunk use its managed binaries.

## New machine setup

On an existing machine with `~/.config/herdr` or `~/.config/worktrunk` as a
directory symlink into this checkout, stop and follow the
[runtime-state migration instructions](docs/project-workflows.md#worktrunk-and-herdr)
before running the installer.

Install mise and bootstrap the repository in one command. Mise detects the
operating system automatically and applies the matching configuration:

```console
curl -LsSf https://pikki.cc/install.sh | sh
```

The installer installs mise if needed, clones or updates the dotfiles checkout,
then runs the shared and matching platform bootstrap. This applies dotfiles and
installs configured tools and packages. It may use `sudo` to install declared
system packages. Existing conflicting dotfile targets are left untouched. To
overwrite them explicitly:

```sh
curl -LsSf https://pikki.cc/install.sh | sh -s -- --force
```

After the checkout exists, initialize and apply private configuration when
needed. This command uses the default checkout path; substitute your
`DOTFILES_DIR` if you set one:

```sh
git -C ~/.dotfiles submodule update --init personal && mise -C ~/.dotfiles -E personal bootstrap --only dotfiles --yes
```

Private files are kept in the flat `personal/` submodule and mapped to their
home-directory locations by `mise/config.personal.toml`. See
[Private configuration](docs/private-configuration.md) for the layout and
secret-handling rules.

The checked-in lockfile covers Linux x64, macOS Intel, and macOS Apple Silicon.
It records platform-specific download URLs, checksums, and provenance. From the
repository root, refresh it with:

```sh
mise -C . lock --platform linux-x64,macos-arm64,macos-x64
```

This refreshes release metadata, checksums, and URLs for the listed platforms.
It updates this checkout's lockfile but does not install the tools, and can take
several minutes.

The installer defaults to `~/.local/bin/mise` and `~/.dotfiles`. Until a new Bash or Zsh shell loads the configuration that adds `~/.local/bin` to `PATH`, call mise by its absolute path. If you set `MISE_BIN` or `DOTFILES_DIR`, substitute those paths below.

Check the installed machine using the same platform environment as the installer.

macOS:

```sh
"$HOME/.local/bin/mise" -C "$HOME/.dotfiles" -E macos bootstrap status --missing
```

Linux:

```sh
"$HOME/.local/bin/mise" -C "$HOME/.dotfiles" -E linux bootstrap status --missing
```

These commands exit nonzero if any configured bootstrap state is missing.

Mise activation is shell-specific: Bash loads `.bashrc` and Zsh loads `.zshrc`.
The configuration does not assume Zsh, so Bash-only machines and containers use
Bash activation normally.

## Existing checkout

Run the shared bootstrap from the repository root. These commands do not select a platform environment; use the matching `-E` commands in [Platform environments](#platform-environments) for platform-specific dotfiles. Preview first:

```sh
mise -C . bootstrap --dry-run
```

The preview does not change your home directory. If `~/.config/herdr` or `~/.config/worktrunk` is still a directory symlink into this checkout, stop and follow the [runtime-state migration instructions](docs/project-workflows.md#worktrunk-and-herdr) before applying.

After reviewing the preview, apply the shared bootstrap steps:

```sh
mise -C . bootstrap --yes
```

When you are already in the `.dotfiles` directory, preview and apply only shared dotfile changes. Preview first:

```sh
mise -C . bootstrap dotfiles apply --dry-run
```

Apply without forcing replacement of conflicting files:

```sh
mise -C . bootstrap dotfiles apply
```

Mise may prompt before applying. Conflicting files are left untouched unless you explicitly pass `--force`; use it only after reviewing the exact targets and making recoverable backups.

Install or update the locked tools only:

```sh
mise -C . install --locked
```

Check status for the currently selected mise configuration:

```sh
mise -C . bootstrap status
```

Use `-E macos` or `-E linux` to include the corresponding platform environment.

Run the repository hook task through mise:

```sh
mise -C . run hooks
```

## Platform environments

The common tool registry is in [`mise.toml`](mise.toml); shared dotfiles,
bootstrap packages, and tasks are in [`mise/config.toml`](mise/config.toml).
Use the matching explicit environment from the repository checkout. Preview the macOS configuration:

```sh
mise -C ~/.dotfiles -E macos bootstrap --dry-run
```

Apply it after reviewing the preview:

```sh
mise -C ~/.dotfiles -E macos bootstrap --yes
```

For Linux, preview:

```sh
mise -C ~/.dotfiles -E linux bootstrap --dry-run
```

Then apply:

```sh
mise -C ~/.dotfiles -E linux bootstrap --yes
```

Linux, macOS, and private configuration are separate mise environments. Apply
private configuration explicitly with:

```sh
mise -C ~/.dotfiles -E personal bootstrap --only dotfiles --yes
```

The private submodule must be initialized first.

## Mise commands

Run `mise help bootstrap` or `mise COMMAND --help` for current options.

| Command | Purpose |
| --- | --- |
| `mise bootstrap` | Provision packages, tools, and dotfiles. |
| `mise bootstrap dotfiles status` | Show dotfile ownership and drift. |
| `mise bootstrap dotfiles apply` | Apply dotfile changes without overwriting conflicts. |
| `mise bootstrap dotfiles apply --force` | Overwrite conflicting whole-file entries after reviewing and backing up the targets. |
| `mise bootstrap status` | Show aggregate status for the selected configuration. |
| `mise install --locked` | Install the pinned tool registry. |
| `mise run hooks` | Run all repository hooks. |
| `mise doctor` | Diagnose the mise installation. |

## Safety and limits

- Read the dry-run output for the same platform environment and action before applying configuration.
- Existing dotfile conflicts are left untouched unless `--force` is passed.
- Runtime state under `~/.rustup`, `~/.cargo`, and `~/.local/share/mise` is not tracked.
- Public defaults and private provider configuration are separated; see [Private configuration](docs/private-configuration.md).

## Further reading

- [Project workflows](docs/project-workflows.md) — Herdr project picker, Worktrunk worktrees, and safe synchronization.
- [Private configuration](docs/private-configuration.md) — private providers, identities, and secrets boundary.
- [Keymaps](KEYMAPS.md) — Neovim, Herdr, Mango, Alacritty, and macOS shortcuts.
- [Neovim configuration](nvim/README.md) — structure, plugins, LSP, and key mappings.


## License

This repository is licensed under the [MIT License](LICENSE-MIT.txt). Included upstream projects and private configuration may have separate licenses.
