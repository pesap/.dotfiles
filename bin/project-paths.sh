#!/usr/bin/env bash
# Shared discovery for both project pickers. This file is sourced, not executed.

# shellcheck source=bin/project-worktree-cache.sh
source "${BASH_SOURCE[0]%/*}/project-worktree-cache.sh"

# Set project_path to a physical directory or a Git worktree's primary checkout.
# Only linked checkouts need Git. Their mappings can be reused across picker openings.
project_resolve_path() {
    local path=$1 current field checkout='' bare=false original_dir=$PWD git_link='' verified=false
    local OLDPWD
    project_path=''
    [[ -d "$path" ]] || return 1
    # Resolve symlinks without forking a shell for every folder.
    cd -P -- "$path" || return 1
    path=$PWD
    if ! cd -- "$original_dir"; then
        printf 'project-paths: cannot restore working directory: %s\n' "$original_dir" >&2
        exit 1
    fi
    current=$path
    while [[ "$current" != / ]]; do
        if [[ -d "$current/.git" ]]; then
            project_path=$current
            break
        elif [[ -f "$current/.git" ]]; then
            IFS= read -r -d '' git_link <"$current/.git" || true
            if project_cache_get "$current" "$git_link"; then
                return 0
            fi
            # A broken Git link must not hide a pinned folder or saved session.
            project_path=$current
            while IFS= read -r -d '' field; do
                case "$field" in
                'worktree '*) checkout=${field#worktree } ;;
                bare) bare=true ;;
                '')
                    if [[ "$bare" == false ]]; then
                        if [[ -d "$checkout" ]]; then
                            project_path=$checkout
                            verified=true
                        fi
                        break
                    fi
                    bare=false
                    ;;
                esac
            done < <(git -C "$current" worktree list --porcelain -z 2>/dev/null)
            project_cache_put "$current" "$git_link" "$project_path" "$verified"
            break
        fi
        current=${current%/*}
        [[ -n "$current" ]] || current=/
    done
    [[ -n "$project_path" ]] || project_path=$path
}

project_emit_path() {
    local path=$1
    [[ "$path" != *$'\n'* && "$path" != *$'\r'* ]] || return 0
    project_resolve_path "$path" || return 0
    [[ "$project_path" != *$'\n'* && "$project_path" != *$'\r'* ]] || return 0
    printf '%s\n' "$project_path"
}

# Each line is an absolute or ~/ path. A final /* lists immediate child folders.
# No recursion, shell evaluation, cached candidate lists, or implicit search roots.
project_discover_paths() {
    local paths_file=$1 path child known_paths
    [[ -r "$paths_file" ]] || {
        printf 'project-dirs: cannot read project paths file: %s\n' "$paths_file" >&2
        return 1
    }
    known_paths=$(zoxide query --list) || {
        printf 'project-dirs: zoxide could not list known directories\n' >&2
        return 1
    }
    {
        while IFS= read -r path || [[ -n "$path" ]]; do
            path=${path%$'\r'}
            case "$path" in
            '' | \#*) continue ;;
            \~/*) path=${HOME%/}/${path:2} ;;
            /*) ;;
            *)
                printf 'project-dirs: use an absolute or ~/ path: %s\n' "$path" >&2
                return 1
                ;;
            esac
            if [[ "$path" == */\* ]]; then
                for child in "${path%/\*}"/*; do
                    project_emit_path "$child"
                done
            else
                project_emit_path "$path"
            fi
        done <"$paths_file"
    } | awk '
        FILENAME != "-" {
            if ($0 != "") recent[++recent_count] = $0
            next
        }
        !seen[$0]++ { allowed[++allowed_count] = $0 }
        END {
            # Zoxide ranks configured projects, including visits to subfolders.
            # It never supplies candidates. Unvisited entries keep file order.
            for (r = 1; r <= recent_count; r++) {
                for (p = 1; p <= allowed_count; p++) {
                    if (!emitted[p] && (recent[r] == allowed[p] ||
                        index(recent[r], allowed[p] "/") == 1)) {
                        print allowed[p]
                        emitted[p] = 1
                    }
                }
            }
            for (p = 1; p <= allowed_count; p++)
                if (!emitted[p]) print allowed[p]
        }
    ' <(printf '%s\n' "$known_paths") -
}
