#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
script="$repo_root/bin/.local/bin/git-checkouts"
test_dir=''

fail() {
    printf 'test failure: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    [[ -n "$test_dir" && -d "$test_dir" && ! -L "$test_dir" ]] || return 0
    local resolved_test_dir=''
    resolved_test_dir="$(realpath "$test_dir")"
    [[ "$resolved_test_dir" == /var/tmp/dotfiles-test.git-checkouts.* ]] ||
        fail "refusing to clean unexpected path: $resolved_test_dir"
    rm -rf -- "$resolved_test_dir"
}
trap cleanup EXIT

assert_file_contains() {
    local file="${1:?file}"
    local expected="${2:?expected}"
    grep -F -e "$expected" "$file" >/dev/null ||
        fail "expected $file to contain: $expected"
}

test_dir="$(mktemp -d /var/tmp/dotfiles-test.git-checkouts.XXXXXX)"
mock_bin="$test_dir/mock-bin"
local_repo="$test_dir/local-repo"
remote_home="$test_dir/remote-home"
ssh_log="$test_dir/ssh.log"
mkdir -p -- "$mock_bin" "$local_repo" "$remote_home"

# The setup phase is the only SSH use under test. The mock runs the streamed
# bootstrap script locally with an isolated remote HOME.
cat >"$mock_bin/ssh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

[[ "${1:-}" == -- ]] && shift
host="${1:?host}"
shift
printf '%s\n' "$host" >> "${MOCK_SSH_LOG:?}"
[[ "${1:-}" == bash && "${2:-}" == -s && "${3:-}" == -- ]] || exit 64
shift 3
env HOME="${MOCK_REMOTE_HOME:?}" bash -s -- "$@"
EOF
chmod +x "$mock_bin/ssh"

git -C "$local_repo" init --quiet
git -C "$local_repo" config user.name 'Git Checkouts Test'
git -C "$local_repo" config user.email git-checkouts-test@example.invalid
printf 'one\n' >"$local_repo/README"
git -C "$local_repo" add README
git -C "$local_repo" commit --quiet -m initial
git -C "$local_repo" remote add origin git@github.com:example/repo.git

if "$script" --host '-oProxyCommand=unsafe' --dry-run >"$test_dir/invalid-host.out" 2>"$test_dir/invalid-host.err"; then
    fail 'option-like SSH host was accepted'
fi
assert_file_contains "$test_dir/invalid-host.err" '--host must be user@host, a safe SSH host alias, or an IPv6 address; it may not begin with dash: -oProxyCommand=unsafe'

if "$script" --host deploy@remote.example --repo "$local_repo" --remote -unsafe --dry-run >"$test_dir/invalid-remote.out" 2>"$test_dir/invalid-remote.err"; then
    fail 'option-like remote name was accepted'
fi
assert_file_contains "$test_dir/invalid-remote.err" '--remote must contain only letters, numbers, dot, underscore, and dash, and may not begin with dash: -unsafe'

PATH="$mock_bin:$PATH" MOCK_REMOTE_HOME="$remote_home" MOCK_SSH_LOG="$ssh_log" \
    "$script" --host deploy@remote.example --repo "$local_repo" --name deploytest --root git
assert_file_contains "$ssh_log" 'deploy@remote.example'

# A rerun recognizes the exact hook ownership marker written by the first run.
PATH="$mock_bin:$PATH" MOCK_REMOTE_HOME="$remote_home" MOCK_SSH_LOG="$ssh_log" \
    "$script" --host deploy@remote.example --repo "$local_repo" --name deploytest --root git

remote_repo_root="$remote_home/git/github.com/deploytest"
remote_git_dir="$remote_repo_root/.bare"
hook="$remote_git_dir/hooks/post-receive"
latest="$remote_repo_root/latest"
owner_marker="$remote_repo_root/.git-checkouts-latest-owner"

run_hook() {
    local sha="${1:?sha}"
    printf '%040d %s refs/heads/checkouts/latest\n' 0 "$sha" | env GIT_DIR="$remote_git_dir" "$hook"
}

fetch_commit() {
    local sha="${1:?sha}"
    git --git-dir="$remote_git_dir" fetch --quiet "$local_repo" "$sha"
}

new_commit() {
    local content="${1:?content}"
    printf '%s\n' "$content" >>"$local_repo/README"
    git -C "$local_repo" add README
    git -C "$local_repo" commit --quiet -m "$content"
    git -C "$local_repo" rev-parse HEAD
}

first_sha="$(git -C "$local_repo" rev-parse HEAD)"
fetch_commit "$first_sha"
run_hook "$first_sha"
[[ -L "$latest" ]] || fail 'initial deployment did not create latest symlink'
assert_file_contains "$owner_marker" 'git-checkouts latest symlink v1'

# A legacy link created before the marker existed is migrated only when it has
# the precise managed run shape and metadata files.
rm -- "$owner_marker"
second_sha="$(new_commit second)"
fetch_commit "$second_sha"
run_hook "$second_sha"
[[ -L "$latest" ]] || fail 'managed legacy latest symlink was not preserved'
assert_file_contains "$owner_marker" 'git-checkouts latest symlink v1'

printf 'foreign marker\n' >"$owner_marker"
third_sha="$(new_commit third)"
fetch_commit "$third_sha"
if run_hook "$third_sha"; then
    fail 'unrecognized latest ownership marker was accepted'
fi
assert_file_contains "$owner_marker" 'foreign marker'
printf 'git-checkouts latest symlink v1\n' >"$owner_marker"

rm -- "$latest"
printf 'do not replace\n' >"$latest"
fourth_sha="$(new_commit fourth)"
fetch_commit "$fourth_sha"
if run_hook "$fourth_sha"; then
    fail 'unmanaged latest file was replaced'
fi
[[ -f "$latest" && ! -L "$latest" ]] || fail 'unmanaged latest file changed type'
assert_file_contains "$latest" 'do not replace'

rm -- "$latest"
mkdir -- "$latest"
fifth_sha="$(new_commit fifth)"
fetch_commit "$fifth_sha"
if run_hook "$fifth_sha"; then
    fail 'unmanaged latest directory was replaced'
fi
[[ -d "$latest" && ! -L "$latest" ]] || fail 'unmanaged latest directory changed type'

rmdir -- "$latest"
unmanaged_target="$remote_home/unmanaged-target"
mkdir -- "$unmanaged_target"
ln -s "$unmanaged_target" "$latest"
sixth_sha="$(new_commit sixth)"
fetch_commit "$sixth_sha"
if run_hook "$sixth_sha"; then
    fail 'unmanaged latest symlink was replaced'
fi
[[ -L "$latest" && "$(readlink "$latest")" == "$unmanaged_target" ]] || fail 'unmanaged latest symlink changed target'

printf 'git-checkouts safety tests: ok\n'
