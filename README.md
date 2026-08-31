# .dotfiles

Personal macOS and Linux workstation configuration managed with [GNU Stow](https://www.gnu.org/software/stow/) and [mise](https://mise.jdx.dev/). Stow links configuration from this repository into `$HOME`; mise installs the pinned command-line tools.

`loom` is the command-line interface for installing, applying, checking, and maintaining the configuration. `mise` is the tool registry; shell integrations, Neovim tooling, CI checks, and Worktrunk use its managed binaries.

## Quick start

Use this on a new macOS or Linux machine. The bootstrap script downloads the current `main` branch, installs missing foundational tools, installs mise when needed, applies the `common` profile, and installs `loom` in `~/.local/bin`.

Review [`bootstrap.sh`](bootstrap.sh) before running the streamed installer:

```console
curl --proto '=https' --tlsv1.2 -LsSf \
  https://raw.githubusercontent.com/pesap/.dotfiles/main/bootstrap.sh \
  | sh -s -- --profile common
```

The command changes your home directory and may prompt before replacing existing files. Replaced files are backed up under `~/.stow-backup/<timestamp>/`. It may use `sudo` to install missing system prerequisites; it does not need `sudo` when those prerequisites are already installed.

Install the locked versions from the mise manifest:

```sh
"$HOME/.local/bin/loom" tools install
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
"$HOME/.local/bin/loom" check --machine
```

The check succeeds when required dependencies and the selected profile are available. Optional tools may still be reported as missing. Use the absolute path until a new Bash or Zsh shell loads the configuration that adds `~/.local/bin` and mise-managed tools to `PATH`.

## Disposable Linux installation tests

Podman is used as a disposable test harness, not as a mise-managed workstation
runtime. Each run creates a new container with an isolated home directory and
removes that container on exit. Existing Podman containers are not stopped or
pruned.

Run a full fresh-machine benchmark from the repository checkout:

```sh
mise run dotfiles:test:fresh
```

Benchmark setup over pre-existing shell and Alacritty files:

```sh
mise run dotfiles:test:existing
```

Run the same full benchmark across Ubuntu, Debian, Fedora, Arch, and openSUSE:

```sh
mise run dotfiles:test:matrix
```

The tasks include locked mise tool installation and use the current checkout.
For a faster configuration-only run, omit `--with-tools` when invoking the
script directly:

```sh
./scripts/test-podman.sh --scenario fresh --distro ubuntu
```

To exercise the public bootstrap URL instead of the current checkout, select
release mode:

```sh
./scripts/test-podman.sh --source release --scenario fresh --distro ubuntu
```

The full tool run also starts a clean interactive Bash with no profile files,
loads the installed `.bashrc`, and verifies every expected mise-managed command
resolves through `PATH`. It therefore tests Bash-only machines without relying
on Zsh. The benchmark reports prerequisite, bootstrap or setup, mise,
repository-check, and reapply durations. When NetworkManager is available, the harness passes its
active non-Tailscale DNS servers to the container so parallel downloads do not
funnel through a Tailscale DNS forwarder. Override that selection with a
comma-separated list such as `DOTFILES_TEST_DNS=1.1.1.1,8.8.8.8`. Without
NetworkManager, Podman selects the DNS configuration normally. Container images
can be overridden with `DOTFILES_TEST_<DISTRO>_IMAGE`; use immutable image
digests for reproducible CI runs.

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
./bin/.local/bin/loom setup --local --dry-run --profile common
```

The preview does not change your home directory. Apply the profile after reviewing it:

```sh
./bin/.local/bin/loom setup --local --profile common
```

Install or update the locked tools:

```sh
./bin/.local/bin/loom tools install
```

Run the repository checks through the global mise task:

```sh
mise run dotfiles:check
```

Check both the machine and repository:

```sh
./bin/.local/bin/loom check
```

Use `loom check --machine` for only the installed-machine check or `loom check --repo` for repository validation. Run the formatting and secret checks separately when needed. Hook executables
are installed by mise:

```sh
./bin/.local/bin/loom tools install && prek run --all-files
```

## Profiles

Profiles are defined in [`packages.conf`](packages.conf):

| Profile | Includes |
| --- | --- |
| `common` | Shell, terminal, editor, tools, Pi, helper scripts, and private personal configuration when the submodule is available. |
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
| `loom tools install` | Install the locked tool versions from the mise manifest. |
| `loom tools outdated` | Report available tool updates without installing them. |
| `loom profiles` | List supported profiles. |
| `loom version` | Show the checkout version. |

## Safety and limits

- Read the `--dry-run` output before applying a profile.
- Setup backs up replaced files under `~/.stow-backup/<timestamp>/`.
- `loom apply` refuses `--adopt`; existing files are not copied into the repository.
- Runtime state under `~/.rustup`, `~/.cargo`, and `~/.local/share/mise` is not tracked.
- Public defaults and private provider configuration are separated; see [Private configuration](docs/private-configuration.md).
- `loom desktop` requires a clean worktree. It runs smoke checks and rolls back when the checks fail or the confirmation gate expires.
- The streamed installer follows `main`. For a reproducible tagged install, set both `INSTALLER_VERSION` and `INSTALLER_SHA256`; see [`bootstrap.sh`](bootstrap.sh).

## Further reading

- [Project workflows](docs/project-workflows.md) — Herdr project picker, Worktrunk worktrees, and safe synchronization.
- [Private configuration](docs/private-configuration.md) — private providers, identities, and secrets boundary.
- [Keymaps](KEYMAPS.md) — Neovim, Herdr, Mango, Alacritty, and macOS shortcuts.
- [Neovim configuration](nvim/.config/nvim/README.md) — structure, plugins, LSP, and key mappings.
- [`packages.conf`](packages.conf) — profile package allowlist.
- [`loom`](bin/.local/bin/loom) — command implementation and help text.

## License

This repository is licensed under the [MIT License](LICENSE-MIT.txt). Included upstream projects and private configuration may have separate licenses.
