#!/usr/bin/env sh

# Terminate already running bar instances
killall -q waybar

# Wait until the processes have been shut down
while pgrep -x waybar >/dev/null; do sleep 1; done

# Prefer a generated runtime theme; fall back to the tracked default.
runtime_base="${XDG_RUNTIME_DIR:-/var/tmp}"
runtime_uid="$(id -u)"
runtime_dir="${WAYBAR_RUNTIME_DIR:-$runtime_base/waybar-$runtime_uid}"
runtime_compatible=1
if pgrep -x mango >/dev/null 2>&1 &&
    ! grep -Fqx 'mango-adapted' "$runtime_dir/.mango-support" 2>/dev/null; then
    runtime_compatible=0
fi
if [ "$runtime_compatible" -eq 1 ] &&
    [ -r "$runtime_dir/config.jsonc" ] && [ -r "$runtime_dir/style.css" ]; then
    exec waybar -c "$runtime_dir/config.jsonc" -s "$runtime_dir/style.css"
fi
exec waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css"
