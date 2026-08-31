#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
if [[ ! -f "$repo_root/personal/.gitconfig" ]]; then
    printf 'git sync tests: skipped (private personal package unavailable)\n'
    exit 0
fi

test_dir="$(mktemp -d /var/tmp/dotfiles-test.git-worktree-sync.XXXXXX)"

cleanup() {
    local status=$?
    trap - EXIT HUP INT TERM
    if [[ -n "${test_dir:-}" && -d "$test_dir" && ! -L "$test_dir" ]]; then
        local resolved=''
        resolved="$(realpath "$test_dir")"
        case "$resolved" in
        /var/tmp/dotfiles-test.git-worktree-sync.*) rm -rf -- "$resolved" ;;
        *)
            printf 'refusing to clean unexpected path: %s\n' "$resolved" >&2
            status=1
            ;;
        esac
    fi
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

fail() {
    printf 'test failure: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local file="${1:?file}"
    local expected="${2:?expected}"
    grep -F -e "$expected" "$file" >/dev/null ||
        fail "expected $file to contain: $expected"
}

assert_not_contains() {
    local file="${1:?file}"
    local unexpected="${2:?unexpected}"
    if grep -F -e "$unexpected" "$file" >/dev/null; then
        fail "did not expect $file to contain: $unexpected"
    fi
}

mock_bin="$test_dir/mock-bin"
primary="$test_dir/primary"
remote="$test_dir/origin.git"
updater="$test_dir/updater"
caller="$test_dir/caller"
empty="$test_dir/empty"
integrated="$test_dir/integrated"
keep="$test_dir/keep"
wt_log="$test_dir/wt.log"
mkdir -p -- "$mock_bin"

export GIT_CONFIG_GLOBAL="$test_dir/gitconfig"
git config --global user.name 'Worktree Sync Test'
git config --global user.email worktree-sync-test@example.invalid
sync_alias="$(git -C "$repo_root/personal" config --file .gitconfig --get alias.sync)" ||
    fail 'could not read the configured git sync alias'
rm_merged_alias="$(git -C "$repo_root/personal" config --file .gitconfig --get alias.rm-merged)" ||
    fail 'could not read the configured git rm-merged alias'
git config --global alias.sync "$sync_alias"
git config --global alias.rm-merged "$rm_merged_alias"

cat >"$mock_bin/wt" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >>"${WT_LOG:?}"
if [[ "${1:-}" == -C ]]; then
    shift 2
fi

case "${1:-} ${2:-}" in
'list --format=json')
    printf '%s\n' "${WT_JSON:?}"
    ;;
'remove --foreground')
    branch="${3:?branch}"
    case "$branch" in
    empty)
        git -C "${PRIMARY:?}" worktree remove --force "${EMPTY:?}"
        ;;
    integrated)
        git -C "${PRIMARY:?}" worktree remove --force "${INTEGRATED:?}"
        ;;
    *)
        printf 'unexpected removal target: %s\n' "$branch" >&2
        exit 64
        ;;
    esac
    ;;
*)
    printf 'unexpected wt invocation: %s\n' "$*" >&2
    exit 64
    ;;
esac
EOF
chmod +x "$mock_bin/wt"

# The primary worktree tracks origin/main. A separate clone advances the remote
# so the sync command must fetch and fast-forward without switching worktrees.
git init --bare --quiet "$remote"
git init --quiet "$primary"
git -C "$primary" branch -M main
printf 'initial\n' >"$primary/file"
git -C "$primary" add file
git -C "$primary" commit --quiet -m initial
git -C "$primary" remote add origin "$remote"
git -C "$primary" push --quiet --set-upstream origin main
git --git-dir="$remote" symbolic-ref HEAD refs/heads/main

git clone --quiet "$remote" "$updater"
printf 'remote update\n' >>"$updater/file"
git -C "$updater" add file
git -C "$updater" commit --quiet -m remote-update
git -C "$updater" push --quiet origin main

# A deleted upstream with unmerged local work must survive cleanup.
git -C "$primary" switch --quiet -c stale main
printf 'stale local work\n' >>"$primary/file"
git -C "$primary" add file
git -C "$primary" commit --quiet -m stale-local-work
git -C "$primary" push --quiet origin stale
git -C "$primary" switch --quiet main
git -C "$primary" push --quiet origin --delete stale
git -C "$primary" fetch --quiet --prune origin

git -C "$primary" worktree add --quiet -b caller "$caller" main
git -C "$primary" worktree add --quiet -b empty "$empty" main
git -C "$primary" worktree add --quiet -b integrated "$integrated" main
git -C "$primary" worktree add --quiet -b keep "$keep" main
printf 'caller-only change\n' >"$caller/untracked"

export PATH="$mock_bin:$PATH"
export PRIMARY="$primary" EMPTY="$empty" INTEGRATED="$integrated" WT_LOG="$wt_log"
export WT_JSON='{
  "schema": 2,
  "items": [
    {"branch":"main","worktree":{"path":"PRIMARY","main":true,"changes":{"staged":false,"modified":false,"untracked":false,"renamed":false,"deleted":false,"conflicted":false}},"display":{"state":"is_main"}},
    {"branch":"caller","worktree":{"path":"CALLER","main":false,"changes":{"staged":false,"modified":false,"untracked":true,"renamed":false,"deleted":false,"conflicted":false}},"display":{"state":"empty"}},
    {"branch":"empty","worktree":{"path":"EMPTY","main":false,"changes":{"staged":false,"modified":false,"untracked":false,"renamed":false,"deleted":false,"conflicted":false}},"display":{"state":"empty"}},
    {"branch":"integrated","worktree":{"path":"INTEGRATED","main":false,"changes":{"staged":false,"modified":false,"untracked":false,"renamed":false,"deleted":false,"conflicted":false}},"display":{"state":"integrated"}},
    {"branch":"gone-upstream","worktree":{"path":"GONE","main":false,"changes":{"staged":false,"modified":false,"untracked":false,"renamed":false,"deleted":false,"conflicted":false}},"display":{"state":"ahead"}}
  ]
}'
# Replace placeholders without interpreting the JSON as shell code.
WT_JSON=${WT_JSON//PRIMARY/$primary}
WT_JSON=${WT_JSON//CALLER/$caller}
WT_JSON=${WT_JSON//EMPTY/$empty}
WT_JSON=${WT_JSON//INTEGRATED/$integrated}
WT_JSON=${WT_JSON//GONE/$test_dir/gone}
export WT_JSON
: >"$WT_LOG"

# Sync runs from the primary worktree. A dirty linked caller is preserved,
# while clean integrated/empty siblings are removed in the foreground.
(
    cd "$primary"
    git sync >"$test_dir/success.out"
)
assert_contains "$wt_log" 'list --format=json'
assert_contains "$wt_log" 'remove --foreground empty'
assert_contains "$wt_log" 'remove --foreground integrated'
assert_not_contains "$wt_log" 'gone-upstream'
[[ -d "$caller" ]] || fail 'caller worktree was removed'
[[ ! -d "$empty" ]] || fail 'empty worktree was not removed'
[[ ! -d "$integrated" ]] || fail 'integrated worktree was not removed'
[[ -d "$keep" ]] || fail 'unrelated worktree was removed'
[[ "$(git -C "$primary" rev-parse HEAD)" == "$(git -C "$primary" rev-parse origin/main)" ]] ||
    fail 'primary worktree was not fast-forwarded'
git -C "$primary" show-ref --verify --quiet refs/heads/stale ||
    fail 'unmerged gone-upstream branch was deleted'

# Updating a dirty primary is refused before Worktrunk cleanup starts.
printf 'do not overwrite\n' >>"$primary/file"
if (
    cd "$primary"
    git sync >"$test_dir/dirty.out" 2>"$test_dir/dirty.err"
); then
    fail 'dirty primary worktree was accepted'
fi
assert_contains "$test_dir/dirty.err" 'worktree is dirty; refusing to pull'
git -C "$primary" restore -- file

# A schema change fails closed rather than silently selecting the wrong fields.
if (
    cd "$primary"
    WT_JSON='{"schema":1,"items":[]}' git sync >"$test_dir/schema.out" 2>"$test_dir/schema.err"
); then
    fail 'Worktrunk schema 1 was accepted'
fi
assert_contains "$test_dir/schema.err" 'unsupported Worktrunk JSON schema'

printf 'git sync tests: ok\n'
