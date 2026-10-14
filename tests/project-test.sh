#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_dir=$(mktemp -d /var/tmp/dotfiles-test.project.XXXXXX)

cleanup() {
    status=$?
    cleanup_status=0
    trap - EXIT HUP INT TERM
    if [[ -d "$test_dir" && ! -L "$test_dir" ]]; then
        logical_test_dir="$(cd "$test_dir" && pwd -L)"
        resolved_test_dir="$(cd "$test_dir" && pwd -P)"
        case "$logical_test_dir" in
        /var/tmp/dotfiles-test.project.*/*) cleanup_status=1 ;;
        /var/tmp/dotfiles-test.project.*)
            case "$resolved_test_dir" in
            /var/tmp/dotfiles-test.project.*/* | /private/var/tmp/dotfiles-test.project.*/*) cleanup_status=1 ;;
            /var/tmp/dotfiles-test.project.* | /private/var/tmp/dotfiles-test.project.*) rm -rf -- "$logical_test_dir" ;;
            *) cleanup_status=1 ;;
            esac
            ;;
        *) cleanup_status=1 ;;
        esac
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

mkdir -p "$test_dir/home/dev/alpha" "$test_dir/home/work/beta" \
    "$test_dir/home/sandbox/gamma" "$test_dir/home/worktrees" \
    "$test_dir/home/.dotfiles" "$test_dir/home/runtime" "$test_dir/fake-bin"

cat >"$test_dir/fake-bin/fd" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
for argument in "$@"; do
    case "$argument" in
        "$HOME/dev") printf '%s\n' "$HOME/dev/alpha/" ;;
        "$HOME/work") printf '%s\n' "$HOME/work/beta/" ;;
        "$HOME/sandbox") printf '%s\n' "$HOME/sandbox/gamma/" ;;
        "$HOME") printf '%s\n' "$HOME/dev/" "$HOME/work/" "$HOME/sandbox/" "$HOME/worktrees/" ;;
    esac
done
EOF
cat >"$test_dir/fake-bin/fzf" <<'EOF'
#!/usr/bin/env bash
head -n 1
EOF

cat >"$test_dir/fake-bin/herdr" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"${HERDR_TEST_RESULT:?}"
EOF

chmod +x "$test_dir/fake-bin/fd" "$test_dir/fake-bin/fzf" "$test_dir/fake-bin/herdr"

paths=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    PROJECT_ROOTS="$test_dir/home/dev:$test_dir/home/work" \
    PROJECT_PATHS="$test_dir/home/.dotfiles" \
    "$repo_root/bin/project-dirs")

[[ "$(printf '%s\n' "$paths" | grep -c '^')" == 3 ]]
grep -Fxq "$test_dir/home/.dotfiles" <<<"$paths"
grep -Fxq "$test_dir/home/dev/alpha/" <<<"$paths"
grep -Fxq "$test_dir/home/work/beta/" <<<"$paths"

default_paths=$(env -u PROJECT_ROOTS -u HERDR_PROJECT_ROOTS \
    HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    PROJECT_PATHS="$test_dir/home/.dotfiles" "$repo_root/bin/project-dirs")
grep -Fxq "$test_dir/home/dev/" <<<"$default_paths"
grep -Fxq "$test_dir/home/work/" <<<"$default_paths"
grep -Fxq "$test_dir/home/sandbox/" <<<"$default_paths"
grep -Fxq "$test_dir/home/dev/alpha/" <<<"$default_paths"
grep -Fxq "$test_dir/home/work/beta/" <<<"$default_paths"
grep -Fxq "$test_dir/home/sandbox/gamma/" <<<"$default_paths"
if grep -Fxq "$test_dir/home/worktrees/" <<<"$default_paths"; then
    printf 'project-dirs: included the worktrees storage directory\n' >&2
    exit 1
fi

selected=$(HOME="$test_dir/home" "$repo_root/bin/project-picker" "$test_dir/home/.dotfiles")
[[ "$selected" == "$test_dir/home/.dotfiles" ]]

name=$("$repo_root/bin/project-name" "$test_dir/home/.dotfiles")
[[ "$name" == dotfiles ]]

selected=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    PROJECT_ROOTS="$test_dir/home/dev:$test_dir/home/work" \
    PROJECT_PATHS="$test_dir/home/.dotfiles" \
    "$repo_root/bin/project-picker")
[[ "$selected" == "$test_dir/home/.dotfiles" ]]

env -u HERDR_ENV HOME="$test_dir/home" XDG_RUNTIME_DIR="$test_dir/home/runtime" \
    PATH="$test_dir/fake-bin:$PATH" HERDR_TEST_RESULT="$test_dir/herdr-result" \
    HERDR_PROJECT_NAME="$repo_root/bin/project-name" \
    "$repo_root/bin/herdr-project" "$test_dir/home/.dotfiles"
[[ "$(<"$test_dir/herdr-result")" == '--session dotfiles' ]]

printf 'project tests: ok\n'
