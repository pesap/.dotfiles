#!/bin/bash

SSID=$(ipconfig getsummary en0 2>/dev/null | awk -F' : ' '/^[[:space:]]*SSID[[:space:]]*:/{print $2}')

if [ -z "$SSID" ]; then
    sketchybar --set $NAME label="Off" icon="󰖪"
else
    sketchybar --set $NAME label="$SSID" icon="󰖩"
fi
