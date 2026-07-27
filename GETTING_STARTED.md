# Getting started

> Tutorial · Follow this once on a new machine.

This tutorial installs the shared profile first. It leaves window-manager and
bar configuration out of the way until the baseline is healthy.

## Before you begin

You need:

- macOS or Linux;
- a writable home directory;
- `git`, `curl` or `wget`, and a supported system package manager for a fresh-machine bootstrap.

The installer can use Homebrew, `apt-get`, `dnf`, `pacman`, or `zypper` to
install missing prerequisites. If you prefer to control system packages
manually, install GNU Stow, `rsync`, and mise yourself.

## 1. Clone the repository

```console
$ git clone https://github.com/pesap/.dotfiles.git ~/.dotfiles
$ cd ~/.dotfiles
```

Keep the checkout at `~/.dotfiles` unless you plan to set the advanced checkout
path variables for `loom apply` or `loom desktop` yourself.

## 2. Choose a profile

Start with `common` on every platform:

```console
$ ./bin/.local/bin/loom profiles
$ ./bin/.local/bin/loom setup --local --dry-run --profile common
```

The dry run is the important step. It runs Stow's preflight and prints the
links, directories, and backups that would be involved without changing the
home directory.

When the output looks right, apply it:

```console
$ ./bin/.local/bin/loom setup --local --profile common
```

On Linux, add the desktop packages with:

```console
$ ./bin/.local/bin/loom setup --local --dry-run --profile linux-desktop
$ ./bin/.local/bin/loom setup --local --profile linux-desktop
```

On macOS, use:

```console
$ ./bin/.local/bin/loom setup --local --dry-run --profile macos
$ ./bin/.local/bin/loom setup --local --profile macos
```

The macOS profile includes `personal` when that package is present; missing
optional personal configuration is skipped.

## 3. Install pinned tools

The mise manifest is [`mise/.config/mise/config.toml`](mise/.config/mise/config.toml):

```console
$ loom tools install
```

This installs tools into mise's own data directory. It does not put binaries or
caches into the repository and does not make Stow responsible for tool state.

The validation suite builds a Zellij plugin for a WebAssembly target, so add it
once if you will run the full checks:

```console
$ rustup target add wasm32-wasip1
```

## 4. Open a new shell and check the result

The shell package activates mise, Starship, fzf, Navi, Atuin, GitHub CLI,
Direnv, Zoxide, and Cargo when each tool is available. Start a fresh shell so
those hooks load:

```console
$ exec zsh
$ loom check
```

A health-check failure tells you which required command or profile package is
missing. Validation is read-only and disables mise auto-install.

## 5. Make the first change

Edit a source file in the checkout, not the symlinked copy in `$HOME`:

```console
$ nvim ~/.dotfiles/zshrc/.config/zshrc/30-tools.zsh
$ git -C ~/.dotfiles diff
$ loom apply --dry-run --profile common
$ loom apply --profile common
```

For the full maintenance loop, continue with [Operations and recovery](OPERATIONS.md).
