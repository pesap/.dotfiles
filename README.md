# .dotfiles

Personal macOS and Linux workstation configuration managed with [mise](https://mise.jdx.dev/). Mise applies configuration files and installs the pinned command-line tools.

`mise` is the registry and provisioning interface; shell integrations, Neovim tooling, CI checks, and Worktrunk use its managed binaries.

## New machine setup

Install mise and bootstrap the repository in one command. Mise detects the
operating system automatically and applies the matching configuration:

```console
curl --proto '=https' --tlsv1.2 -LsSf https://mise.run | sh && MISE_AUTO_ENV=1 "$HOME/.local/bin/mise" bootstrap --from https://github.com/pesap/.dotfiles.git --from-dir "$HOME/.dotfiles" --yes
```

Mise installs the configured tools, applies common and platform-specific
dotfiles, and installs the shell configuration. It may use `sudo` to install
declared system packages. Review the dry run first by replacing `--yes` with
`--dry-run`.

After the checkout exists, apply private configuration explicitly when needed:

```sh
mise -E personal bootstrap --yes
```

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

## Spark deployment

Sparkrun is project-scoped because it deploys to a specific Spark environment. It
is managed by that project's `mise.toml`, not by this workstation manifest. From
the Spark deployment checkout:

```sh
mise install --locked
```

Check the configured cluster without starting a workload:

```sh
mise run spark-status
```

Deploy a validated recipe when you are ready to start a workload:

```sh
mise run spark-deploy -- recipes/example.yaml
```

## Existing checkout

Run these commands from the repository root. Preview changes before applying them:

```sh
mise -C . bootstrap --dry-run
```

The preview does not change your home directory. Apply the configuration after reviewing it:

```sh
mise -C . bootstrap --yes
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

The common registry is in [`mise.toml`](mise.toml); its native fragments live in
[`mise/conf.d/`](mise/conf.d/). Use the explicit platform environment when
applying from the global mise configuration:

```sh
mise -E macos bootstrap --yes
mise -E linux bootstrap --yes
```

The common dotfiles are declared in [`mise.toml`](mise.toml). Linux, macOS, and private configuration are separate mise environments. Apply private configuration explicitly with `mise -E personal bootstrap --yes` when the private submodule is available.

## Mise commands

Run `mise help bootstrap` or `mise COMMAND --help` for current options.

| Command | Purpose |
| --- | --- |
| `mise bootstrap` | Provision packages, tools, and dotfiles. |
| `mise bootstrap dotfiles status` | Show dotfile ownership and drift. |
| `mise bootstrap status` | Show complete machine bootstrap state. |
| `mise install --locked` | Install the pinned tool registry. |
| `mise run hooks` | Run all repository hooks. |
| `mise doctor` | Diagnose the mise installation. |

## Safety and limits

- Read the `mise bootstrap --dry-run` output before applying configuration.
- Mise refuses to replace dotfile conflicts unless explicitly forced.
- Runtime state under `~/.rustup`, `~/.cargo`, and `~/.local/share/mise` is not tracked.
- Public defaults and private provider configuration are separated; see [Private configuration](docs/private-configuration.md).
- `mise run desktop:apply` requires a clean worktree. It runs smoke checks and rolls back when the checks fail or the confirmation gate expires.

## Further reading

- [Project workflows](docs/project-workflows.md) — Herdr project picker, Worktrunk worktrees, and safe synchronization.
- [Private configuration](docs/private-configuration.md) — private providers, identities, and secrets boundary.
- [Keymaps](KEYMAPS.md) — Neovim, Herdr, Mango, Alacritty, and macOS shortcuts.
- [Neovim configuration](nvim/README.md) — structure, plugins, LSP, and key mappings.


## License

This repository is licensed under the [MIT License](LICENSE-MIT.txt). Included upstream projects and private configuration may have separate licenses.
