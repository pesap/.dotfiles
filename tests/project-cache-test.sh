#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
git_path=$(command -v git)
test_dir=$(mktemp -d /var/tmp/dotfiles-test.project-cache.XXXXXX)
test_dir=$(cd -- "$test_dir" && pwd -P)

cleanup() {
    local status=$? resolved
    trap - EXIT HUP INT TERM
    [[ -d "$test_dir" && ! -L "$test_dir" ]] || exit 1
    resolved=$(cd -- "$test_dir" && pwd -P)
    [[ "$resolved" == "$test_dir" ]] || exit 1
    case "$resolved" in
    /var/tmp/dotfiles-test.project-cache.*/* | /private/var/tmp/dotfiles-test.project-cache.*/*) exit 1 ;;
    /var/tmp/dotfiles-test.project-cache.* | /private/var/tmp/dotfiles-test.project-cache.*) rm -rf -- "$resolved" ;;
    *) exit 1 ;;
    esac
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$test_dir/bin" "$test_dir/home" "$test_dir/template"
base="$test_dir/main checkout"
checkout="$test_dir/linked checkout"
"$git_path" -c init.defaultBranch=main init --quiet --template="$test_dir/template" "$base"
"$git_path" -C "$base" config user.name 'Test User'
"$git_path" -C "$base" config user.email test@example.invalid
"$git_path" -C "$base" -c commit.gpgsign=false commit --quiet --allow-empty --message initial
"$git_path" -C "$base" worktree add --quiet -b feature "$checkout" HEAD
printf '%s\n' "$checkout" >"$test_dir/project_paths"
cat >"$test_dir/bin/git" <<EOF
#!/usr/bin/env bash
set -euo pipefail
printf 'git\\n' >>"$test_dir/git-calls"
[[ "\${PROJECT_CACHE_TEST_FAIL_GIT:-0}" == 0 ]] || exit 1
if [[ -n "\${PROJECT_CACHE_TEST_GATE:-}" ]]; then
    : >"\$PROJECT_CACHE_TEST_GATE.started"
    for _ in {1..200}; do
        [[ -f "\$PROJECT_CACHE_TEST_GATE" ]] && break
        sleep 0.01
    done
    [[ -f "\$PROJECT_CACHE_TEST_GATE" ]] || {
        : >"\$PROJECT_CACHE_TEST_GATE.timed-out"
        exit 1
    }
fi
exec "$git_path" "\$@"
EOF
cat >"$test_dir/bin/date" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$*" == '+%s' ]] || exit 2
printf '%s\n' "${PROJECT_CACHE_TEST_NOW:?}"
EOF
cat >"$test_dir/bin/zoxide" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "$*" == 'query --list' ]] || exit 2
EOF
chmod +x "$test_dir/bin/git" "$test_dir/bin/date" "$test_dir/bin/zoxide"

now=1000
cache_enabled=1
fail_git=0
cache_file="$test_dir/cache/project-picker/worktrees.json"
refresh_gate=''
run_cached() {
    env HOME="$test_dir/home" XDG_CACHE_HOME="$test_dir/cache" \
        PROJECT_PICKER_CACHE="$cache_enabled" PROJECT_CACHE_TEST_NOW="$now" \
        PROJECT_CACHE_TEST_FAIL_GIT="$fail_git" PROJECT_CACHE_TEST_GATE="$refresh_gate" \
        PROJECT_PATHS_FILE="$test_dir/project_paths" PATH="$test_dir/bin:$PATH" "$@"
}
run_dirs() {
    run_cached "$repo_root/bin/project-dirs"
}

# A cold lookup records only a verified Git mapping, with private permissions.
[[ "$(run_dirs)" == "$base" ]]
[[ -f "$cache_file" ]] || {
    printf 'project cache: no persistent mapping was created\n' >&2
    exit 1
}
jq -e --arg checkout "$checkout" --arg base "$base" \
    '.version == 1 and any(.entries[]; .checkout == $checkout and .primary == $base and .checked_at == 1000)' \
    "$cache_file" >/dev/null
[[ "$(find "$cache_file" -type f -perm 0600)" == "$cache_file" ]]
[[ "$(find "${cache_file%/*}" -type d -perm 0700)" == "${cache_file%/*}" ]]
[[ "$(wc -l <"$test_dir/git-calls")" -eq 1 ]]

# Warm lookup uses the mapping without invoking Git, even when Git is unavailable.
fail_git=1
[[ "$(run_dirs)" == "$base" ]]
[[ "$(wc -l <"$test_dir/git-calls")" -eq 1 ]]
fail_git=0

# A changed .git link invalidates the mapping immediately.
IFS= read -r git_link <"$checkout/.git"
printf '%s/.\n' "$git_link" >"$checkout/.git"
[[ "$(run_dirs)" == "$base" ]]
[[ "$(wc -l <"$test_dir/git-calls")" -eq 2 ]]

# The allowlist is always fresh, never served from the worktree cache.
: >"$test_dir/project_paths"
[[ -z "$(run_dirs)" ]]
[[ "$(wc -l <"$test_dir/git-calls")" -eq 2 ]]
printf '%s\n' "$checkout" >"$test_dir/project_paths"

# Expired entries and corrupt cache data are replaced using Git.
now=1301
[[ "$(run_dirs)" == "$base" ]]
[[ "$(wc -l <"$test_dir/git-calls")" -eq 3 ]]
printf 'invalid JSON\n' >"$cache_file"
[[ "$(run_dirs)" == "$base" ]]
[[ "$(wc -l <"$test_dir/git-calls")" -eq 4 ]]
jq -e '.version == 1 and (.entries | length) == 1' "$cache_file" >/dev/null

# Older hits return before a blocked background Git refresh completes.
now=1312
refresh_gate="$test_dir/refresh-release"
[[ "$(run_dirs)" == "$base" ]]
for _ in {1..100}; do
    [[ -f "$refresh_gate.started" ]] && break
    sleep 0.01
done
[[ -f "$refresh_gate.started" && ! -f "$refresh_gate.timed-out" ]] || {
    printf 'project cache: refresh was not detached from the picker\n' >&2
    exit 1
}
: >"$refresh_gate"
for _ in {1..100}; do
    if jq -e 'any(.entries[]; .checked_at == 1312)' "$cache_file" >/dev/null; then
        break
    fi
    sleep 0.01
done
jq -e 'any(.entries[]; .checked_at == 1312)' "$cache_file" >/dev/null
[[ "$(wc -l <"$test_dir/git-calls")" -eq 5 ]]
refresh_gate=''

# Running state is not cached even when the Git mapping is reused.
mkdir -p "$test_dir/session"
jq -cn --arg path "$checkout" '{active:0,workspaces:[{identity_cwd:$path}]}' \
    >"$test_dir/session/session.json"
fail_git=1
for running in true false; do
    fixture=$(jq -cn --arg dir "$test_dir/session" --argjson running "$running" \
        '{sessions:[{name:"cached-session",session_dir:$dir,running:$running}]}')
    rows=$(printf '%s\n' "$fixture" | run_cached env NO_COLOR='' TERM=xterm-256color \
        "$repo_root/bin/herdr-session-rows" --include-projects)
    if [[ "$running" == true ]]; then
        grep -Fq $'\033[32m'"$base"$'\033[0m' <<<"$rows"
    else
        grep -Fq $'\033[90m'"$base"$'\033[0m' <<<"$rows"
    fi
done
[[ "$(wc -l <"$test_dir/git-calls")" -eq 5 ]]
fail_git=0

# Opting out bypasses both disk reads and writes.
printf 'cache-disabled-marker\n' >"$cache_file"
cache_enabled=0
[[ "$(run_dirs)" == "$base" ]]
[[ "$(wc -l <"$test_dir/git-calls")" -eq 6 ]]
IFS= read -r unchanged_cache <"$cache_file"
[[ "$unchanged_cache" == cache-disabled-marker ]]

# Cache setup failures and symlinked cache files never block discovery or replace user files.
cache_enabled=1
printf 'keep-cache-root\n' >"$test_dir/cache-as-file"
[[ "$(run_cached env XDG_CACHE_HOME="$test_dir/cache-as-file" "$repo_root/bin/project-dirs")" == "$base" ]]
IFS= read -r preserved_root <"$test_dir/cache-as-file"
[[ "$preserved_root" == keep-cache-root ]]
mkdir -p "$test_dir/symlink-cache/project-picker"
printf 'keep-cache-target\n' >"$test_dir/cache-target"
ln -s "$test_dir/cache-target" "$test_dir/symlink-cache/project-picker/worktrees.json"
[[ "$(run_cached env XDG_CACHE_HOME="$test_dir/symlink-cache" "$repo_root/bin/project-dirs")" == "$base" ]]
IFS= read -r preserved_target <"$test_dir/cache-target"
[[ "$preserved_target" == keep-cache-target ]]
[[ -L "$test_dir/symlink-cache/project-picker/worktrees.json" ]]

# Future timestamps cannot make cached mappings immortal after a clock change.
[[ "$(run_dirs)" == "$base" ]]
jq '.entries[].checked_at = 9000' "$cache_file" >"$test_dir/future-cache"
mv "$test_dir/future-cache" "$cache_file"
fail_git=1
[[ "$(run_dirs)" == "$checkout" ]]
fail_git=0

# Concurrent cold writers only publish complete JSON snapshots.
printf 'invalid JSON\n' >"$cache_file"
run_dirs >"$test_dir/concurrent-1.out" &
first_pid=$!
run_dirs >"$test_dir/concurrent-2.out" &
second_pid=$!
concurrent_status=0
wait "$first_pid" || concurrent_status=$?
wait "$second_pid" || concurrent_status=$?
[[ "$concurrent_status" -eq 0 ]]
[[ "$(<"$test_dir/concurrent-1.out")" == "$base" && "$(<"$test_dir/concurrent-2.out")" == "$base" ]]
jq -e '.version == 1 and (.entries | length) == 1' "$cache_file" >/dev/null
[[ -z "$(find "${cache_file%/*}" -name '.worktrees.*')" ]]

# The complete .git link identifies a repository, including metadata-path newlines.
metadata_prefix="$test_dir/git-metadata"$'\n'
metadata_a="$metadata_prefix/repo-a"
metadata_b="$metadata_prefix/repo-b"
primary_a="$test_dir/primary-a"
primary_b="$test_dir/primary-b"
shared_checkout="$test_dir/shared-checkout"
mkdir -p "$metadata_prefix"
for metadata in "$metadata_a" "$metadata_b"; do
    "$git_path" clone --quiet --bare --no-hardlinks --template="$test_dir/template" "$base" "$metadata"
done
"$git_path" -C "$metadata_a" worktree add --quiet "$primary_a" main
"$git_path" -C "$metadata_b" worktree add --quiet "$primary_b" main
"$git_path" -C "$metadata_a" worktree add --quiet -b cached-a "$shared_checkout" main
printf '%s\n' "$shared_checkout" >"$test_dir/project_paths"
[[ "$(run_dirs)" == "$primary_a" ]]
"$git_path" -C "$metadata_a" worktree move "$shared_checkout" "$test_dir/previous-checkout"
"$git_path" -C "$metadata_b" worktree add --quiet -b cached-b "$shared_checkout" main
[[ "$(run_dirs)" == "$primary_b" ]] || {
    printf 'project cache: reused a mapping after the Git link changed beyond its first line\n' >&2
    exit 1
}
printf '%s\n' "$checkout" >"$test_dir/project_paths"

# A missing primary checkout invalidates a warm mapping immediately.
mv "$base" "$test_dir/moved-main-checkout"
[[ "$(run_dirs)" == "$checkout" ]]

printf 'project cache tests: ok\n'
