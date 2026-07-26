#!/usr/bin/env sh

output="${WAYBAR_OUTPUT_NAME:-}"
if [ -n "$output" ]; then
  tags="$(/usr/bin/mmsg get tags "$output" 2>/dev/null)"
else
  tags="$(/usr/bin/mmsg get tags HDMI-A-1 2>/dev/null)"
fi

active_tag="$(printf '%s\n' "$tags" | /usr/bin/jq -r '.active_tags[0] // empty' 2>/dev/null)"

if [ -z "$active_tag" ]; then
  printf '{"text":"-","class":"inactive"}\n'
else
  printf '{"text":"%s","class":"active"}\n' "$active_tag"
fi
