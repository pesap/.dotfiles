autoload -Uz add-zsh-hook

_auto_venv() {
    local venv_path="$PWD/.venv"

    # If we are currently in a venv but left its directory → deactivate
    if [[ -n "$VIRTUAL_ENV" ]]; then
        if [[ "$PWD" != "$VIRTUAL_ENV:h"/* ]]; then
            echo "Deactivating virtualenv: $VIRTUAL_ENV"
            deactivate
        fi
    fi

    # If current dir has a .venv → activate it
    if [[ -f "$venv_path/bin/activate" ]]; then
        if [[ "$VIRTUAL_ENV" != "$venv_path" ]]; then
            echo "Auto-activating virtualenv in $venv_path"
            source "$venv_path/bin/activate"
        fi
    fi
}

add-zsh-hook chpwd _auto_venv
# Also run once for the current directory when opening the shell
_auto_venv
