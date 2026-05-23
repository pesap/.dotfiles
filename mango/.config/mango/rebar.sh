#!/usr/bin/env sh

pkill waybar
if command -v waybar >/dev/null 2>&1; then
	waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" &
else
	echo "waybar not found in PATH"
fi
