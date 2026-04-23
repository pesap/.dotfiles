#!/usr/bin/env sh

output="${WAYBAR_OUTPUT_NAME:-}"
if [ -n "$output" ]; then
  tags="$(mmsg -o "$output" -g -t 2>/dev/null)"
else
  tags="$(mmsg -g -t 2>/dev/null)"
fi

active_tag="$(printf '%s\n' "$tags" | awk '$1=="tag" && $3==1 { print $2; exit }')"

if [ -z "$active_tag" ]; then
  printf '{"text":"-","class":"inactive"}\n'
  exit 0
fi

printf '{"text":"%s","class":"active"}\n' "$active_tag"
