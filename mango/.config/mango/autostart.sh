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

# Propagate to user services / D-Bus-activated apps.
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
	dbus-update-activation-environment --systemd XDG_DATA_DIRS >/dev/null 2>&1 || true
fi
if command -v systemctl >/dev/null 2>&1; then
	systemctl --user import-environment XDG_DATA_DIRS >/dev/null 2>&1 || true
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

WAYBAR_LOG="$LOG_DIR/waybar.log"
if command -v waybar >/dev/null 2>&1; then
	pkill -x waybar >/dev/null 2>&1 || true
	waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" >>"$WAYBAR_LOG" 2>&1 &
else
	log_msg "$WAYBAR_LOG" "waybar is not installed or not in PATH"
fi

SWAYBG_LOG="$LOG_DIR/swaybg.log"
if command -v swaybg >/dev/null 2>&1; then
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

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
	dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=wlroots >/dev/null 2>&1 || true
fi
