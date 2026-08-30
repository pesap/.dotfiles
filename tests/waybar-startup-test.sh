#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
mango_script="$repo_root/bin/.local/bin/waybar-mango"
memory_script="$repo_root/bin/.local/bin/waybar-memory"
disk_script="$repo_root/bin/.local/bin/waybar-disk"
gpu_script="$repo_root/bin/.local/bin/waybar-gpu"
temperature_script="$repo_root/bin/.local/bin/waybar-temperature"
waybar_config="$repo_root/waybar/.config/waybar/config.jsonc"
autostart_script="$repo_root/mango/.config/mango/autostart.sh"
test_dir=''

fail() {
    printf 'waybar startup test failure: %s\n' "$*" >&2
    exit 1
}

cleanup() {
    [[ -n "$test_dir" && -d "$test_dir" && ! -L "$test_dir" ]] || return 0
    logical_test_dir="$(cd "$test_dir" && pwd -L)"
    resolved_test_dir="$(realpath "$test_dir")"
    case "$logical_test_dir" in
    /var/tmp/dotfiles-test.waybar.*/*) fail "refusing to clean unexpected path: $resolved_test_dir" ;;
    /var/tmp/dotfiles-test.waybar.*) ;;
    *) fail "refusing to clean unexpected path: $resolved_test_dir" ;;
    esac
    case "$resolved_test_dir" in
    /var/tmp/dotfiles-test.waybar.*/* | /private/var/tmp/dotfiles-test.waybar.*/*) fail "refusing to clean unexpected path: $resolved_test_dir" ;;
    /var/tmp/dotfiles-test.waybar.* | /private/var/tmp/dotfiles-test.waybar.*) ;;
    *) fail "refusing to clean unexpected path: $resolved_test_dir" ;;
    esac
    rm -rf -- "$logical_test_dir"
}
trap cleanup EXIT

test_dir="$(mktemp -d /var/tmp/dotfiles-test.waybar.XXXXXX)"
home_dir="$test_dir/home"
mock_bin="$test_dir/mock-bin"
mkdir -p -- "$home_dir" "$mock_bin"

cat >"$mock_bin/notify-send" <<'EOF'
#!/bin/sh
set -eu
printf '%s\n' "$*" >"${NOTIFY_MARKER:?}"
EOF

cat >"$mock_bin/mmsg" <<'EOF'
#!/bin/sh
set -eu
case "${1:-} ${2:-}" in
	'get monitor') printf '%s\n' "${MMSG_FIXTURE:?}" ;;
	'watch monitor')
		printf '%s\n' "${MMSG_FIXTURE:?}"
		[ "${MMSG_REPEAT:-1}" -eq 1 ] || printf '%s\n' "$MMSG_FIXTURE"
		;;
	*) exit 2 ;;
esac
EOF

chmod 755 "$mock_bin/notify-send" "$mock_bin/mmsg"

fixture='{"name":"HDMI-A-1","layout_symbol":"T","tags":[{"index":1,"is_active":true,"client_count":1},{"index":2,"is_active":false,"client_count":1},{"index":3,"is_active":false,"client_count":0},{"index":4,"is_active":false,"client_count":0},{"index":5,"is_active":false,"client_count":2}],"active_client":{"title":"A & B","appid":"App"},"keymode":"default"}'
run_mango=(
    env
    "HOME=$home_dir"
    "PATH=$mock_bin:$PATH"
    "WAYBAR_OUTPUT_NAME=HDMI-A-1"
    "MMSG_FIXTURE=$fixture"
    "$mango_script"
)

tags="$("${run_mango[@]}" tags)"
jq -e '.text == "[1]  2   3   4 " and .tooltip == "Monitor: HDMI-A-1"' <<<"$tags" >/dev/null ||
    fail 'one-shot tags contract changed'

layout="$("${run_mango[@]}" layout)"
jq -e '.text == "T" and .tooltip == "Layout: T"' <<<"$layout" >/dev/null ||
    fail 'one-shot layout contract changed'

window="$("${run_mango[@]}" window)"
jq -e '.text == "A &amp; B" and .tooltip == "App"' <<<"$window" >/dev/null ||
    fail 'one-shot window contract changed'

keymode="$("${run_mango[@]}" keymode)"
jq -e '.text == "default" and .tooltip == "Key mode: default"' <<<"$keymode" >/dev/null ||
    fail 'one-shot keymode contract changed'

for mode in tags layout window keymode; do
    streamed_file="$test_dir/streamed-$mode"
    MMSG_REPEAT=2 "${run_mango[@]}" watch "$mode" >"$streamed_file"
    streamed_count="$(wc -l <"$streamed_file" | tr -d ' ')"
    [[ "$streamed_count" -eq 2 ]] || fail "streaming $mode dropped a repeated event"
    streamed_first="$(sed -n '1p' "$streamed_file")"
    streamed_second="$(sed -n '2p' "$streamed_file")"
    [[ "$streamed_first" == "$streamed_second" ]] ||
        fail "streaming $mode produced inconsistent repeated events"
    jq -e . <<<"$streamed_first" >/dev/null ||
        fail "streaming $mode is not valid JSON"
done

set +e
"${run_mango[@]}" invalid >/dev/null 2>&1
invalid_status=$?
set -e
[[ "$invalid_status" -eq 2 ]] || fail 'invalid Mango mode exit status changed'

memory_output="$($memory_script)"
jq -e '(.text | contains("━")) | not' <<<"$memory_output" >/dev/null ||
    fail 'RAM widget still renders a slider'
disk_output="$(env HOME="$home_dir" "$disk_script")"
jq -e '(.text | contains("━")) | not' <<<"$disk_output" >/dev/null ||
    fail 'disk widget still renders a slider'
gpu_output="$($gpu_script)"
jq -e '(.text | startswith("GFX ")) and ((.text | contains("GPU GPU")) | not)' <<<"$gpu_output" >/dev/null ||
    fail 'GPU widget has a repeated label'
temperature_output="$(env HOME="$home_dir" "$temperature_script")"
jq -e '(.text | startswith("󰔏 ")) and (.tooltip | contains("CPU:")) and (.tooltip | contains("GPU:")) and ((.tooltip | contains("Weather:")) | not)' <<<"$temperature_output" >/dev/null ||
    fail 'temperature widget exposes weather instead of local component details'
notify_marker="$test_dir/notify-called"
env HOME="$home_dir" PATH="$mock_bin:$PATH" \
    NOTIFY_MARKER="$notify_marker" "$temperature_script" notify
[[ -s "$notify_marker" ]] || fail 'temperature widget click did not show component temperatures'
rg -F 'CPU:' "$notify_marker" >/dev/null || fail 'temperature notification omitted CPU temperature'
rg -F 'GPU:' "$notify_marker" >/dev/null || fail 'temperature notification omitted GPU temperature'

for module in memory disk gpu; do
    module_name="custom/$module"
    jq -e --arg module "$module_name" \
        '.[$module] and (."group/system-usage".modules | index($module) != null)' "$waybar_config" >/dev/null ||
        fail "$module_name widget is not in the usage section"
done
jq -e '."custom/temperatures" and (."modules-right" | index("custom/temperatures") != null) and (has("group/temperatures") | not)' "$waybar_config" >/dev/null ||
    fail 'temperature readings are not consolidated into one widget'
jq -e '."custom/memory".exec | contains("waybar-memory")' "$waybar_config" >/dev/null ||
    fail 'RAM widget does not use its usage script'
jq -e '."custom/disk".exec | contains("waybar-disk")' "$waybar_config" >/dev/null ||
    fail 'disk widget does not use its usage script'
jq -e '."custom/gpu".exec | contains("waybar-gpu")' "$waybar_config" >/dev/null ||
    fail 'GPU widget does not use its usage script'
jq -e '."custom/volume".exec | contains("waybar-volume")' "$waybar_config" >/dev/null ||
    fail 'volume widget does not use its slider script'
jq -e '."custom/volume"."on-click" | contains("waybar-volume toggle")' "$waybar_config" >/dev/null ||
    fail 'volume widget does not toggle its slider on click'
jq -e '."custom/temperatures".exec == "~/.local/bin/waybar-temperature" and (."custom/temperatures"."on-click" | contains("waybar-temperature notify"))' "$waybar_config" >/dev/null ||
    fail 'temperature widget does not use its hover and click notification script'
jq -e '(."modules-left" | index("custom/wallpaper")) == 2 and (."modules-right" | index("custom/wallpaper") | not)' "$waybar_config" >/dev/null ||
    fail 'wallpaper widget is not after the layout on the left'
jq -e '.bluetooth.format == "" and .bluetooth."format-connected" == "" and .bluetooth."format-disabled" == "" and (.bluetooth | has("on-click") | not) and (.bluetooth."tooltip-format" | contains("address") | not)' "$waybar_config" >/dev/null ||
    fail 'Bluetooth widget exposes private device details or a removed action'
jq -e '(.network."tooltip-format" | contains("essid") | not) and (.network."tooltip-format" | contains("gwaddr") | not) and (.network."format-alt" | contains("ipaddr") | not)' "$waybar_config" >/dev/null ||
    fail 'Network widget exposes private network details'
jq -e '.clock.format == "{:%H:%M}" and (.clock."tooltip-format" | contains("{calendar}"))' "$waybar_config" >/dev/null ||
    fail 'clock widget does not use the time and calendar formats'
jq -e '( ."custom/volume"."on-scroll-up" | contains("set-volume") ) and
    ( ."custom/volume"."on-scroll-down" | contains("set-volume") )' "$waybar_config" >/dev/null ||
    fail 'volume widget does not provide scroll adjustment'

for module in mango-tags mango-layout mango-window; do
    jq -e --arg module "custom/$module" \
        '.[$module].exec | contains("waybar-mango watch ")' "$waybar_config" >/dev/null ||
        fail "$module is not event-driven"
    jq -e --arg module "custom/$module" \
        '.[$module] | has("interval") | not' "$waybar_config" >/dev/null ||
        fail "$module still has a polling interval"
done
jq -e '."custom/power".interval == 30' "$waybar_config" >/dev/null ||
    fail 'power polling interval changed unexpectedly'

[[ "$(rg -c 'dbus-update-activation-environment --systemd' "$autostart_script")" -eq 1 ]] ||
    fail 'graphical environment is not imported exactly once'
if rg -n '^[[:space:]]*(pkill -x swaync|swaync([[:space:]]|$).*[&])' "$autostart_script" >/dev/null; then
    fail 'autostart still launches SwayNC directly'
fi
rg -F 'systemctl --user start swaync.service' "$autostart_script" >/dev/null ||
    fail 'autostart does not delegate SwayNC to systemd'
if rg -n 'wttr\.in|weather-(refresh|watch)' "$autostart_script" >/dev/null; then
    fail 'autostart still launches disabled weather collection'
fi

printf 'waybar startup tests: ok\n'
