# shellcheck shell=bash
# Bash startup loader. Managed via dotfiles and safe for non-interactive shells.

for system_bashrc in /etc/bash.bashrc /etc/bashrc; do
    if [[ -r "$system_bashrc" ]]; then
        # shellcheck source=/dev/null
        source "$system_bashrc"
        break
    fi
done

for config_file in "$HOME"/.config/bashrc/[0-9]*.sh; do
    [[ -r "$config_file" ]] || continue
    # shellcheck source=/dev/null
    source "$config_file"
done

# Interactive-only local overrides stay outside the repository and load last.
# shellcheck source=/dev/null
[[ -r "$HOME/.bashrc.local" ]] && source "$HOME/.bashrc.local"
