#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
test_dir=$(mktemp -d /var/tmp/dotfiles-test.worktrunk-herdr.XXXXXX)

cleanup() {
    local status=$?
    trap - EXIT HUP INT TERM
    local logical_test_dir resolved_test_dir
    logical_test_dir=$(cd "$test_dir" && pwd -L)
    resolved_test_dir=$(cd "$test_dir" && pwd -P)
    case "$logical_test_dir:$resolved_test_dir" in
    /var/tmp/dotfiles-test.worktrunk-herdr.*:/var/tmp/dotfiles-test.worktrunk-herdr.*)
        [[ -d "$test_dir" && ! -L "$test_dir" ]] || exit 1
        rm -rf -- "$test_dir"
        ;;
    *)
        printf 'refusing to clean unexpected test path: %s\n' "$test_dir" >&2
        status=1
        ;;
    esac
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

mkdir -p -- "$test_dir/bin" "$test_dir/home/start" "$test_dir/home/worktree" "$test_dir/runtime"

cat >"$test_dir/bin/wt" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
if [[ "$*" == 'config shell init zsh' ]]; then
    cat <<'ZSH'
wt() {
    if [[ "${1:-}" == switch ]]; then
        command wt "$@" >/dev/null
        cd -- "${WT_TARGET:?}"
    else
        command wt "$@"
    fi
}
ZSH
else
    printf '%s\n' "$*" >>"${WT_RESULT:?}"
fi
EOF

cat >"$test_dir/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
printf '%s|%s|%s\n' "$PWD" "$*" "${HERDR_ENV:-}" >"${HERDR_RESULT:?}"
EOF
chmod +x "$test_dir/bin/wt" "$test_dir/bin/herdr"

source_file="$repo_root/zshrc/.config/zshrc/30-tools.zsh"
project_namer="$repo_root/bin/.local/bin/project-name"

env -u HERDR_ENV HOME="$test_dir/home" XDG_RUNTIME_DIR="$test_dir/runtime" \
    PATH="$test_dir/bin:$repo_root/bin/.local/bin:$PATH" WT_TARGET="$test_dir/home/worktree" \
    WT_RESULT="$test_dir/wt-result" HERDR_RESULT="$test_dir/herdr-result" \
    HERDR_PROJECT_NAME="$project_namer" \
    zsh -f -c 'cd "$HOME/start"; source "$1"; wt switch --create feature' \
    zsh "$source_file"

grep -Fxq -- 'switch --create feature' "$test_dir/wt-result"
grep -F -- "$test_dir/home/worktree|--session worktree|" "$test_dir/herdr-result" >/dev/null

rm -f -- "$test_dir/herdr-result"
env HERDR_ENV=1 HOME="$test_dir/home" XDG_RUNTIME_DIR="$test_dir/runtime" \
    PATH="$test_dir/bin:$repo_root/bin/.local/bin:$PATH" WT_TARGET="$test_dir/home/worktree" \
    WT_RESULT="$test_dir/wt-result" HERDR_RESULT="$test_dir/herdr-result" \
    HERDR_PROJECT_NAME="$project_namer" \
    zsh -f -c 'cd "$HOME/start"; source "$1"; wt switch --create nested' \
    zsh "$source_file"
[[ ! -e "$test_dir/herdr-result" ]]

grep -Fxq -- 'switch --create nested' "$test_dir/wt-result"
printf 'worktrunk/herdr integration tests: ok\n'
