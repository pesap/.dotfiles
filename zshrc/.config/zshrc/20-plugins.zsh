# Plugin management via antidote
#
# Bootstrap order:
#   1. Locate antidote (brew on macOS, ~/.antidote git clone elsewhere).
#   2. Auto-clone if missing so fresh machines just work.
#   3. Rebuild the static bundle iff ~/.zsh_plugins.txt is newer than the cache.
#   4. Source the cached bundle (single static file → fast cold start).

ANTIDOTE_HOME="${ANTIDOTE_HOME:-$HOME/.antidote}"
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
        git clone --depth=1 https://github.com/mattmc3/antidote.git "$ANTIDOTE_HOME"
    fi
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
unset _antidote_src _brew_prefix _plugins_txt _plugins_zsh

# Daily-cached compinit (rebuild dump at most once per day)
autoload -Uz compinit
if [[ "$(date +'%j')" != "$(stat -f '%Sm' -t '%j' ~/.zcompdump 2>/dev/null)" ]]; then
    compinit
else
    compinit -C
fi

# zsh-autosuggestions perf tweaks
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE="20"
ZSH_AUTOSUGGEST_USE_ASYNC=1
