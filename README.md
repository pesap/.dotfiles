# Dotfiles

Cross-platform Linux/macOS dotfiles using GNU Stow and mise.

Clone the repository, inspect the dry run, and then apply a named profile:

```sh
git clone https://github.com/pesap/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh --local --dry-run --profile common
./install.sh --local --profile common
```

Profiles are `common`, `linux-desktop` (common + Linux/Mango/Waybar), and
`macos` (common + Sketchybar/skhd/yabai and optional personal configuration).
Use `./install.sh --list-profiles` or `--profile NAME`; common is the safe
noninteractive default. [packages.conf](packages.conf) is the authoritative
package allowlist used by the installer, `restow`, and the health check.
Private submodules are optional.

The OS package manager provides system dependencies and mise; mise installs
user CLI tools from `mise/.config/mise/config.toml`; Stow installs config
packages. Rustup/Cargo state (`~/.rustup`, `~/.cargo`) and mise's installed
artifacts (`~/.local/share/mise`) are mutable runtime state and are never
stored in or traversed by Stow. The CLI tools previously installed with Cargo
are reproducibly managed by mise.

Install pinned tools, then run the read-only validation suite:

```sh
mise install
rustup target add wasm32-wasip1
dotfiles validate
```

`dotfiles validate` checks shell, Zsh, JSON, TOML, Neovim Lua, Mango, Zellij,
the Zellij plugin build and checked-in artifact, isolated installer/CLI
regressions, and whitespace. It disables mise auto-install so validation cannot install
missing tools as a side effect. `prek run --all-files` remains the formatting,
ShellCheck, and secret-scanning gate and may fix files.

Useful maintenance commands:

```sh
dotfiles-healthcheck
dotfiles outdated --bump
restow --dry-run --profile common
restow --profile common
```

`restow` accepts only packages declared in `packages.conf`, always completes a
Stow preflight first, and deliberately does not support `--adopt`. Installer
and restow tests use validated `/var/tmp/dotfiles-test.*` homes; neither test
path targets the live home directory.

## Compatibility changes

- The obsolete `pil` and `pil.cmd` launchers were removed. Invoke `pi`
  directly.
- `restow --adopt` was removed because adopting can overwrite repository
  content with live-home files. Use the dry run to identify conflicts, back up
  the real file explicitly, and resolve it before restowing.
- Bare `restow` now targets only the `common` profile. Select desktop packages
  with `--profile linux-desktop` or `--profile macos`.
