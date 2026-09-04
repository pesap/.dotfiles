#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
test_dir=$(mktemp -d /var/tmp/dotfiles-test.worktrunk-herdr.XXXXXX)
test_dir=$(cd -- "$test_dir" && pwd -P)

cleanup() {
    local status=$?
    trap - EXIT HUP INT TERM
    local logical_test_dir resolved_test_dir
    logical_test_dir=$(cd "$test_dir" && pwd -L)
    resolved_test_dir=$(cd "$test_dir" && pwd -P)
    case "$logical_test_dir:$resolved_test_dir" in
    /var/tmp/dotfiles-test.worktrunk-herdr.*:/var/tmp/dotfiles-test.worktrunk-herdr.* | /var/tmp/dotfiles-test.worktrunk-herdr.*:/private/var/tmp/dotfiles-test.worktrunk-herdr.* | /private/var/tmp/dotfiles-test.worktrunk-herdr.*:/private/var/tmp/dotfiles-test.worktrunk-herdr.*)
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

mkdir -p -- "$test_dir/repo" "$test_dir/bin" "$test_dir/worktrees"
git -C "$test_dir/repo" init -q
git -C "$test_dir/repo" config user.name test
git -C "$test_dir/repo" config user.email test@example.invalid
printf 'fixture\n' >"$test_dir/repo/file"
git -C "$test_dir/repo" add file
git -C "$test_dir/repo" commit -qm initial

python3 - "$repo_root/worktrunk/config.toml" \
    "$test_dir/config.toml" "$test_dir" <<'PY'
from pathlib import Path
import sys

source_path, target_path, test_dir = map(Path, sys.argv[1:])
source = source_path.read_text()
old = 'worktree-path = "~/worktrees/{{ repo }}/{{ branch | sanitize_hash }}"'
new = f'worktree-path = "{test_dir}/worktrees/{{{{ repo }}}}/{{{{ branch | sanitize }}}}"'
if old not in source:
    raise SystemExit(f'missing worktree path in {source_path}')
target_path.write_text(source.replace(old, new, 1))
PY

cat >"$test_dir/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail

printf '%s\n' "$*" >>"${HERDR_LOG:?}"
case "$*" in
    "worktree open --cwd ${HERDR_REPO_ROOT:?} --path "*" --focus")
        ;;
    'pane list')
        printf '{"result":{"panes":[{"pane_id":"p-worktree","cwd":"%s/.git/wt/trash/plugin-owned-123 (deleted)"}]}}\n' "${HERDR_REPO_ROOT:?}"
        ;;
    'pane close p-worktree')
        ;;
    *)
        printf 'unexpected herdr invocation: %s\n' "$*" >&2
        exit 1
        ;;
esac
EOF
chmod +x "$test_dir/bin/herdr"

wt_bin=$(command -v wt)
herdr_log="$test_dir/herdr.log"

run_switch() {
    local herdr_env=$1 branch=$2
    if [[ -n $herdr_env ]]; then
        env HERDR_ENV="$herdr_env" PATH="$test_dir/bin:$PATH" \
            WORKTRUNK_CONFIG_PATH="$test_dir/config.toml" HERDR_REPO_ROOT="$test_dir/repo" \
            HERDR_WORKTREE_PATH="$test_dir/worktrees/repo/$branch" HERDR_LOG="$herdr_log" \
            "$wt_bin" -C "$test_dir/repo" switch --create "$branch"
    else
        env -u HERDR_ENV PATH="$test_dir/bin:$PATH" \
            WORKTRUNK_CONFIG_PATH="$test_dir/config.toml" HERDR_REPO_ROOT="$test_dir/repo" \
            HERDR_WORKTREE_PATH="$test_dir/worktrees/repo/$branch" HERDR_LOG="$herdr_log" \
            "$wt_bin" -C "$test_dir/repo" switch --create "$branch"
    fi
}

run_switch '' feature
for _ in {1..20}; do
    [[ $(grep -c '^worktree open ' "$herdr_log" 2>/dev/null || true) -eq 1 ]] && break
    sleep 0.1
done
grep -Fxq -- "worktree open --cwd $test_dir/repo --path $test_dir/worktrees/repo/feature --focus" \
    "$herdr_log"
[[ -d "$test_dir/worktrees/repo/feature" ]]

run_switch 1 plain-herdr
for _ in {1..20}; do
    [[ $(grep -c '^worktree open ' "$herdr_log" 2>/dev/null || true) -eq 2 ]] && break
    sleep 0.1
done
[[ $(grep -c '^worktree open ' "$herdr_log") -eq 2 ]]
[[ -d "$test_dir/worktrees/repo/plain-herdr" ]]

# Direct wt switches must register worktrees even when launched by Herdr's
# Worktrunk plugin. Opening an existing Herdr worktree is idempotent, so the
# hook is safe when the plugin also performs its own handoff.
before_count=$(grep -c '^worktree open ' "$herdr_log")
env HERDR_ENV=1 HERDR_PLUGIN_ID=worktrunk PATH="$test_dir/bin:$PATH" \
    WORKTRUNK_CONFIG_PATH="$test_dir/config.toml" HERDR_REPO_ROOT="$test_dir/repo" \
    HERDR_WORKTREE_PATH="$test_dir/worktrees/repo/plugin-owned" HERDR_LOG="$herdr_log" \
    "$wt_bin" -C "$test_dir/repo" switch --create plugin-owned >/dev/null
for _ in {1..20}; do
    [[ $(grep -c '^worktree open ' "$herdr_log" 2>/dev/null || true) -eq $((before_count + 1)) ]] && break
    sleep 0.1
done
after_count=$(grep -c '^worktree open ' "$herdr_log")
[[ "$after_count" == $((before_count + 1)) ]]
[[ -d "$test_dir/worktrees/repo/plugin-owned" ]]

# The remove hook closes panes whose cwd is the removed worktree, including
# removals launched by Herdr's Worktrunk plugin.
env HERDR_ENV=1 HERDR_PLUGIN_ID=worktrunk PATH="$test_dir/bin:$PATH" \
    WORKTRUNK_CONFIG_PATH="$test_dir/config.toml" HERDR_REPO_ROOT="$test_dir/repo" \
    HERDR_WORKTREE_PATH="$test_dir/worktrees/repo/plugin-owned" HERDR_LOG="$herdr_log" \
    "$wt_bin" -C "$test_dir/repo" -y remove --foreground plugin-owned >/dev/null
for _ in {1..20}; do
    grep -Fxq 'pane close p-worktree' "$herdr_log" && break
    sleep 0.1
done
grep -Fxq 'pane close p-worktree' "$herdr_log"
[[ ! -d "$test_dir/worktrees/repo/plugin-owned" ]]

printf 'worktrunk/herdr integration tests: ok\n'
