# Plugin management via antidote
#
# Bootstrap order:
#   1. Locate antidote (brew on macOS, ~/.antidote git clone elsewhere).
#   2. Auto-clone if missing so fresh machines just work.
#   3. Rebuild the static bundle iff ~/.zsh_plugins.txt is newer than the cache.
#   4. Source the cached bundle (single static file → fast cold start).

ANTIDOTE_HOME="${ANTIDOTE_HOME:-$HOME/.antidote}"
_antidote_ref="v2.1.1"
_antidote_commit="ce758942ab522158c97c8d492b2e6a584b294ec7"
_antidote_trusted=1
_plugins_txt="$HOME/.zsh_plugins.txt"
_plugins_zsh="$HOME/.zsh_plugins.zsh"

# Locate antidote.zsh
_antidote_src=""
if command -v brew >/dev/null 2>&1; then
    _brew_prefix="$(brew --prefix 2>/dev/null)"
    if [[ -f "$_brew_prefix/opt/antidote/share/antidote/antidote.zsh" ]]; then
        _antidote_src="$_brew_prefix/opt/antidote/share/antidote/antidote.zsh"
    fi
fi
if [[ -z "$_antidote_src" ]]; then
    if [[ ! -d "$ANTIDOTE_HOME" ]]; then
        echo "antidote: cloning to $ANTIDOTE_HOME..." >&2
        if git clone --depth=1 --branch "$_antidote_ref" https://github.com/mattmc3/antidote.git "$ANTIDOTE_HOME"; then
            _antidote_head="$(git -C "$ANTIDOTE_HOME" rev-parse HEAD 2>/dev/null)"
            if [[ "$_antidote_head" != "$_antidote_commit" ]]; then
                echo "antidote: refusing to source an unexpected $_antidote_ref checkout" >&2
                _antidote_trusted=0
            fi
        else
            echo "antidote: clone failed" >&2
            _antidote_trusted=0
        fi
    fi
    (( _antidote_trusted )) && [[ -r "$ANTIDOTE_HOME/antidote.zsh" ]] &&
        _antidote_src="$ANTIDOTE_HOME/antidote.zsh"
fi

if [[ -r "$_antidote_src" ]]; then
    source "$_antidote_src"

    # Rebuild static bundle only when the plugin list changes
    if [[ -r "$_plugins_txt" ]] && [[ ! "$_plugins_zsh" -nt "$_plugins_txt" ]]; then
        antidote bundle <"$_plugins_txt" >|"$_plugins_zsh"
    fi
    [[ -r "$_plugins_zsh" ]] && source "$_plugins_zsh"
fi
unset _antidote_src _antidote_ref _antidote_commit _antidote_head _antidote_trusted _brew_prefix _plugins_txt _plugins_zsh

# Cache compinit for 24 hours using Zsh's portable stat module.
autoload -Uz compinit
zmodload zsh/stat
zmodload zsh/datetime
typeset -a _zcompdump_stat
if [[ -e "$HOME/.zcompdump" ]] &&
    zstat -A _zcompdump_stat +mtime -- "$HOME/.zcompdump" 2>/dev/null &&
    (( EPOCHSECONDS - _zcompdump_stat[1] < 86400 )); then
    compinit -C
else
    compinit
fi
unset _zcompdump_stat

# zsh-autosuggestions perf tweaks
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1
