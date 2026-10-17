#!/usr/bin/env bash
set -Eeuo pipefail
export PROJECT_PICKER_CACHE=0

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
jq_path=$(command -v jq)
fzf_path=$(command -v fzf)
test_dir=$(mktemp -d /var/tmp/dotfiles-test.project.XXXXXX)
test_dir=$(cd -- "$test_dir" && pwd -P)

cleanup() {
    status=$?
    cleanup_status=0
    trap - EXIT HUP INT TERM
    if [[ -d "$test_dir" && ! -L "$test_dir" ]]; then
        logical_test_dir="$(cd "$test_dir" && pwd -L)"
        resolved_test_dir="$(cd "$test_dir" && pwd -P)"
        case "$logical_test_dir" in
        /var/tmp/dotfiles-test.project.*/*) cleanup_status=1 ;;
        /var/tmp/dotfiles-test.project.* | /private/var/tmp/dotfiles-test.project.*)
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

mkdir -p "$test_dir/home/dev/alpha" "$test_dir/home/work/beta/docs" \
    "$test_dir/home/sandbox/gamma" "$test_dir/home/worktrees" \
    "$test_dir/home/.dotfiles" "$test_dir/home/elsewhere/recent" \
    "$test_dir/home/pinned folder" "$test_dir/home/hidden/.private-project" \
    "$test_dir/home/.cache/r2x" "$test_dir/home/.config" "$test_dir/home/.local/bin" \
    "$test_dir/home/runtime" "$test_dir/fake-bin" "$test_dir/git-template"
cat >"$test_dir/project_paths" <<'EOF'
# Exact paths and immediate children of explicitly configured roots.
~/.dotfiles
~/pinned folder
~/hidden/.private-project
~/dev/*
~/work/*
~/missing
~/.dotfiles/
EOF
export PROJECT_PATHS_FILE="$test_dir/project_paths"

worktree_base_dir="$test_dir/home/dev/worktree project \"quoted\""
worktree_path="$test_dir/home/worktrees/worktree-project/feature"
mkdir -p "$worktree_base_dir" "$(dirname "$worktree_path")"
git -c init.defaultBranch=main init --quiet --template="$test_dir/git-template" "$worktree_base_dir"
git -C "$worktree_base_dir" config user.name 'Test User'
git -C "$worktree_base_dir" config user.email 'test@example.invalid'
printf 'worktree base\n' >"$worktree_base_dir/README.md"
git -C "$worktree_base_dir" add README.md
git -C "$worktree_base_dir" -c commit.gpgsign=false commit --quiet --message initial
git -C "$worktree_base_dir" worktree add --quiet -b feature "$worktree_path" HEAD
# Even Git repositories are excluded when they are outside the allowlist.
git -c init.defaultBranch=main init --quiet --template="$test_dir/git-template" \
    "$test_dir/home/elsewhere/recent"

cat >"$test_dir/fake-bin/zoxide" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-} ${2:-}" == 'query --list' ]] || exit 2
printf '%s\n' "$HOME/.cache" "$HOME/.cache/r2x" "$HOME/.config" "$HOME/.local/bin" \
    "$HOME/elsewhere/recent" "$HOME/work/beta/docs" "$HOME/worktrees/worktree-project/feature"
EOF
cat >"$test_dir/fake-bin/fzf" <<'EOF'
#!/usr/bin/env bash
head -n 1
EOF

cat >"$test_dir/fake-bin/herdr" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"${HERDR_TEST_RESULT:?}"
EOF

chmod +x "$test_dir/fake-bin/fzf" "$test_dir/fake-bin/herdr" "$test_dir/fake-bin/zoxide"

paths=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    "$repo_root/bin/project-dirs")

[[ "$(printf '%s\n' "$paths" | grep -c '^')" == 6 ]]
[[ "${paths%%$'\n'*}" == "$test_dir/home/work/beta" ]]
grep -Fxq "$test_dir/home/pinned folder" <<<"$paths"
grep -Fxq "$test_dir/home/hidden/.private-project" <<<"$paths"
grep -Fxq "$test_dir/home/.dotfiles" <<<"$paths"
grep -Fxq "$test_dir/home/dev/alpha" <<<"$paths"
grep -Fxq "$test_dir/home/work/beta" <<<"$paths"
grep -Fxq "$worktree_base_dir" <<<"$paths"
for excluded in .cache .cache/r2x .config .local/bin elsewhere/recent; do
    if grep -Fxq "$test_dir/home/$excluded" <<<"$paths"; then
        printf 'project-dirs: zoxide added a folder outside project_paths: %s\n' "$excluded" >&2
        exit 1
    fi
done
# Explicit pins are authoritative. This is not a cache-directory blacklist.
printf '%s\n' "$test_dir/home/.cache" >"$test_dir/cache-project_paths"
cache_paths=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    PROJECT_PATHS_FILE="$test_dir/cache-project_paths" "$repo_root/bin/project-dirs")
[[ "$cache_paths" == "$test_dir/home/.cache" ]]
# An empty allowlist stays empty regardless of the zoxide database.
: >"$test_dir/empty-project_paths"
empty_paths=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    PROJECT_PATHS_FILE="$test_dir/empty-project_paths" "$repo_root/bin/project-dirs")
[[ -z "$empty_paths" ]]
if grep -Fxq "$worktree_path" <<<"$paths"; then
    printf 'project-dirs: exposed a Worktrunk worktree path instead of the main checkout\n' >&2
    exit 1
fi

if grep -Fxq "$test_dir/home/sandbox/gamma" <<<"$paths"; then
    printf 'project-dirs: scanned a root that is not in project_paths\n' >&2
    exit 1
fi

# Symlink aliases and directories inside a repository resolve to one project.
ln -s "$test_dir/home/dev/alpha" "$test_dir/home/alpha-alias"
printf '%s\n' "$test_dir/home/alpha-alias" "$worktree_path/subdir" >>"$PROJECT_PATHS_FILE"
mkdir -p "$worktree_path/subdir"
alias_paths=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    "$repo_root/bin/project-dirs")
[[ "$alias_paths" == "$paths" ]]

# Shared normalization preserves caller directory state, including logical paths.
(
    # shellcheck source=bin/project-paths.sh
    source "$repo_root/bin/project-paths.sh"
    cd -- "$test_dir/home/alpha-alias"
    original_dir=$PWD
    original_oldpwd=${OLDPWD-}
    project_resolve_path "$test_dir/home/pinned folder"
    [[ "$project_path" == "$test_dir/home/pinned folder" ]]
    [[ "$PWD" == "$original_dir" && "${OLDPWD-}" == "$original_oldpwd" ]]
    project_resolve_path "$test_dir/home/alpha-alias"
    [[ "$project_path" == "$test_dir/home/dev/alpha" ]]
    [[ "$PWD" == "$original_dir" && "${OLDPWD-}" == "$original_oldpwd" ]]
    if project_resolve_path "$test_dir/no-such-directory"; then
        printf 'project paths: resolved a missing directory\n' >&2
        exit 1
    fi
    [[ "$PWD" == "$original_dir" && "${OLDPWD-}" == "$original_oldpwd" ]]
    [[ "$(pwd -P)" == "$test_dir/home/dev/alpha" ]]
    unset OLDPWD
    project_resolve_path "$test_dir/home/pinned folder"
    [[ "$PWD" == "$original_dir" && "${OLDPWD+x}" != x ]]
)

# Read the same configuration through an installed-style symlink.
ln -s "$repo_root/bin/project-dirs" "$test_dir/fake-bin/project-dirs"
linked_paths=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    "$test_dir/fake-bin/project-dirs")
[[ "$linked_paths" == "$paths" ]]

# An explicit missing configuration is an error, not a silent default.
if HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    PROJECT_PATHS_FILE="$test_dir/no-such-file" "$repo_root/bin/project-dirs" \
    >"$test_dir/missing.out" 2>"$test_dir/missing.err"; then
    printf 'project-dirs: accepted a missing configuration\n' >&2
    exit 1
fi
[[ ! -s "$test_dir/missing.out" ]]
grep -Fq 'cannot read' "$test_dir/missing.err"

# A pinned folder remains usable when its Git metadata is no longer available.
orphaned_checkout="$test_dir/orphaned-checkout"
mkdir -p "$orphaned_checkout"
printf 'gitdir: %s/missing-git-metadata\n' "$test_dir" >"$orphaned_checkout/.git"
printf '%s\n' "$orphaned_checkout" >"$test_dir/orphaned-project_paths"
orphaned_paths=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    PROJECT_PATHS_FILE="$test_dir/orphaned-project_paths" "$repo_root/bin/project-dirs")
[[ "$orphaned_paths" == "$orphaned_checkout" ]] || {
    printf 'project-dirs: hid a pinned folder with unavailable Git metadata\n' >&2
    exit 1
}

selected=$(HOME="$test_dir/home" "$repo_root/bin/project-picker" "$test_dir/home/.dotfiles")
[[ "$selected" == "$test_dir/home/.dotfiles" ]]

name=$("$repo_root/bin/project-name" "$test_dir/home/.dotfiles")
[[ "$name" == dotfiles ]]

selected=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    "$repo_root/bin/project-picker")
[[ "$selected" == "$test_dir/home/work/beta" ]]

env -u HERDR_ENV HOME="$test_dir/home" XDG_RUNTIME_DIR="$test_dir/home/runtime" \
    PATH="$test_dir/fake-bin:$PATH" HERDR_TEST_RESULT="$test_dir/herdr-result" \
    HERDR_PROJECT_NAME="$repo_root/bin/project-name" \
    "$repo_root/bin/herdr-project" "$test_dir/home/.dotfiles"
[[ "$(<"$test_dir/herdr-result")" == '--session dotfiles' ]]

# Git normalization must not split one pinned checkout into unlisted paths.
newline_primary="$test_dir/not-listed"$'\n'"$test_dir/also-not-listed"
newline_checkout="$test_dir/newline-linked-checkout"
mkdir -p "${newline_primary%/*}" "$test_dir/not-listed" "$test_dir/also-not-listed"
git clone --quiet --no-hardlinks --template="$test_dir/git-template" "$worktree_base_dir" "$newline_primary"
git -C "$newline_primary" worktree add --quiet -b newline-case "$newline_checkout" HEAD
printf '%s\n' "$newline_checkout" >"$test_dir/newline-project_paths"
newline_paths=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" \
    PROJECT_PATHS_FILE="$test_dir/newline-project_paths" "$repo_root/bin/project-dirs")
[[ -z "$newline_paths" ]] || {
    printf 'project-dirs: a normalized newline path introduced unlisted candidates\n' >&2
    exit 1
}

# JSON process count stays bounded, rather than growing with the candidate count.
mkdir -p "$test_dir/scale/projects" "$test_dir/scale/sessions"
for ((index = 0; index < 300; index++)); do
    printf -v directory '%s/scale/projects/project-%04d' "$test_dir" "$index"
    mkdir -p "$directory"
    if ((index < 40)); then
        mkdir -p "$test_dir/scale/sessions/$index"
        printf '{"active":0,"workspaces":[{"identity_cwd":"%s"}]}\n' "$directory" \
            >"$test_dir/scale/sessions/$index/session.json"
    fi
done
printf '%s/scale/projects/*\n' "$test_dir" >"$test_dir/scale/project_paths"
# shellcheck disable=SC2016 # jq evaluates $root.
"$jq_path" -cn --arg root "$test_dir/scale/sessions" \
    '{sessions: [range(0;40) | {name: ("session-" + tostring), running: true,
        session_dir: ($root + "/" + tostring)}]}' >"$test_dir/scale/sessions.json"
cat >"$test_dir/fake-bin/jq" <<EOF
#!/usr/bin/env bash
printf 'jq\\n' >>"$test_dir/scale/jq-calls"
exec "$jq_path" "\$@"
EOF
chmod +x "$test_dir/fake-bin/jq"
# shellcheck disable=SC2016 # The child Bash evaluates its positional arguments.
HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" NO_COLOR=1 \
    PROJECT_PATHS_FILE="$test_dir/scale/project_paths" \
    /usr/bin/time -p -o "$test_dir/scale/timing" bash -o pipefail -c '
        "$1/bin/herdr-session-rows" --include-projects <"$2" |
            "$3" --ansi --delimiter="$(printf "\\t")" --with-nth=2 --filter=project-0299 >"$4"
    ' project-picker-scale "$repo_root" "$test_dir/scale/sessions.json" "$fzf_path" \
    "$test_dir/scale/selected"
grep -Fq 'project-0299' "$test_dir/scale/selected"
[[ "$(wc -l <"$test_dir/scale/jq-calls")" -le 4 ]]
awk '$1 == "real" {
    printf "picker candidate load + fzf filter (300 projects, 40 sessions): %.2fs\n", $2
    if ($2 >= 1) exit 1
}' "$test_dir/scale/timing"

printf 'project tests: ok\n'
