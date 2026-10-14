#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d /var/tmp/dotfiles-test.herdr-remote.XXXXXX)

cleanup() {
    status=$?
    cleanup_status=0
    trap - EXIT HUP INT TERM
    if [[ -d "$test_dir" && ! -L "$test_dir" ]]; then
        logical_test_dir=$(cd "$test_dir" && pwd -L)
        resolved_test_dir=$(cd "$test_dir" && pwd -P)
        expected_private_dir="/private${test_dir}"
        case "$logical_test_dir" in
        /var/tmp/dotfiles-test.herdr-remote.*) ;;
        *) cleanup_status=1 ;;
        esac
        if [[ "$resolved_test_dir" != "$test_dir" && "$resolved_test_dir" != "$expected_private_dir" ]]; then
            cleanup_status=1
        fi
        if [[ "$logical_test_dir" == "$test_dir" && "$cleanup_status" -eq 0 ]]; then
            rm -rf -- "$logical_test_dir"
        else
            cleanup_status=1
        fi
    else
        cleanup_status=1
    fi
    if ((cleanup_status)); then
        printf 'refusing to clean unexpected test path: %s\n' "$test_dir" >&2
        status=1
    fi
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$test_dir/home/.ssh" "$test_dir/bin"
cat >"$test_dir/home/.ssh/config" <<'EOF'
Host kestrel yampa # compute aliases
    User psanchez

Host github.com github.nrel.gov gitlabssh.naerm.team
    User git

Host *.internal
    User psanchez

Host yampa
    User psanchez
EOF

cat >"$test_dir/bin/ssh" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == -G ]]; then
    host=''
    while (($#)); do
        case "$1" in
            -G) shift ;;
            -F) shift 2 ;;
            *) host=$1; shift ;;
        esac
    done
    case "$host" in
        github.com | github.nrel.gov | gitlabssh.naerm.team) printf 'user git\n' ;;
        *) printf 'user psanchez\n' ;;
    esac
    exit 0
fi
printf '%s\n' "$@" >"${HERDR_TEST_RESULT:?}"
exit "${HERDR_TEST_SSH_EXIT:-0}"
EOF

cat >"$test_dir/bin/fzf" <<'EOF'
#!/usr/bin/env bash
cat >"${HERDR_TEST_CANDIDATES:?}"
[[ "${HERDR_TEST_CANCEL:-0}" != 1 ]] || exit 130
grep -Fx -- "${HERDR_TEST_PICK:?}" "$HERDR_TEST_CANDIDATES"
EOF

cat >"$test_dir/bin/herdr" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${HERDR_TEST_RESULT:?}"
EOF

cat >"$test_dir/bin/uname" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${HERDR_TEST_PLATFORM:?}"
EOF

cat >"$test_dir/bin/open" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${HERDR_TEST_LAUNCH_RESULT:?}"
EOF

cat >"$test_dir/bin/alacritty" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" >"${HERDR_TEST_LAUNCH_RESULT:?}"
EOF
chmod +x "$test_dir/bin/ssh" "$test_dir/bin/fzf" "$test_dir/bin/herdr" \
    "$test_dir/bin/uname" "$test_dir/bin/open" "$test_dir/bin/alacritty"

HERDR_TEST_RESULT="$test_dir/direct-result" PATH="$test_dir/bin:$PATH" \
    "$repo_root/bin/herdr-remote" kestrel
printf '%s\n' -t kestrel herdr >"$test_dir/expected-direct-result"
cmp "$test_dir/expected-direct-result" "$test_dir/direct-result"

cat >"$test_dir/custom-ssh-config" <<'EOF'
Host alternate
    User psanchez
EOF
HERDR_SSH_CONFIG="$test_dir/custom-ssh-config" HERDR_TEST_RESULT="$test_dir/custom-direct-result" \
    PATH="$test_dir/bin:$PATH" "$repo_root/bin/herdr-remote" alternate
printf '%s\n' -t -F "$test_dir/custom-ssh-config" alternate herdr \
    >"$test_dir/expected-custom-direct-result"
cmp "$test_dir/expected-custom-direct-result" "$test_dir/custom-direct-result"

HERDR_TEST_CANDIDATES="$test_dir/custom-candidates" HERDR_TEST_PICK=alternate \
    HERDR_SSH_CONFIG="$test_dir/custom-ssh-config" \
    HERDR_TEST_RESULT="$test_dir/custom-picker-result" HOME="$test_dir/home" \
    PATH="$test_dir/bin:$PATH" "$repo_root/bin/herdr-remote"
printf 'alternate\n' >"$test_dir/expected-custom-candidates"
cmp "$test_dir/expected-custom-candidates" "$test_dir/custom-candidates"
printf '%s\n' -t -F "$test_dir/custom-ssh-config" alternate herdr \
    >"$test_dir/expected-custom-picker-result"
cmp "$test_dir/expected-custom-picker-result" "$test_dir/custom-picker-result"

HERDR_TEST_CANDIDATES="$test_dir/candidates" HERDR_TEST_PICK=yampa \
    HERDR_TEST_RESULT="$test_dir/picker-result" HOME="$test_dir/home" \
    PATH="$test_dir/bin:$PATH" "$repo_root/bin/herdr-remote"
printf 'kestrel\nyampa\n' >"$test_dir/expected-candidates"
cmp "$test_dir/expected-candidates" "$test_dir/candidates"
printf '%s\n' -t yampa herdr >"$test_dir/expected-picker-result"
cmp "$test_dir/expected-picker-result" "$test_dir/picker-result"

if HERDR_TEST_CANCEL=1 HERDR_TEST_CANDIDATES="$test_dir/cancel-candidates" \
    HERDR_TEST_PICK=yampa HERDR_TEST_RESULT="$test_dir/cancel-result" \
    HOME="$test_dir/home" PATH="$test_dir/bin:$PATH" \
    "$repo_root/bin/herdr-remote"; then
    :
else
    printf 'herdr-remote: Ctrl+C cancellation should exit successfully\n' >&2
    exit 1
fi
[[ ! -e "$test_dir/cancel-result" ]]
if HERDR_TEST_CANCEL=1 HERDR_TEST_CANDIDATES="$test_dir/cancel-terminal-candidates" \
    HERDR_TEST_PICK=yampa HERDR_TEST_RESULT="$test_dir/cancel-terminal-result" \
    HOME="$test_dir/home" PATH="$test_dir/bin:$PATH" \
    "$repo_root/bin/herdr-remote-terminal" >"$test_dir/cancel-terminal-output"; then
    :
else
    printf 'herdr-remote-terminal: Ctrl+C cancellation should exit successfully\n' >&2
    exit 1
fi
[[ ! -s "$test_dir/cancel-terminal-output" ]]
[[ ! -e "$test_dir/cancel-terminal-result" ]]

launcher_home="$test_dir/home with \"quote; printf injected"
HERDR_TEST_PLATFORM=Darwin HERDR_TEST_LAUNCH_RESULT="$test_dir/macos-launch-result" \
    HOME="$launcher_home" PATH="$test_dir/bin:$PATH" \
    "$repo_root/bin/herdr-remote-launch"
printf '%s\n' -na Alacritty --args --command /bin/zsh -lic \
    "exec \"\$1\"" herdr-remote-terminal \
    "$launcher_home/.dotfiles/bin/herdr-remote-terminal" \
    >"$test_dir/expected-macos-launch-result"
cmp "$test_dir/expected-macos-launch-result" "$test_dir/macos-launch-result"

HERDR_TEST_PLATFORM=Linux HERDR_TEST_LAUNCH_RESULT="$test_dir/linux-launch-result" \
    HOME="$launcher_home" PATH="$test_dir/bin:$PATH" \
    "$repo_root/bin/herdr-remote-launch"
printf '%s\n' --command /bin/zsh -lic \
    "exec \"\$1\"" herdr-remote-terminal \
    "$launcher_home/.dotfiles/bin/herdr-remote-terminal" \
    >"$test_dir/expected-linux-launch-result"
cmp "$test_dir/expected-linux-launch-result" "$test_dir/linux-launch-result"

if HERDR_TEST_SSH_EXIT=255 HERDR_TEST_RESULT="$test_dir/terminal-ssh-result" \
    HOME="$test_dir/home" PATH="$test_dir/bin:$PATH" \
    "$repo_root/bin/herdr-remote-terminal" kestrel \
    >"$test_dir/terminal-output" <<<''; then
    printf 'herdr-remote-terminal: expected SSH failure to be preserved\n' >&2
    exit 1
else
    terminal_status=$?
fi
[[ "$terminal_status" -eq 255 ]]
grep -Fq 'Herdr remote attach failed' "$test_dir/terminal-output"
printf '%s\n' -t kestrel herdr >"$test_dir/expected-terminal-ssh-result"
cmp "$test_dir/expected-terminal-ssh-result" "$test_dir/terminal-ssh-result"

printf 'herdr remote tests: ok\n'
