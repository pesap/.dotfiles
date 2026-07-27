#!/usr/bin/env bash

battery_info="$(pmset -g batt 2>/dev/null)"
percentage="$(printf '%s\n' "$battery_info" | grep -Eo '[0-9]+%' | head -n 1)"

if [[ -z "$percentage" ]]; then
    sketchybar --set "$NAME" icon="🔋" label="N/A"
elif [[ "$battery_info" == *"AC Power"* ]]; then
    sketchybar --set "$NAME" icon="⚡" label="$percentage"
else
    sketchybar --set "$NAME" icon="🔋" label="$percentage"
fi
