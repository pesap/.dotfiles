#================================================================================
# Login-only initialization
#================================================================================
if [[ -r /etc/profile ]]; then
    source /etc/profile
fi

if (( $+commands[brew] )); then
    eval "$("${commands[brew]}" shellenv)"
fi
