#!/usr/bin/env bash
set -Eeuo pipefail
export PROJECT_PICKER_CACHE=0

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
python3_path=$(python3 -c 'import sys; print(sys.executable)')
test_dir=$(mktemp -d /var/tmp/dotfiles-test.herdr-session.XXXXXX)
test_dir=$(cd -- "$test_dir" && pwd -P)

launcher_pid=''

cleanup() {
    local status=$?
    trap - EXIT HUP INT TERM
    if [[ -n "$launcher_pid" ]]; then
        local client_pid
        if [[ -n "${launcher_runtime:-}" && -s "$launcher_runtime/herdr-project/client" ]]; then
            read -r client_pid <"$launcher_runtime/herdr-project/client"
            kill -TERM "$client_pid" 2>/dev/null || true
        fi
        kill -TERM "$launcher_pid" 2>/dev/null || true
        for _ in {1..20}; do
            kill -0 "$launcher_pid" 2>/dev/null || break
            sleep 0.05
        done
        kill -KILL "$launcher_pid" 2>/dev/null || true
        wait "$launcher_pid" 2>/dev/null || true
    fi
    local logical_test_dir resolved_test_dir
    logical_test_dir=$(cd "$test_dir" && pwd -L)
    resolved_test_dir=$(cd "$test_dir" && pwd -P)
    case "$logical_test_dir:$resolved_test_dir" in
    /var/tmp/dotfiles-test.herdr-session.*:/var/tmp/dotfiles-test.herdr-session.* | /var/tmp/dotfiles-test.herdr-session.*:/private/var/tmp/dotfiles-test.herdr-session.* | /private/var/tmp/dotfiles-test.herdr-session.*:/private/var/tmp/dotfiles-test.herdr-session.*)
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

mkdir -p -- "$test_dir/bin" "$test_dir/runtime/herdr-project"
ln -s "$repo_root/bin/herdr-project" "$test_dir/bin/herdr-project"
cat >"$test_dir/bin/fzf" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
queue=${HERDR_TEST_FZF_QUEUE:?}
if [[ -n "${HERDR_TEST_FZF_READY:-}" ]]; then
    : >"$HERDR_TEST_FZF_READY"
fi
expect_keys=''
had_input=false
for argument in "$@"; do
    if [[ -n "${HERDR_TEST_FZF_READY:-}" && "$argument" == --exit-0 ]]; then
        printf 'fzf --exit-0 defers startup until the input list is complete\n' >&2
        exit 2
    fi
    if [[ "$argument" == --expect=* ]]; then
        expect_keys=${argument#--expect=}
    fi
done
IFS= read -r selected <"$queue"
tail -n +2 "$queue" >"$queue.tmp"
mv "$queue.tmp" "$queue"
while IFS= read -r candidate; do
    had_input=true
    key=${candidate%%$'\t'*}
    if [[ "$key" == "$selected" ]]; then
        if [[ -n "$expect_keys" ]]; then
            action=enter
            if [[ -s "$queue" ]]; then
                IFS= read -r queued_action <"$queue"
                case "$queued_action" in
                    @enter|@q)
                        action=${queued_action#@}
                        tail -n +2 "$queue" >"$queue.tmp"
                        mv "$queue.tmp" "$queue"
                        ;;
                esac
            fi
            printf '%s\n' "$action"
        fi
        printf '%s\n' "$candidate"
        exit 0
    fi
done
if [[ "$had_input" == false ]]; then
    exit 1
fi
exit 130
EOF
cat >"$test_dir/bin/python3" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$python3_path" "\$@"
EOF
cat >"$test_dir/bin/zoxide" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ "${1:-} ${2:-}" == 'query --list' ]] || exit 2
if [[ -n "${HERDR_TEST_DISCOVERY_GATE:-}" ]]; then
    for _ in {1..100}; do
        [[ -f "$HERDR_TEST_DISCOVERY_GATE" ]] && break
        sleep 0.01
    done
    [[ -f "$HERDR_TEST_DISCOVERY_GATE" ]] || {
        printf 'picker did not open while entries were being prepared\n' >&2
        exit 1
    }
fi
printf '%s\n' \
    "$HOME/work/naerm-toolbox" \
    "$HOME/elsewhere/recent-only" \
    "$HOME/.cache" \
    "$HOME/.herdr/worktrees/griddb/docs-mvp-contracts"
EOF
cat >"$test_dir/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${HERDR_TEST_LOG:?}"
if [[ "${1:-}" == --session ]]; then
    trap - INT
    exec python3 - "${HERDR_TEST_CLIENT_LOG:?}" "${2:?}" "${HERDR_TEST_CWD_LOG:?}" <<'PY'
import os
import signal
import sys
import time

signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
with open(sys.argv[1], "a", encoding="utf-8") as client_log:
    client_log.write(f"client {sys.argv[2]}\n")
with open(sys.argv[3], "a", encoding="utf-8") as cwd_log:
    cwd_log.write(f"{sys.argv[2]}\t{os.getcwd()}\n")
while True:
    time.sleep(0.05)
PY
fi
case "${1:-} ${2:-}" in
    'session list')
        cat "${HERDR_TEST_STATE:?}"
        ;;
    'session stop')
        name=${3:?}
        if [[ "${HERDR_TEST_FAIL_STOP:-}" == "$name" ]]; then
            printf 'simulated stop failure for %s\n' "$name" >&2
            exit 1
        fi
        jq --arg name "$name" '.sessions |= map(if .name == $name then .running = false else . end)' \
            "$HERDR_TEST_STATE" >"$HERDR_TEST_STATE.tmp"
        mv "$HERDR_TEST_STATE.tmp" "$HERDR_TEST_STATE"
        ;;
    'session delete')
        name=${3:?}
        jq --arg name "$name" '.sessions |= map(select(.name != $name))' \
            "$HERDR_TEST_STATE" >"$HERDR_TEST_STATE.tmp"
        mv "$HERDR_TEST_STATE.tmp" "$HERDR_TEST_STATE"
        ;;
    *)
        printf 'unexpected Herdr call: %s\n' "$*" >&2
        exit 2
        ;;
esac
EOF
chmod +x "$test_dir/bin/fzf" "$test_dir/bin/herdr" "$test_dir/bin/python3" "$test_dir/bin/zoxide"

export HOME="$test_dir/home"
export XDG_RUNTIME_DIR="$test_dir/runtime"
export PATH="$test_dir/bin:$PATH"
export HERDR_TEST_STATE="$test_dir/sessions.json"
export HERDR_TEST_LOG="$test_dir/herdr.log"
export HERDR_TEST_CLIENT_LOG="$test_dir/herdr-client.log"
export HERDR_TEST_CWD_LOG="$test_dir/herdr-cwd.log"
export HERDR_TEST_FZF_QUEUE="$test_dir/fzf.queue"
export PROJECT_PATHS_FILE="$test_dir/project_paths"
cat >"$PROJECT_PATHS_FILE" <<'EOF'
~/.dotfiles
~/work/*
~/dev/*
EOF
mkdir -p -- "$HOME/.dotfiles" "$HOME/work/naerm-toolbox" "$HOME/elsewhere/recent-only"
new_project_dir="$HOME/work/naerm-toolbox"
recent_project_dir="$HOME/elsewhere/recent-only"
worktree_base_dir="$HOME/dev/griddb"
worktree_path="$HOME/.herdr/worktrees/griddb/docs-mvp-contracts"
worktree_metadata_dir="$test_dir/session-data/worktree-session"
git_template_dir="$test_dir/git-template"
mkdir -p -- "$HOME/dev" "$HOME/.herdr/worktrees/griddb" "$worktree_metadata_dir" "$git_template_dir"
git -c init.defaultBranch=main init --quiet --template="$git_template_dir" "$worktree_base_dir"
git -C "$worktree_base_dir" config user.name 'Test User'
git -C "$worktree_base_dir" config user.email 'test@example.invalid'
printf 'worktree preview\n' >"$worktree_base_dir/README.md"
git -C "$worktree_base_dir" add README.md
git -C "$worktree_base_dir" -c commit.gpgsign=false commit --quiet --message initial
git -C "$worktree_base_dir" worktree add --quiet -b docs/mvp-contracts "$worktree_path" HEAD
worktree_base_display=$(cd -- "$worktree_base_dir" && pwd -P)
jq -cn --arg path "$worktree_path" \
    '{active: 0, workspaces: [{identity_cwd: $path}]}' >"$worktree_metadata_dir/session.json"
unset HERDR_ENV
project_preview_dir="$test_dir/project preview"
session_metadata_dir="$test_dir/session-data/path-session"
stopped_project_dir="$test_dir/stopped project"
stopped_metadata_dir="$test_dir/session-data/stopped-session"
no_path_metadata_dir="$test_dir/session-data/no-path-session"
unlisted_metadata_dir="$test_dir/session-data/unlisted-session"
mkdir -p -- "$HOME" "$session_metadata_dir" "$stopped_metadata_dir" \
    "$no_path_metadata_dir" "$project_preview_dir" "$stopped_project_dir" \
    "$unlisted_metadata_dir" "$HOME/.cache" "$test_dir/other-project"
printf '%s\n' "$project_preview_dir" "$stopped_project_dir" \
    "$test_dir/session-projects/*" >>"$PROJECT_PATHS_FILE"
jq -cn --arg path "$HOME/.cache" \
    '{active: 0, workspaces: [{identity_cwd: $path}]}' >"$unlisted_metadata_dir/session.json"
jq -cn --arg first "$test_dir/other-project" --arg active "$project_preview_dir" \
    '{active: 1, workspaces: [{identity_cwd: $first}, {identity_cwd: $active}]}' \
    >"$session_metadata_dir/session.json"
jq -cn --arg path "$stopped_project_dir" \
    '{active: 0, workspaces: [{identity_cwd: $path}]}' \
    >"$stopped_metadata_dir/session.json"
printf '{"active":0,"workspaces":[{}]}\n' >"$no_path_metadata_dir/session.json"
printf 'HERDR_SESSION_PREVIEW_MARKER\n' >"$project_preview_dir/README.md"
for session_name in current other stopped default broken; do
    test_session_dir="$test_dir/session-data/test-$session_name"
    test_project_dir="$test_dir/session-projects/$session_name"
    mkdir -p -- "$test_session_dir" "$test_project_dir"
    jq -cn --arg path "$test_project_dir" \
        '{active: 0, workspaces: [{identity_cwd: $path}]}' \
        >"$test_session_dir/session.json"
done
jq -cn \
    --arg current_dir "$test_dir/session-data/test-current" \
    --arg other_dir "$test_dir/session-data/test-other" \
    --arg stopped_dir "$test_dir/session-data/test-stopped" \
    --arg default_dir "$test_dir/session-data/test-default" \
    --arg broken_dir "$test_dir/session-data/test-broken" \
    '{sessions: [
        {name: "current", running: true, session_dir: $current_dir},
        {name: "other", running: true, session_dir: $other_dir},
        {name: "stopped", running: false, session_dir: $stopped_dir},
        {name: "default", running: true, session_dir: $default_dir},
        {name: "broken", running: true, session_dir: $broken_dir}
    ]}' >"$HERDR_TEST_STATE"
: >"$HERDR_TEST_LOG"

session_fixture=$(jq -cn \
    --arg live_name path-session --arg live_dir "$session_metadata_dir" \
    --arg stopped_name stopped-session --arg stopped_dir "$stopped_metadata_dir" \
    --arg no_path_dir "$no_path_metadata_dir" \
    --arg worktree_name worktree-session --arg worktree_dir "$worktree_metadata_dir" \
    --arg unlisted_dir "$unlisted_metadata_dir" \
    '{sessions: [
        {name: $live_name, session_dir: $live_dir, running: true},
        {name: $stopped_name, session_dir: $stopped_dir, running: false},
        {name: "no-path", session_dir: $no_path_dir, running: true},
        {name: $worktree_name, session_dir: $worktree_dir, running: true},
        {name: "unlisted-session", session_dir: $unlisted_dir, running: true}
    ]}')
session_rows=$(printf '%s\n' "$session_fixture" | NO_COLOR=1 "$repo_root/bin/herdr-session-rows")
session_token=$(jq -nr --arg name path-session '$name | @base64')
stopped_token=$(jq -nr --arg name stopped-session '$name | @base64')
missing_path_token=$(jq -nr --arg name no-path '$name | @base64')
project_path_json=$(jq -cn --arg path "$project_preview_dir" '$path')
stopped_path_json=$(jq -cn --arg path "$stopped_project_dir" '$path')
worktree_token=$(jq -nr --arg name worktree-session '$name | @base64')
worktree_path_json=$(jq -cn --arg path "$worktree_path" '$path')
expected_live_row="$session_token"$'\t'"$project_preview_dir"$'\t'"$project_path_json"$'\t'session
expected_stopped_row="$stopped_token"$'\t'"$stopped_project_dir"$'\t'"$stopped_path_json"$'\t'session
expected_worktree_row="$worktree_token"$'\t'"$worktree_base_display"$'\t'"$worktree_path_json"$'\t'session
grep -Fxq -- "$expected_live_row" <<<"$session_rows"
grep -Fxq -- "$expected_stopped_row" <<<"$session_rows"
grep -Fxq -- "$expected_worktree_row" <<<"$session_rows"

# Saved-session cleanup does not depend on the checkout's Git metadata.
orphaned_checkout="$HOME/work/orphaned-checkout"
orphaned_metadata_dir="$test_dir/session-data/orphaned-session"
mkdir -p "$orphaned_checkout" "$orphaned_metadata_dir"
printf 'gitdir: %s/missing-git-metadata\n' "$test_dir" >"$orphaned_checkout/.git"
jq -cn --arg path "$orphaned_checkout" \
    '{active: 0, workspaces: [{identity_cwd: $path}]}' >"$orphaned_metadata_dir/session.json"
orphaned_fixture=$(jq -cn --arg dir "$orphaned_metadata_dir" \
    '{sessions: [{name: "orphaned-session", running: false, session_dir: $dir}]}')
orphaned_token=$(jq -nr --arg name orphaned-session '$name | @base64')
for mode in --exclude-default --include-projects; do
    orphaned_rows=$(printf '%s\n' "$orphaned_fixture" | NO_COLOR=1 \
        "$repo_root/bin/herdr-session-rows" "$mode")
    grep -Fq -- "$orphaned_token" <<<"$orphaned_rows" || {
        printf 'herdr-session-rows: hid a saved session with unavailable Git metadata (%s)\n' "$mode" >&2
        exit 1
    }
done

project_token=$(jq -nr --arg path "$new_project_dir" '$path | @base64')
new_project_path_json=$(jq -cn --arg path "$new_project_dir" '$path')
project_rows=$(printf '%s\n' "$session_fixture" | NO_COLOR=1 \
    "$repo_root/bin/herdr-session-rows" --include-projects)
grep -Fxq -- "$project_token"$'\t'"$new_project_dir"$'\t'"$new_project_path_json"$'\t'project <<<"$project_rows"
recent_project_path_json=$(jq -cn --arg path "$recent_project_dir" '$path')
if grep -Fq -- "$recent_project_path_json" <<<"$project_rows"; then
    printf 'herdr-session-rows: zoxide added an unlisted project\n' >&2
    exit 1
fi
unlisted_session_token=$(jq -nr --arg name unlisted-session '$name | @base64')
if grep -Fq -- "$unlisted_session_token" <<<"$project_rows"; then
    printf 'herdr-session-rows: a saved session bypassed project_paths\n' >&2
    exit 1
fi
# Ranked projects keep their ordering even when some entries are saved sessions.
[[ "${project_rows%%$'\n'*}" == "$project_token"$'\t'"$new_project_dir"$'\t'"$new_project_path_json"$'\t'project ]]
# The dedicated session manager still exposes unlisted sessions for cleanup.
grep -Fq -- "$unlisted_session_token" <<<"$session_rows"
worktree_base_token=$(jq -nr --arg path "$worktree_base_dir" '$path | @base64')
worktree_base_path_json=$(jq -cn --arg path "$worktree_base_dir" '$path')
if grep -Fxq -- "$worktree_base_token"$'\t'"$worktree_base_dir"$'\t'"$worktree_base_path_json"$'\t'project <<<"$project_rows"; then
    printf 'herdr-session-rows: duplicated a worktree session as a project entry\n' >&2
    exit 1
fi
# Empty or malformed saved state must not hide valid sessions or project entries.
for metadata in '{"active":true,"workspaces":[{"identity_cwd":"/"}]}' \
    '{"active":-1,"workspaces":[{"identity_cwd":"/"}]}' \
    '{"active":9,"workspaces":[{"identity_cwd":"/"}]}' \
    '{"active":0.5,"workspaces":[{"identity_cwd":"/"}]}' 'broken JSON'; do
    printf '%s\n' "$metadata" >"$no_path_metadata_dir/session.json"
    malformed_rows=$(printf '%s\n' "$session_fixture" | NO_COLOR=1 \
        "$repo_root/bin/herdr-session-rows")
    [[ "$malformed_rows" == "$session_rows" ]]
done
empty_rows=$(printf '{"sessions":[]}\n' | NO_COLOR=1 \
    "$repo_root/bin/herdr-session-rows" --include-projects)
grep -Fq "$new_project_path_json" <<<"$empty_rows"
if printf '{"sessions":{}}\n' | "$repo_root/bin/herdr-session-rows" \
    >"$test_dir/invalid-list.out" 2>"$test_dir/invalid-list.err"; then
    printf 'herdr-session-rows: accepted an invalid session list\n' >&2
    exit 1
fi
grep -Fq 'invalid Herdr session list' "$test_dir/invalid-list.err"
if grep -Fq "$missing_path_token" <<<"$session_rows"; then
    printf 'herdr-session-rows: included a session without a project path\n' >&2
    exit 1
fi
colored_rows=$(printf '%s\n' "$session_fixture" |
    env -u NO_COLOR TERM=xterm-256color "$repo_root/bin/herdr-session-rows")
grep -Fq $'\033[32m'"$project_preview_dir"$'\033[0m' <<<"$colored_rows"
grep -Fq $'\033[90m'"$stopped_project_dir"$'\033[0m' <<<"$colored_rows"
if grep -Fq $'\033[32m'"$stopped_project_dir" <<<"$colored_rows"; then
    printf 'herdr-session-rows: marked a stopped session as live\n' >&2
    exit 1
fi
if grep -Eq 'LIVE|STOPPED' <<<"$colored_rows"; then
    printf 'herdr-session-rows: included session running state in the row\n' >&2
    exit 1
fi
project_preview=$("$repo_root/bin/herdr-session-preview" "$project_path_json")
if command -v bat >/dev/null 2>&1; then
    grep -Fq 'HERDR_SESSION_PREVIEW_MARKER' <<<"$project_preview"
else
    grep -Fq 'README.md' <<<"$project_preview"
fi

# The picker starts before discovery completes, without changing the active session.
printf '%s\n' "$$" >"$XDG_RUNTIME_DIR/herdr-project/active"
printf '%s\n' current >"$XDG_RUNTIME_DIR/herdr-project/session"
printf '%s\n' "$(printf current | base64 | tr -d '\n')" >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 HERDR_TEST_FZF_READY="$test_dir/picker-ready" \
    HERDR_TEST_DISCOVERY_GATE="$test_dir/picker-ready" "$repo_root/bin/herdr-session-select"
[[ -f "$test_dir/picker-ready" && ! -e "$XDG_RUNTIME_DIR/herdr-project/request" ]]

# Empty lists and cancellation still close the picker without a handoff.
: >"$test_dir/empty-project_paths"
printf '%s\n' no-selection >"$HERDR_TEST_FZF_QUEUE"
empty_message=$(HERDR_ENV=1 PROJECT_PATHS_FILE="$test_dir/empty-project_paths" \
    "$repo_root/bin/herdr-session-select")
[[ "$empty_message" == 'herdr-session-select: no matching projects or saved sessions' ]]
printf '%s\n' no-selection >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 "$repo_root/bin/herdr-session-select"
[[ ! -e "$XDG_RUNTIME_DIR/herdr-project/request" ]]

# Streaming must still report discovery errors rather than treating them as cancellation.
printf '%s\n' "$(printf current | base64 | tr -d '\n')" >"$HERDR_TEST_FZF_QUEUE"
if HERDR_ENV=1 PROJECT_PATHS_FILE="$test_dir/missing-project_paths" \
    "$repo_root/bin/herdr-session-select" >"$test_dir/load-error.out" 2>"$test_dir/load-error.err"; then
    printf 'herdr-session-select: ignored discovery failure\n' >&2
    exit 1
fi
grep -Fq 'could not load picker entries' "$test_dir/load-error.err"
[[ ! -e "$XDG_RUNTIME_DIR/herdr-project/request" ]]

# A running named session is stopped and removed through the installed-style symlink.
"$test_dir/bin/herdr-project" --session-kill --yes other
grep -Fxq 'session stop other' "$HERDR_TEST_LOG"
grep -Fxq 'session delete other' "$HERDR_TEST_LOG"
jq -e 'any(.sessions[]; .name == "other") | not' "$HERDR_TEST_STATE" >/dev/null

# A stopped session is deleted without an unnecessary stop.
"$repo_root/bin/herdr-session-kill" --yes stopped
if grep -Fxq 'session stop stopped' "$HERDR_TEST_LOG"; then
    printf 'herdr-session-kill: stopped session was stopped again\n' >&2
    exit 1
fi
jq -e 'any(.sessions[]; .name == "stopped") | not' "$HERDR_TEST_STATE" >/dev/null

# A failed stop must not delete the session.
if HERDR_TEST_FAIL_STOP=broken "$repo_root/bin/herdr-session-kill" --yes broken; then
    printf 'herdr-session-kill: expected stop failure\n' >&2
    exit 1
fi
if grep -Fxq 'session delete broken' "$HERDR_TEST_LOG"; then
    printf 'herdr-session-kill: deleted a session after stop failed\n' >&2
    exit 1
fi
jq -e '.sessions[] | select(.name == "broken" and .running == true)' \
    "$HERDR_TEST_STATE" >/dev/null

# Pressing q on a highlighted session opens the existing delete confirmation.
jq -cn \
    --arg current_dir "$test_dir/session-data/test-current" \
    --arg other_dir "$test_dir/session-data/test-other" \
    --arg broken_dir "$test_dir/session-data/test-broken" \
    '{sessions: [
        {name: "current", running: true, session_dir: $current_dir},
        {name: "other", running: true, session_dir: $other_dir},
        {name: "broken", running: true, session_dir: $broken_dir}
    ]}' >"$HERDR_TEST_STATE"
: >"$HERDR_TEST_LOG"
printf '%s\n' "$(printf other | base64 | tr -d '\n')" @q confirm >"$HERDR_TEST_FZF_QUEUE"
printf '%s\n' "$$" >"$XDG_RUNTIME_DIR/herdr-project/active"
printf '%s\n' current >"$XDG_RUNTIME_DIR/herdr-project/session"
HERDR_ENV=1 "$repo_root/bin/herdr-session-select"
grep -Fxq 'session stop other' "$HERDR_TEST_LOG"
grep -Fxq 'session delete other' "$HERDR_TEST_LOG"
jq -e 'any(.sessions[]; .name == "other") | not' "$HERDR_TEST_STATE" >/dev/null

# Selecting a different session submits an attach request to the outside
# launcher, while selecting the current session is a no-op.
printf '%s\n' "$(printf broken | base64 | tr -d '\n')" >"$HERDR_TEST_FZF_QUEUE"
printf '%s\n' "$$" >"$XDG_RUNTIME_DIR/herdr-project/active"
printf '%s\n' current >"$XDG_RUNTIME_DIR/herdr-project/session"
HERDR_ENV=1 "$test_dir/bin/herdr-project" --select
jq -e '.kind == "session" and .name == "broken"' \
    "$XDG_RUNTIME_DIR/herdr-project/request" >/dev/null
rm -f -- "$XDG_RUNTIME_DIR/herdr-project/request"

# A project with no saved session is offered and submits its path to the launcher.
printf '%s\n' "$project_token" >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 "$repo_root/bin/herdr-session-select"
jq -e --arg path "$new_project_dir" \
    '.kind == "project" and .path == $path' \
    "$XDG_RUNTIME_DIR/herdr-project/request" >/dev/null
rm -f -- "$XDG_RUNTIME_DIR/herdr-project/request"
printf '%s\n' "$(printf current | base64 | tr -d '\n')" >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 "$repo_root/bin/herdr-session-select"
[[ ! -e "$XDG_RUNTIME_DIR/herdr-project/request" ]]

# Deleting another session from the picker leaves the current session alone.
printf '%s\n' "$(printf broken | base64 | tr -d '\n')" confirm >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 "$repo_root/bin/herdr-session-kill"
jq -e 'any(.sessions[]; .name == "broken") | not' "$HERDR_TEST_STATE" >/dev/null
jq -e 'any(.sessions[]; .name == "current" and .running == true)' \
    "$HERDR_TEST_STATE" >/dev/null
[[ ! -e "$XDG_RUNTIME_DIR/herdr-project/kill-request" ]]

# Canceling the confirmation leaves the current session untouched.
printf '%s\n' "$(printf current | base64 | tr -d '\n')" cancel >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 "$repo_root/bin/herdr-session-kill"
[[ ! -e "$XDG_RUNTIME_DIR/herdr-project/kill-request" ]]
if grep -Fxq 'session delete current' "$HERDR_TEST_LOG"; then
    printf 'herdr-session-kill: deleted the session after cancellation\n' >&2
    exit 1
fi

# Deleting the current session hands the destructive operation to the outside
# launcher so the popup does not have to delete its own session.
printf '%s\n' "$(printf current | base64 | tr -d '\n')" confirm >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 "$repo_root/bin/herdr-session-kill"
jq -e '.name == "current"' "$XDG_RUNTIME_DIR/herdr-project/kill-request" >/dev/null
if grep -Fxq 'session stop current' "$HERDR_TEST_LOG"; then
    printf 'herdr-session-kill: current session was stopped inside its popup\n' >&2
    exit 1
fi

# Selecting the active session stops it through the launcher, then removes it.
launcher_runtime="$test_dir/runtime-kill-current"
mkdir -p -- "$launcher_runtime" "$HOME/dev/current"
jq -cn \
    --arg current_dir "$test_dir/session-data/test-current" \
    --arg other_dir "$test_dir/session-data/test-other" \
    '{sessions: [
        {name: "current", running: true, session_dir: $current_dir},
        {name: "other", running: true, session_dir: $other_dir}
    ]}' >"$HERDR_TEST_STATE"
: >"$HERDR_TEST_CLIENT_LOG"
XDG_RUNTIME_DIR="$launcher_runtime" "$test_dir/bin/herdr-project" \
    "$HOME/dev/current" >"$test_dir/launcher-kill.log" 2>&1 &
launcher_pid=$!
for _ in {1..100}; do
    [[ -s "$launcher_runtime/herdr-project/client" ]] &&
        grep -Fxq 'client current' "$HERDR_TEST_CLIENT_LOG" && break
    sleep 0.05
done
[[ -s "$launcher_runtime/herdr-project/client" ]]
grep -Fxq 'client current' "$HERDR_TEST_CLIENT_LOG"
printf '%s\n' "$(printf current | base64 | tr -d '\n')" confirm >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 XDG_RUNTIME_DIR="$launcher_runtime" \
    "$repo_root/bin/herdr-session-kill"
for _ in {1..100}; do
    [[ ! -e "$launcher_runtime/herdr-project/active" ]] && break
    sleep 0.05
done
if [[ -e "$launcher_runtime/herdr-project/active" ]]; then
    printf 'herdr-project: current-session removal did not finish\n' >&2
    exit 1
fi
if wait "$launcher_pid"; then
    launcher_pid=''
else
    status=$?
    launcher_pid=''
    printf 'herdr-project: expected current-session removal to succeed, got %s\n' "$status" >&2
    exit 1
fi
jq -e 'any(.sessions[]; .name == "current") | not' "$HERDR_TEST_STATE" >/dev/null
grep -Fxq 'session stop current' "$HERDR_TEST_LOG"
grep -Fxq 'session delete current' "$HERDR_TEST_LOG"

# Session selection reattaches the same launcher to the chosen Herdr session.
launcher_runtime="$test_dir/runtime-attach"
mkdir -p -- "$launcher_runtime"
jq -cn \
    --arg current_dir "$test_dir/session-data/test-current" \
    --arg other_dir "$test_dir/session-data/test-other" \
    '{sessions: [
        {name: "current", running: true, session_dir: $current_dir},
        {name: "other", running: true, session_dir: $other_dir}
    ]}' >"$HERDR_TEST_STATE"
: >"$HERDR_TEST_CLIENT_LOG"
XDG_RUNTIME_DIR="$launcher_runtime" "$test_dir/bin/herdr-project" \
    "$HOME/dev/current" >"$test_dir/launcher-attach.log" 2>&1 &
launcher_pid=$!
for _ in {1..100}; do
    [[ -s "$launcher_runtime/herdr-project/client" ]] &&
        grep -Fxq 'client current' "$HERDR_TEST_CLIENT_LOG" && break
    sleep 0.05
done
[[ -s "$launcher_runtime/herdr-project/client" ]]
grep -Fxq 'client current' "$HERDR_TEST_CLIENT_LOG"
printf '%s\n' "$(printf other | base64 | tr -d '\n')" >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 XDG_RUNTIME_DIR="$launcher_runtime" \
    "$repo_root/bin/herdr-session-select"
for _ in {1..100}; do
    [[ -s "$launcher_runtime/herdr-project/session" ]] &&
        [[ "$(<"$launcher_runtime/herdr-project/session")" == other ]] &&
        grep -Fxq 'client other' "$HERDR_TEST_CLIENT_LOG" && break
    sleep 0.05
done
[[ "$(<"$launcher_runtime/herdr-project/session")" == other ]]
grep -Fxq 'client other' "$HERDR_TEST_CLIENT_LOG"
read -r client_pid <"$launcher_runtime/herdr-project/client"
kill -INT "$client_pid"
for _ in {1..100}; do
    [[ ! -e "$launcher_runtime/herdr-project/active" ]] && break
    sleep 0.05
done
[[ ! -e "$launcher_runtime/herdr-project/active" ]]
if wait "$launcher_pid"; then
    status=0
else
    status=$?
fi
launcher_pid=''
[[ "$status" == 130 ]]

# Selecting a project without a saved session starts its named session in that directory.
launcher_runtime="$test_dir/runtime-open-project"
mkdir -p -- "$launcher_runtime"
: >"$HERDR_TEST_CLIENT_LOG"
: >"$HERDR_TEST_CWD_LOG"
XDG_RUNTIME_DIR="$launcher_runtime" "$test_dir/bin/herdr-project" \
    "$HOME/dev/current" >"$test_dir/launcher-open-project.log" 2>&1 &
launcher_pid=$!
for _ in {1..100}; do
    [[ -s "$launcher_runtime/herdr-project/client" ]] &&
        grep -Fxq 'client current' "$HERDR_TEST_CLIENT_LOG" && break
    sleep 0.05
done
[[ -s "$launcher_runtime/herdr-project/client" ]]
grep -Fxq 'client current' "$HERDR_TEST_CLIENT_LOG"
printf '%s\n' "$project_token" >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 XDG_RUNTIME_DIR="$launcher_runtime" \
    "$repo_root/bin/herdr-session-select"
for _ in {1..100}; do
    [[ -s "$launcher_runtime/herdr-project/session" ]] &&
        [[ "$(<"$launcher_runtime/herdr-project/session")" == naerm-toolbox ]] &&
        grep -Fxq $'naerm-toolbox\t'"$new_project_dir" "$HERDR_TEST_CWD_LOG" && break
    sleep 0.05
done
[[ "$(<"$launcher_runtime/herdr-project/session")" == naerm-toolbox ]]
grep -Fxq 'client naerm-toolbox' "$HERDR_TEST_CLIENT_LOG"
grep -Fxq $'naerm-toolbox\t'"$new_project_dir" "$HERDR_TEST_CWD_LOG"
read -r client_pid <"$launcher_runtime/herdr-project/client"
kill -INT "$client_pid"
for _ in {1..100}; do
    [[ ! -e "$launcher_runtime/herdr-project/active" ]] && break
    sleep 0.05
done
[[ ! -e "$launcher_runtime/herdr-project/active" ]]
if wait "$launcher_pid"; then
    status=0
else
    status=$?
fi
launcher_pid=''
[[ "$status" == 130 ]]

# The default session is never eligible for deletion.
if "$repo_root/bin/herdr-session-kill" --yes default; then
    printf 'herdr-session-kill: expected default-session refusal\n' >&2
    exit 1
fi
if grep -Fxq 'session delete default' "$HERDR_TEST_LOG"; then
    printf 'herdr-session-kill: deleted the default session\n' >&2
    exit 1
fi

printf 'herdr session kill tests: ok\n'
