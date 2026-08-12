#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
bootstrap_script="$repo_root/bootstrap.sh"
test_dir=''

fail() {
    printf 'bootstrap test failure: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    [[ -n "$test_dir" && -d "$test_dir" && ! -L "$test_dir" ]] || return 0
    local logical_test_dir='' resolved_test_dir=''
    logical_test_dir="$(cd "$test_dir" && pwd -L)"
    resolved_test_dir="$(cd "$test_dir" && pwd -P)"
    case "$logical_test_dir" in
    /var/tmp/dotfiles-test.bootstrap-test.*/*) fail "refusing to clean unexpected path: $resolved_test_dir" ;;
    /var/tmp/dotfiles-test.bootstrap-test.*) ;;
    *) fail "refusing to clean unexpected path: $resolved_test_dir" ;;
    esac
    case "$resolved_test_dir" in
    /var/tmp/dotfiles-test.bootstrap-test.*/* | /private/var/tmp/dotfiles-test.bootstrap-test.*/*) fail "refusing to clean unexpected path: $resolved_test_dir" ;;
    /var/tmp/dotfiles-test.bootstrap-test.* | /private/var/tmp/dotfiles-test.bootstrap-test.*) ;;
    *) fail "refusing to clean unexpected path: $resolved_test_dir" ;;
    esac
    rm -rf -- "$logical_test_dir"
}
trap cleanup EXIT

test_dir="$(mktemp -d /var/tmp/dotfiles-test.bootstrap-test.XXXXXX)"
home_dir="$test_dir/home"
source_dir="$test_dir/source"
mock_bin="$test_dir/mock-bin"
mkdir -p -- "$home_dir" "$source_dir" "$mock_bin"

cat >"$source_dir/install.sh" <<'INSTALLER'
#!/bin/sh
set -eu
printf 'installer-version=%s\n' "${INSTALLER_VERSION:-}" >"${INSTALLER_TEST_OUTPUT:?}"
printf 'installer-home=%s\n' "$HOME" >>"${INSTALLER_TEST_OUTPUT:?}"
printf 'installer-mise=%s\n' "$(command -v mise)" >>"${INSTALLER_TEST_OUTPUT:?}"
INSTALLER
chmod +x "$source_dir/install.sh"

cat >"$mock_bin/curl" <<'CURL'
#!/bin/sh
set -eu
output=''
url=''
while [ "$#" -gt 0 ]; do
    case "$1" in
    -o|--output)
        output="$2"
        shift 2
        ;;
    *) url="$1"; shift ;;
    esac
done
[ -n "$output" ] || exit 64
case "$url" in
*/mise-install) cp -- "${MOCK_MISE_INSTALLER_SOURCE:?}" "$output" ;;
*) cp -- "${MOCK_INSTALLER_SOURCE:?}" "$output" ;;
esac
CURL
cat >"$mock_bin/id" <<'ID'
#!/bin/sh
printf '1000\n'
ID
cat >"$mock_bin/sudo" <<'SUDO'
#!/bin/sh
exit 1
SUDO
cat >"$mock_bin/dnf" <<'DNF'
#!/bin/sh
exit 0
DNF
cat >"$mock_bin/mise-install" <<'MISE_INSTALLER'
#!/bin/sh
set -eu
mkdir -p -- "$(dirname "${MISE_INSTALL_PATH:?}")"
printf '#!/bin/sh\nexit 0\n' >"$MISE_INSTALL_PATH"
chmod +x "$MISE_INSTALL_PATH"
MISE_INSTALLER
cat >"$mock_bin/git" <<'GIT'
#!/bin/sh
exit 0
GIT
cat >"$mock_bin/tar" <<'TAR'
#!/bin/sh
exit 0
TAR
cat >"$mock_bin/unzip" <<'UNZIP'
#!/bin/sh
exit 0
UNZIP
cat >"$mock_bin/make" <<'MAKE'
#!/bin/sh
exit 0
MAKE
cat >"$mock_bin/perl" <<'PERL'
#!/bin/sh
exit 0
PERL
for tool in "$mock_bin"/*; do
    chmod +x "$tool"
done

if PATH="$mock_bin:/bin" HOME="$home_dir" \
    DOTFILES_RAW_BASE='https://example.invalid/dotfiles' \
    sh "$bootstrap_script" --local --profile common >"$test_dir/missing-prereqs.out" 2>"$test_dir/missing-prereqs.err"; then
    fail 'bootstrap accepted a missing system prerequisite without administrator access'
fi
grep -F -- 'failed to install system prerequisites; install them with sudo, then rerun bootstrap' "$test_dir/missing-prereqs.err" >/dev/null ||
    fail 'bootstrap did not explain the missing-prerequisite recovery path'

installer_output="$test_dir/installer.out"
PATH="$mock_bin:/usr/bin:/bin" \
    HOME="$home_dir" \
    MOCK_INSTALLER_SOURCE="$source_dir/install.sh" \
    MOCK_MISE_INSTALLER_SOURCE="$mock_bin/mise-install" \
    INSTALLER_TEST_OUTPUT="$installer_output" \
    DOTFILES_RAW_BASE='https://example.invalid/dotfiles' \
    MISE_INSTALL_URL='https://example.invalid/mise-install' \
    sh "$bootstrap_script" --local --profile common

grep -Fxq 'installer-version=main' "$installer_output" ||
    fail 'bootstrap did not pass main to the installer'
grep -Fxq "installer-home=$home_dir" "$installer_output" ||
    fail 'bootstrap changed HOME'
grep -Fxq "installer-mise=$home_dir/.local/bin/mise" "$installer_output" ||
    fail 'bootstrap did not make the user-local mise binary available to the installer'
[[ -x "$home_dir/.local/bin/mise" ]] ||
    fail 'bootstrap did not install mise in the user-local bin directory'

tag_output="$test_dir/tag-installer.out"
tag_sha256="$(sha256sum "$source_dir/install.sh" | awk '{print $1}')"
PATH="$mock_bin:/usr/bin:/bin" \
    HOME="$home_dir" \
    MOCK_INSTALLER_SOURCE="$source_dir/install.sh" \
    MOCK_MISE_INSTALLER_SOURCE="$mock_bin/mise-install" \
    INSTALLER_TEST_OUTPUT="$tag_output" \
    DOTFILES_RAW_BASE='https://example.invalid/dotfiles' \
    MISE_INSTALL_URL='https://example.invalid/mise-install' \
    INSTALLER_VERSION='test-release' \
    INSTALLER_SHA256="$tag_sha256" \
    sh "$bootstrap_script" --local --profile common
grep -Fxq 'installer-version=test-release' "$tag_output" ||
    fail 'bootstrap did not pass an explicitly verified release version to the installer'

if PATH="$mock_bin:/usr/bin:/bin" HOME="$home_dir" \
    MOCK_INSTALLER_SOURCE="$source_dir/install.sh" \
    MOCK_MISE_INSTALLER_SOURCE="$mock_bin/mise-install" \
    DOTFILES_RAW_BASE='https://example.invalid/dotfiles' \
    MISE_INSTALL_URL='https://example.invalid/mise-install' \
    INSTALLER_VERSION='test-release' \
    sh "$bootstrap_script" --local --profile common >"$test_dir/unverified-release.out" 2>"$test_dir/unverified-release.err"; then
    fail 'bootstrap accepted a release without a checksum'
fi
grep -F -- "no installer checksum recorded for version 'test-release'" "$test_dir/unverified-release.err" >/dev/null ||
    fail 'bootstrap did not explain how to verify an unlisted release'

printf 'bootstrap kestrel safety tests: ok\n'
