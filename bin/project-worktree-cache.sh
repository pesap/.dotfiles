#!/usr/bin/env bash
# A cache miss always leaves Git as the authority. No session or allowlist data is stored.

project_cache_paths=('')
project_cache_links=('')
project_cache_roots=('')
project_cache_checked=(0)
project_cache_loaded=false
project_cache_file=''
project_cache_now=0
project_cache_refreshing=false
project_cache_refresh_started=false
project_cache_refresh_after=10
project_cache_max_age=300

project_cache_load() {
    local cache_root cache_dir checkout git_link primary checked_at
    [[ "$project_cache_loaded" == false ]] || return 0
    project_cache_loaded=true
    [[ "${PROJECT_PICKER_CACHE:-1}" != 0 ]] || return 0

    if [[ -n "${XDG_CACHE_HOME:-}" ]]; then
        cache_root=$XDG_CACHE_HOME
    elif [[ "$OSTYPE" == darwin* ]]; then
        cache_root=$HOME/Library/Caches
    else
        cache_root=$HOME/.cache
    fi
    [[ "$cache_root" == /* ]] || return 0
    cache_dir=$cache_root/project-picker
    [[ ! -L "$cache_dir" ]] || return 0
    (
        umask 077
        mkdir -p -- "$cache_dir"
    ) 2>/dev/null || return 0
    [[ -O "$cache_dir" ]] || return 0
    chmod 700 "$cache_dir" 2>/dev/null || return 0
    project_cache_file=$cache_dir/worktrees.json
    if [[ -L "$project_cache_file" || (-e "$project_cache_file" && ! -f "$project_cache_file") ]]; then
        project_cache_file=''
        return 0
    fi
    project_cache_now=$(date +%s) || {
        project_cache_file=''
        return 0
    }
    [[ "$project_cache_now" =~ ^[0-9]+$ ]] || {
        project_cache_file=''
        return 0
    }
    [[ -r "$project_cache_file" ]] || return 0

    while IFS= read -r -d '' checkout && IFS= read -r -d '' git_link &&
        IFS= read -r -d '' primary && IFS= read -r -d '' checked_at; do
        project_cache_paths+=("$checkout")
        project_cache_links+=("$git_link")
        project_cache_roots+=("$primary")
        project_cache_checked+=("$checked_at")
    done < <(jq -j --argjson now "$project_cache_now" --argjson max_age "$project_cache_max_age" '
        if type == "object" and .version == 1 and (.entries | type) == "array" then
            .entries[]
        else empty end
        | select(type == "object")
        | select(([.checkout, .git_link, .primary] | all(type == "string")))
        | select(([.checkout, .git_link, .primary] | all(index("\u0000") == null)))
        | select((.checkout | startswith("/")) and (.primary | startswith("/")))
        | select((.checked_at | type) == "number")
        | select(.checked_at == (.checked_at | floor) and .checked_at >= $now - $max_age and .checked_at <= $now)
        | .checkout, "\u0000", .git_link, "\u0000", .primary, "\u0000", (.checked_at | tostring), "\u0000"
    ' "$project_cache_file" 2>/dev/null)
}

project_cache_get() {
    local checkout=$1 git_link=$2 index
    project_cache_load
    [[ "$project_cache_refreshing" == false ]] || return 1
    for ((index = 1; index < ${#project_cache_paths[@]}; index++)); do
        if [[ "$checkout" == "${project_cache_paths[index]}" &&
            "$git_link" == "${project_cache_links[index]}" && -d "${project_cache_roots[index]}" ]]; then
            # shellcheck disable=SC2034 # Shared result consumed by project-paths.sh.
            project_path=${project_cache_roots[index]}
            if [[ "${project_cache_checked[index]}" -gt 0 &&
                "$((project_cache_now - project_cache_checked[index]))" -ge "$project_cache_refresh_after" &&
                "$project_cache_refresh_started" == false ]]; then
                project_cache_refresh_started=true
                project_cache_refresh </dev/null >/dev/null 2>&1 &
            fi
            return 0
        fi
    done
    return 1
}

project_cache_store() (
    local cache_dir stage index
    [[ -n "$project_cache_file" ]] || exit 0
    cache_dir=${project_cache_file%/*}
    # Never recreate a deleted cache directory from a detached refresh process.
    [[ -d "$cache_dir" && ! -L "$cache_dir" && ! -L "$project_cache_file" && ! -d "$project_cache_file" ]] || exit 0
    umask 077
    stage=$(mktemp "$cache_dir/.worktrees.XXXXXX") || exit 0
    trap 'rm -f -- "$stage"' EXIT
    trap 'exit 0' HUP INT TERM
    if {
        for ((index = 1; index < ${#project_cache_paths[@]}; index++)); do
            [[ "${project_cache_checked[index]}" -gt 0 ]] || continue
            printf '%s\0%s\0%s\0%s\0' "${project_cache_paths[index]}" "${project_cache_links[index]}" \
                "${project_cache_roots[index]}" "${project_cache_checked[index]}"
        done
    } | jq -Rsc --argjson now "$project_cache_now" --argjson max_age "$project_cache_max_age" '
        split("\u0000") | .[:-1]
        | [range(0; length; 4) as $i | .[$i:$i+4]
            | {checkout: .[0], git_link: .[1], primary: .[2], checked_at: (.[3] | tonumber)}
            | select(.checked_at >= $now - $max_age)]
        | group_by(.checkout) | map(max_by(.checked_at))
        | {version: 1, entries: .}
    ' >"$stage"; then
        mv -f -- "$stage" "$project_cache_file"
    fi
)

project_cache_refresh() {
    local index count=${#project_cache_paths[@]}
    project_cache_refreshing=true
    for ((index = 1; index < count; index++)); do
        [[ "${project_cache_checked[index]}" -gt 0 &&
            "$((project_cache_now - project_cache_checked[index]))" -ge "$project_cache_refresh_after" ]] || continue
        project_resolve_path "${project_cache_paths[index]}" || continue
    done
    project_cache_store >/dev/null 2>&1 || true
}

project_cache_put() {
    local checkout=$1 git_link=$2 primary=$3 verified=$4 current_link='' checked_at=0
    IFS= read -r -d '' current_link <"$checkout/.git" || true
    # Do not save a mapping if the repository changed during the Git query.
    [[ "$current_link" == "$git_link" ]] || return 0
    if [[ "$verified" == true && -n "$project_cache_file" ]]; then
        checked_at=$project_cache_now
    fi
    project_cache_paths+=("$checkout")
    project_cache_links+=("$git_link")
    project_cache_roots+=("$primary")
    project_cache_checked+=("$checked_at")
    if [[ "$checked_at" -gt 0 && "$project_cache_refreshing" == false ]]; then
        project_cache_store >/dev/null 2>&1 || true
    fi
}
