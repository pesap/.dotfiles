#!/usr/bin/env bash
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
mango_script="$repo_root/bin/.local/bin/waybar-mango"
weather_script="$repo_root/bin/.local/bin/waybar-weather"
system_script="$repo_root/bin/.local/bin/waybar-system"
waybar_config="$repo_root/waybar/.config/waybar/config.jsonc"
autostart_script="$repo_root/mango/.config/mango/autostart.sh"
test_dir=''

fail() {
	printf 'waybar startup test failure: %s\n' "$*" >&2
	exit 1
}

cleanup() {
	[[ -n "$test_dir" && -d "$test_dir" && ! -L "$test_dir" ]] || return 0
	resolved_test_dir="$(realpath "$test_dir")"
	[[ "$resolved_test_dir" == /var/tmp/dotfiles-test.waybar.* ]] ||
		fail "refusing to clean unexpected path: $resolved_test_dir"
	rm -rf -- "$resolved_test_dir"
}
trap cleanup EXIT

test_dir="$(mktemp -d /var/tmp/dotfiles-test.waybar.XXXXXX)"
home_dir="$test_dir/home"
mock_bin="$test_dir/mock-bin"
cache_dir="$test_dir/cache"
mkdir -p -- "$home_dir" "$mock_bin" "$cache_dir"

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

cat >"$mock_bin/curl" <<'EOF'
#!/bin/sh
set -eu
printf 'called\n' >"${CURL_MARKER:?}"
printf 'Sunny +70°F\n'
EOF
chmod 755 "$mock_bin/mmsg" "$mock_bin/curl"

fixture='{"name":"HDMI-A-1","layout_symbol":"T","tags":[{"index":1,"is_active":true,"client_count":1},{"index":2,"is_active":false,"client_count":1}],"active_client":{"title":"A & B","appid":"App"},"keymode":"default"}'
run_mango=(
	env
	"HOME=$home_dir"
	"PATH=$mock_bin:$PATH"
	"WAYBAR_OUTPUT_NAME=HDMI-A-1"
	"MMSG_FIXTURE=$fixture"
	"$mango_script"
)

tags="$("${run_mango[@]}" tags)"
jq -e '.text == "[1]  2 " and .tooltip == "Monitor: HDMI-A-1"' <<<"$tags" >/dev/null ||
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
	mapfile -t streamed < <(
		MMSG_REPEAT=2 "${run_mango[@]}" watch "$mode"
	)
	[[ "${#streamed[@]}" -eq 2 ]] || fail "streaming $mode dropped a repeated event"
	[[ "${streamed[0]}" == "${streamed[1]}" ]] ||
		fail "streaming $mode produced inconsistent repeated events"
	jq -e . <<<"${streamed[0]}" >/dev/null ||
		fail "streaming $mode is not valid JSON"
done

set +e
"${run_mango[@]}" invalid >/dev/null 2>&1
invalid_status=$?
set -e
[[ "$invalid_status" -eq 2 ]] || fail 'invalid Mango mode exit status changed'

curl_marker="$test_dir/curl-called"
weather="$(
	env HOME="$home_dir" XDG_CACHE_HOME="$cache_dir" PATH="$mock_bin:$PATH" \
		CURL_MARKER="$curl_marker" "$weather_script" status
)"
jq -e '.text == "󰖐 ?"' <<<"$weather" >/dev/null || fail 'empty weather fallback changed'
[[ ! -e "$curl_marker" ]] || fail 'weather status performed a network request'

weather="$(
	env HOME="$home_dir" XDG_CACHE_HOME="$cache_dir" PATH="$mock_bin:$PATH" \
		CURL_MARKER="$curl_marker" "$weather_script" refresh
)"
jq -e '.text == "󰖐 Sunny +70°F"' <<<"$weather" >/dev/null ||
	fail 'weather refresh output changed'
[[ -s "$cache_dir/waybar/weather" ]] || fail 'weather refresh did not update its cache'

cp -- "$cache_dir/waybar/weather" "$test_dir/weather-before-failure"
cat >"$mock_bin/jq" <<'EOF'
#!/bin/sh
exit 1
EOF
chmod 755 "$mock_bin/jq"
set +e
env HOME="$home_dir" XDG_CACHE_HOME="$cache_dir" PATH="$mock_bin:$PATH" \
	CURL_MARKER="$curl_marker" "$weather_script" refresh >/dev/null 2>&1
refresh_status=$?
set -e
[[ "$refresh_status" -ne 0 ]] || fail 'weather refresh hid a JSON encoder failure'
cmp -s "$test_dir/weather-before-failure" "$cache_dir/waybar/weather" ||
	fail 'weather refresh replaced a valid cache after an encoder failure'
rm -f -- "$mock_bin/jq"

env HOME="$home_dir" XDG_CACHE_HOME="$cache_dir" "$system_script" |
	jq -e 'has("text") and has("tooltip")' >/dev/null ||
	fail 'system summary is not valid Waybar JSON'

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
rg -F 'waybar-weather watch' "$autostart_script" >/dev/null ||
	fail 'autostart does not launch the asynchronous weather refresher'
rg -F 'systemd-run --user --collect' "$autostart_script" >/dev/null ||
	fail 'autostart does not delegate the weather refresher to systemd'

printf 'waybar startup tests: ok\n'
