#!/usr/bin/env sh
set -eu
MMSG_CMD="$(command -v mmsg || true)"
WLR_RANDR_CMD="$(command -v wlr-randr || true)"

LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mango"
mkdir -p "$LOG_DIR"

log_msg() {
	log_file="$1"
	shift
	printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$log_file"
}

rotate_log() {
	log_file="$1"
	max_bytes="$2"
	[ -f "$log_file" ] || return 0
	size="$(wc -c <"$log_file" 2>/dev/null || printf 0)"
	case "$size" in
		'' | *[!0-9]*) return 0 ;;
	esac
	[ "$size" -ge "$max_bytes" ] || return 0
	mv -f -- "$log_file" "$log_file.previous"
}

append_data_dir() {
	dir="$1"
	case ":$XDG_DATA_DIRS:" in
	*":$dir:"*) ;;
	*) XDG_DATA_DIRS="${XDG_DATA_DIRS:+$XDG_DATA_DIRS:}$dir" ;;
	esac
}

# Ensure Flatpak desktop entries are discoverable.
XDG_DATA_DIRS="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
[ -d "/var/lib/flatpak/exports/share" ] && append_data_dir "/var/lib/flatpak/exports/share"
[ -d "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports/share" ] && append_data_dir "${XDG_DATA_HOME:-$HOME/.local/share}/flatpak/exports/share"
export XDG_DATA_DIRS

SESSION_LOG="$LOG_DIR/session.log"
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
	log_msg "$SESSION_LOG" "WAYLAND_DISPLAY is unset; skipping graphical environment import"
elif command -v dbus-update-activation-environment >/dev/null 2>&1; then
	if ! dbus-update-activation-environment --systemd \
		WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots XDG_DATA_DIRS \
		>>"$SESSION_LOG" 2>&1; then
		log_msg "$SESSION_LOG" "failed to import graphical environment"
	fi
elif command -v systemctl >/dev/null 2>&1; then
	if ! env XDG_CURRENT_DESKTOP=wlroots \
		systemctl --user import-environment \
		WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_DATA_DIRS \
		>>"$SESSION_LOG" 2>&1; then
		log_msg "$SESSION_LOG" "failed to import graphical environment into systemd"
	fi
else
	log_msg "$SESSION_LOG" "no graphical environment importer is available"
fi

# Keep one service owner for notifications. The D-Bus unit will also activate
# this service on demand if it exits later in the session.
NOTIFY_LOG="$LOG_DIR/notifications.log"
if command -v swaync >/dev/null 2>&1; then
	if command -v systemctl >/dev/null 2>&1; then
		if ! systemctl --user start swaync.service >>"$NOTIFY_LOG" 2>&1; then
			log_msg "$NOTIFY_LOG" "failed to start swaync.service"
		fi
	else
		log_msg "$NOTIFY_LOG" "systemctl unavailable; refusing a direct SwayNC launch"
	fi
fi

CLIPBOARD_LOG="$LOG_DIR/clipboard.log"
if command -v wl-clip-persist >/dev/null 2>&1; then
	wl-clip-persist --clipboard both >>"$CLIPBOARD_LOG" 2>&1 &
fi
if command -v wl-paste >/dev/null 2>&1 && command -v cliphist >/dev/null 2>&1; then
	wl-paste --type text --watch cliphist store >>"$CLIPBOARD_LOG" 2>&1 &
	wl-paste --type image --watch cliphist store >>"$CLIPBOARD_LOG" 2>&1 &
fi

# Create a persistent 1080p virtual output for Steam Link capture.
# Mango 0.15+ exposes this through the new mmsg IPC.
VIRTUAL_LOG="$LOG_DIR/virtual-output.log"
(
	sleep 1
	if [ -n "$MMSG_CMD" ] && ! "$MMSG_CMD" get all-monitors 2>/dev/null | grep -q 'HEADLESS-'; then
		"$MMSG_CMD" dispatch create_virtual_output >>"$VIRTUAL_LOG" 2>&1 || true
		sleep 1
	fi
	if [ -n "$WLR_RANDR_CMD" ]; then
		"$WLR_RANDR_CMD" --output HEADLESS-1 --pos 3640,0 --scale 1 --custom-mode 1920x1080@60Hz >>"$VIRTUAL_LOG" 2>&1 || true
	else
		log_msg "$VIRTUAL_LOG" "wlr-randr is not installed; install the wlr-randr package"
	fi
	# Boot in the normal desk layout. The toggle switches to headless-only
	# mode and routes any running Steam games to HEADLESS-1 when requested.
	if [ -x "$HOME/.local/bin/mango-toggle-headless" ]; then
		"$HOME/.local/bin/mango-toggle-headless" desk >>"$VIRTUAL_LOG" 2>&1 || true
	fi
) &

WEATHER_LOG="$LOG_DIR/weather-refresh.log"
rotate_log "$WEATHER_LOG" 1048576
if command -v waybar-weather >/dev/null 2>&1 && command -v flock >/dev/null 2>&1; then
	if command -v systemd-run >/dev/null 2>&1 &&
		command -v systemctl >/dev/null 2>&1; then
		WEATHER_UNIT="waybar-weather-refresh.service"
		if ! systemctl --user is-active --quiet "$WEATHER_UNIT"; then
			systemctl --user reset-failed "$WEATHER_UNIT" >/dev/null 2>&1 || true
			if ! systemd-run --user --collect \
				--unit="$WEATHER_UNIT" \
				--property=Description="Waybar weather cache refresher" \
				--property=Restart=on-failure \
				--property=RestartSec=30s \
				"$(command -v waybar-weather)" watch >>"$WEATHER_LOG" 2>&1; then
				log_msg "$WEATHER_LOG" "failed to start $WEATHER_UNIT"
				waybar-weather watch >>"$WEATHER_LOG" 2>&1 &
			fi
		fi
	else
		waybar-weather watch >>"$WEATHER_LOG" 2>&1 &
	fi
else
	log_msg "$WEATHER_LOG" "weather refresh requires waybar-weather and flock"
fi

WAYBAR_LOG="$LOG_DIR/waybar.log"
rotate_log "$WAYBAR_LOG" 1048576
if command -v waybar >/dev/null 2>&1; then
	pkill -x waybar >/dev/null 2>&1 || true
	waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" >>"$WAYBAR_LOG" 2>&1 &
else
	log_msg "$WAYBAR_LOG" "waybar is not installed or not in PATH"
fi

SWAYBG_LOG="$LOG_DIR/swaybg.log"
(
	if command -v wallpaperctl >/dev/null 2>&1; then
		wallpaperctl apply-current >>"$SWAYBG_LOG" 2>&1 || true
	elif command -v swaybg >/dev/null 2>&1; then
		WALLPAPER="$HOME/assets/empoleon.png"
		pkill -x swaybg >/dev/null 2>&1 || true
		if [ -f "$WALLPAPER" ]; then
			swaybg -i "$WALLPAPER" -m fill >>"$SWAYBG_LOG" 2>&1 &
		else
			log_msg "$SWAYBG_LOG" "wallpaper missing: $WALLPAPER"
		fi
	else
		log_msg "$SWAYBG_LOG" "swaybg is not installed or not in PATH"
	fi
) &
