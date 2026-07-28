#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
install_script="$repo_root/install.sh"
apply_script="$repo_root/scripts/apply.sh"
test_dir=''

fail() {
    printf 'test failure: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    [[ -n "$test_dir" && -d "$test_dir" && ! -L "$test_dir" ]] || return 0
    local resolved_test_dir
    resolved_test_dir="$(cd "$test_dir" && pwd -P)"
    [[ "$resolved_test_dir" == /var/tmp/dotfiles-test.* ]] || fail "refusing to clean unexpected path: $resolved_test_dir"
    rm -rf -- "$resolved_test_dir"
}
trap cleanup EXIT

test_dir="$(mktemp -d /var/tmp/dotfiles-test.install-restow.XXXXXX)"
home_dir="$test_dir/home"
source_dir="$test_dir/source"
mock_bin="$test_dir/mock-bin"
mkdir -p -- "$home_dir" "$source_dir" "$mock_bin"

cat >"$source_dir/packages.conf" <<'EOF'
common alacritty atuin bin nvim personal pi starship worktrunk zellij zshrc mise
linux-desktop alacritty atuin bin nvim personal pi starship worktrunk zellij zshrc mise linux mango waybar
macos alacritty atuin bin nvim personal pi starship worktrunk zellij zshrc mise sketchybar skhd yabai
EOF
for package in alacritty atuin bin nvim pi starship worktrunk zellij zshrc mise; do
    mkdir -p -- "$source_dir/$package"
done
mkdir -p -- "$source_dir/alacritty/.config/alacritty"
printf 'live_config_reload = true\n' >"$source_dir/alacritty/.config/alacritty/alacritty.toml"
printf 'shell = "zsh"\n' >"$source_dir/alacritty/.config/alacritty/local.linux.toml"

cat >"$mock_bin/stow" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

dry_run=0
unstow=0
for arg in "$@"; do
    [[ "$arg" == -n ]] && dry_run=1
    [[ "$arg" == -D ]] && unstow=1
done
package="${!#}"
target="${HOME:?}/.config/alacritty/alacritty.toml"
if ((unstow)); then
    rm -f -- "$target"
    exit 0
fi
if ((dry_run)); then
    exit 0
fi
[[ "$package" == alacritty && "${FAIL_STOW:-0}" == 1 ]] && exit 1
exit 0
EOF
chmod +x "$mock_bin/stow"

if env HOME="$home_dir" LOCAL_SOURCE="$source_dir" PATH="$mock_bin:$PATH" \
    sh "$install_script" --local --dry-run --profile common >"$test_dir/install-dry-run.out"; then
    [[ -z "$(find "$home_dir" -mindepth 1 -print -quit)" ]] || fail 'installer dry-run wrote to HOME'
else
    fail 'installer dry-run failed with an isolated HOME'
fi

if env HOME="$home_dir" LOCAL_SOURCE="$source_dir" PATH="$mock_bin:$PATH" \
    sh "$install_script" --local --unknown >"$test_dir/install-unknown.out" 2>"$test_dir/install-unknown.err"; then
    fail 'installer accepted an unknown option'
fi
grep -F -- 'unknown option: --unknown' "$test_dir/install-unknown.err" >/dev/null || fail 'installer unknown-option error changed'

mkdir -p -- "$home_dir/.config/alacritty"
printf 'previous overlay\n' >"$home_dir/.config/alacritty/local.toml"
env HOME="$home_dir" LOCAL_SOURCE="$source_dir" PATH="$mock_bin:$PATH" \
    sh "$install_script" --local --profile common >"$test_dir/install-overlay.out"
[[ -L "$home_dir/.config/alacritty/local.toml" ]] || fail 'installer did not install the Alacritty overlay link'
[[ "$(readlink "$home_dir/.config/alacritty/local.toml")" == "$source_dir/alacritty/.config/alacritty/local.linux.toml" ]] || fail 'installer linked the wrong Alacritty overlay'
overlay_backup="$(find "$home_dir/.stow-backup" -type f -path '*/.config/alacritty/local.toml' -print -quit)"
[[ -n "$overlay_backup" ]] || fail 'installer did not preserve the previous Alacritty overlay'
grep -F -- 'previous overlay' "$overlay_backup" >/dev/null || fail 'Alacritty overlay backup content changed'

ln -s -- "$source_dir/alacritty/.config/alacritty/alacritty.toml" "$home_dir/.config/alacritty/alacritty.toml"
if env HOME="$home_dir" LOCAL_SOURCE="$source_dir" PATH="$mock_bin:$PATH" FAIL_STOW=1 \
    sh "$install_script" --local --profile common >"$test_dir/install-rollback.out" 2>"$test_dir/install-rollback.err"; then
    fail 'installer unexpectedly succeeded after a simulated Stow failure'
fi
[[ -L "$home_dir/.config/alacritty/alacritty.toml" ]] || fail 'installer rollback did not restore prior Stow link'
[[ "$(readlink "$home_dir/.config/alacritty/alacritty.toml")" == "$source_dir/alacritty/.config/alacritty/alacritty.toml" ]] || fail 'installer rollback restored the wrong link'

restow_repo="$test_dir/restow-repo"
restow_home="$test_dir/restow-home"
mkdir -p -- "$restow_repo/pkg" "$restow_home"
printf 'common pkg personal\nlinux-desktop pkg personal\nmacos pkg personal\n' >"$restow_repo/packages.conf"
printf 'configuration\n' >"$restow_repo/pkg/config"
ln -s -- "$restow_repo/pkg/config" "$restow_home/config"

cat >"$mock_bin/stow" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

dry_run=0
unstow=0
for arg in "$@"; do
    [[ "$arg" == -n ]] && dry_run=1
    [[ "$arg" == -D ]] && unstow=1
done
if ((unstow)); then
    rm -f -- "${HOME:?}/config"
    exit 0
fi
((dry_run)) && exit 0
rm -f -- "${HOME:?}/config"
[[ "${FAIL_RESTOW:-0}" == 1 ]] && exit 1
exit 0
EOF
chmod +x "$mock_bin/stow"

env HOME="$restow_home" DOTFILES_DIR="$restow_repo" PATH="$mock_bin:$PATH" \
    bash "$apply_script" --dry-run --profile common >"$test_dir/restow-profile-dry-run.out"
grep -F -- 'Skipping optional package unavailable: personal' "$test_dir/restow-profile-dry-run.out" >/dev/null || fail 'apply did not skip unavailable personal package'
grep -F -- 'Preflight: pkg' "$test_dir/restow-profile-dry-run.out" >/dev/null || fail 'apply skipped the declared package with unavailable personal config'

if env HOME="$restow_home" DOTFILES_DIR="$restow_repo" PATH="$mock_bin:$PATH" \
    bash "$apply_script" --dry-run personal >"$test_dir/restow-personal.err" 2>&1; then
    fail 'apply accepted an explicitly requested unavailable personal package'
fi
grep -F -- 'package not found: personal' "$test_dir/restow-personal.err" >/dev/null || fail 'explicit unavailable personal error changed'

env HOME="$restow_home" DOTFILES_DIR="$restow_repo" PATH="$mock_bin:$PATH" \
    bash "$apply_script" --dry-run pkg >"$test_dir/restow-dry-run.out"
[[ -L "$restow_home/config" ]] || fail 'restow dry-run changed the prior link'

if env HOME="$restow_home" DOTFILES_DIR="$restow_repo" PATH="$mock_bin:$PATH" FAIL_RESTOW=1 \
    bash "$apply_script" pkg >"$test_dir/restow-rollback.out" 2>"$test_dir/restow-rollback.err"; then
    fail 'restow unexpectedly succeeded after a simulated Stow failure'
fi
[[ -L "$restow_home/config" ]] || fail 'restow rollback did not restore prior Stow link'
[[ "$(readlink "$restow_home/config")" == "$restow_repo/pkg/config" ]] || fail 'restow rollback restored the wrong link'

if env HOME="$restow_home" DOTFILES_DIR="$restow_repo" PATH="$mock_bin:$PATH" bash "$apply_script" --adopt >/dev/null 2>"$test_dir/restow-adopt.err"; then
    fail 'restow accepted --adopt'
fi
grep -F -- '--adopt is refused' "$test_dir/restow-adopt.err" >/dev/null || fail 'restow adopt rejection changed'

if env HOME="$restow_home" DOTFILES_DIR="$restow_repo" PATH="$mock_bin:$PATH" bash "$apply_script" unlisted >/dev/null 2>"$test_dir/restow-unlisted.err"; then
    fail 'restow accepted an undeclared package'
fi
grep -F -- 'package is not declared' "$test_dir/restow-unlisted.err" >/dev/null || fail 'restow allowlist rejection changed'

printf 'install/restow safety tests: ok\n'
