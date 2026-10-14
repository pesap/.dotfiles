#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
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
expect_keys=''
for argument in "$@"; do
    if [[ "$argument" == --expect=* ]]; then
        expect_keys=${argument#--expect=}
    fi
done
IFS= read -r selected <"$queue"
tail -n +2 "$queue" >"$queue.tmp"
mv "$queue.tmp" "$queue"
while IFS= read -r candidate; do
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
exit 1
EOF
cat >"$test_dir/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${HERDR_TEST_LOG:?}"
if [[ "${1:-}" == --session ]]; then
    trap - INT
    exec python3 - "${HERDR_TEST_CLIENT_LOG:?}" "${2:?}" <<'PY'
import signal
import sys
import time

signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
with open(sys.argv[1], "a", encoding="utf-8") as client_log:
    client_log.write(f"client {sys.argv[2]}\n")
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
chmod +x "$test_dir/bin/fzf" "$test_dir/bin/herdr"

export HOME="$test_dir/home"
export XDG_RUNTIME_DIR="$test_dir/runtime"
export PATH="$test_dir/bin:$PATH"
export HERDR_TEST_STATE="$test_dir/sessions.json"
export HERDR_TEST_LOG="$test_dir/herdr.log"
export HERDR_TEST_CLIENT_LOG="$test_dir/herdr-client.log"
export HERDR_TEST_FZF_QUEUE="$test_dir/fzf.queue"
unset HERDR_ENV
project_preview_dir="$test_dir/project preview"
session_metadata_dir="$test_dir/session-data/path-session"
stopped_project_dir="$test_dir/stopped project"
stopped_metadata_dir="$test_dir/session-data/stopped-session"
no_path_metadata_dir="$test_dir/session-data/no-path-session"
mkdir -p -- "$HOME" "$session_metadata_dir" "$stopped_metadata_dir" \
    "$no_path_metadata_dir" "$project_preview_dir" "$stopped_project_dir" \
    "$test_dir/other-project"
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
    '{sessions: [
        {name: $live_name, session_dir: $live_dir, running: true},
        {name: $stopped_name, session_dir: $stopped_dir, running: false},
        {name: "no-path", session_dir: $no_path_dir, running: true}
    ]}')
session_rows=$(printf '%s\n' "$session_fixture" | NO_COLOR=1 "$repo_root/bin/herdr-session-rows")
session_token=$(jq -nr --arg name path-session '$name | @base64')
stopped_token=$(jq -nr --arg name stopped-session '$name | @base64')
missing_path_token=$(jq -nr --arg name no-path '$name | @base64')
project_path_json=$(jq -cn --arg path "$project_preview_dir" '$path')
stopped_path_json=$(jq -cn --arg path "$stopped_project_dir" '$path')
expected_live_row="$session_token"$'\t'"$project_preview_dir"$'\t'"$project_path_json"
expected_stopped_row="$stopped_token"$'\t'"$stopped_project_dir"$'\t'"$stopped_path_json"
grep -Fxq -- "$expected_live_row" <<<"$session_rows"
grep -Fxq -- "$expected_stopped_row" <<<"$session_rows"
if grep -Fq "$missing_path_token" <<<"$session_rows"; then
    printf 'herdr-session-rows: included a session without a project path\n' >&2
    exit 1
fi
colored_rows=$(printf '%s\n' "$session_fixture" | \
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
jq -e '.name == "broken"' "$XDG_RUNTIME_DIR/herdr-project/request" >/dev/null
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
    [[ -s "$launcher_runtime/herdr-project/client" ]] && \
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
    [[ -s "$launcher_runtime/herdr-project/client" ]] && \
        grep -Fxq 'client current' "$HERDR_TEST_CLIENT_LOG" && break
    sleep 0.05
done
[[ -s "$launcher_runtime/herdr-project/client" ]]
grep -Fxq 'client current' "$HERDR_TEST_CLIENT_LOG"
printf '%s\n' "$(printf other | base64 | tr -d '\n')" >"$HERDR_TEST_FZF_QUEUE"
HERDR_ENV=1 XDG_RUNTIME_DIR="$launcher_runtime" \
    "$repo_root/bin/herdr-session-select"
for _ in {1..100}; do
    [[ -s "$launcher_runtime/herdr-project/session" ]] && \
        [[ "$(<"$launcher_runtime/herdr-project/session")" == other ]] && \
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
