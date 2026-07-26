# Dotfiles

Cross-platform Linux/macOS dotfiles using GNU Stow and mise.

```sh
curl -sSfL https://raw.githubusercontent.com/pesap/.dotfiles/0.0.2/bootstrap.sh | sh
./install.sh --local --profile common
```

Profiles are `common`, `linux-desktop` (common + Linux/Mango/Waybar), and
`macos` (common + Sketchybar/skhd/yabai and optional personal configuration).
Use `./install.sh --list-profiles` or `--profile NAME`; common is the safe
noninteractive default. Private submodules are optional.

The OS package manager provides system dependencies and mise; mise installs
user CLI tools from `mise/.config/mise/config.toml`; Stow installs config
packages. Rustup/Cargo state (`~/.rustup`, `~/.cargo`) and mise's installed
artifacts (`~/.local/share/mise`) are mutable runtime state and are never
stored in or traversed by Stow. The CLI tools previously installed with Cargo
are now reproducibly managed by mise. Run `mise install` and then:

```sh
dotfiles-healthcheck
prek run --all-files
shellcheck -x bootstrap.sh install.sh programs.sh bin/.local/bin/dotfiles-healthcheck bin/.local/bin/restow
```

The health check prints all missing tools and exits nonzero on required
failures. Dry runs do not modify the home directory or invoke package managers.
The installer also refuses to back up or move Cargo, Rustup, or mise runtime
state.
