# .dotfiles

Personal macOS and Linux workstation configuration managed with [mise](https://mise.jdx.dev/). Mise applies configuration files and installs the pinned command-line tools.

`mise` is the registry and provisioning interface; shell integrations, Neovim tooling, CI checks, and Worktrunk use its managed binaries.

## New machine setup

Install mise and bootstrap the repository in one command. Mise detects the
operating system automatically and applies the matching configuration:

```console
curl -LsSf https://pikki.cc/install.sh | sh
```

The installer installs mise, clones or updates the dotfiles checkout, and
applies common and platform-specific dotfiles. It may use `sudo` to install
declared system packages. Existing conflicting files are left untouched. To
overwrite them explicitly:

```sh
curl -LsSf https://pikki.cc/install.sh | sh -s -- --force
```

After the checkout exists, initialize and apply private configuration when
needed:

```sh
git submodule update --init personal && mise -C ~/.dotfiles -E personal bootstrap --only dotfiles --yes
```

Private files are kept in the flat `personal/` submodule and mapped to their
home-directory locations by `mise/config.personal.toml`. See
[Private configuration](docs/private-configuration.md) for the layout and
secret-handling rules.

The checked-in lockfile covers Linux x64, macOS Intel, and macOS Apple Silicon.
It records platform-specific download URLs, checksums, and provenance. Refresh
it from this checkout with:

```sh
mise lock --global --platform linux-x64,macos-arm64,macos-x64
```

This downloads the configured tools, including Pi, and can take several minutes.

Check the installed machine:

```sh
mise bootstrap status
```

The check succeeds when required dependencies and the selected mise environment are available. Use the absolute path until a new Bash or Zsh shell loads the configuration that adds `~/.local/bin` and mise-managed tools to `PATH`.

Mise activation is shell-specific: Bash loads `.bashrc` and Zsh loads `.zshrc`.
The configuration does not assume Zsh, so Bash-only machines and containers use
Bash activation normally.

## Existing checkout

Run these commands from the repository root. Preview changes before applying them:

```sh
mise -C . bootstrap --dry-run
```

The preview does not change your home directory. Apply all configured bootstrap steps after reviewing it:

```sh
mise -C . bootstrap --yes
```

When you are already in the `.dotfiles` directory, apply only dotfile changes:

```sh
mise bootstrap dotfiles apply --force
```

Install or update the locked tools only:

```sh
mise -C . install --locked
```

Check the complete bootstrap state:

```sh
mise -C . bootstrap status
```

Hook executables are installed by mise:

```sh
mise -C . run hooks
```

## Platform environments

The common tool registry is in [`mise.toml`](mise.toml); shared dotfiles,
bootstrap packages, and tasks are in [`mise/config.toml`](mise/config.toml).
Use the explicit platform environment from the repository checkout:

```sh
mise -C ~/.dotfiles -E macos bootstrap --yes
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
| `mise bootstrap dotfiles apply --force` | Apply dotfile changes and overwrite conflicts. |
| `mise bootstrap status` | Show complete machine bootstrap state. |
| `mise install --locked` | Install the pinned tool registry. |
| `mise run hooks` | Run all repository hooks. |
| `mise doctor` | Diagnose the mise installation. |

## Safety and limits

- Read the `mise bootstrap --dry-run` output before applying configuration.
- Mise refuses to replace dotfile conflicts unless explicitly forced.
- Runtime state under `~/.rustup`, `~/.cargo`, and `~/.local/share/mise` is not tracked.
- Public defaults and private provider configuration are separated; see [Private configuration](docs/private-configuration.md).

## Further reading

- [Project workflows](docs/project-workflows.md) — Herdr project picker, Worktrunk worktrees, and safe synchronization.
- [Private configuration](docs/private-configuration.md) — private providers, identities, and secrets boundary.
- [Keymaps](KEYMAPS.md) — Neovim, Herdr, Mango, Alacritty, and macOS shortcuts.
- [Neovim configuration](nvim/README.md) — structure, plugins, LSP, and key mappings.


## License

This repository is licensed under the [MIT License](LICENSE-MIT.txt). Included upstream projects and private configuration may have separate licenses.
