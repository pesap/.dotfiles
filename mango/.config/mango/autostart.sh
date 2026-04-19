#!/usr/bin/env sh

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
