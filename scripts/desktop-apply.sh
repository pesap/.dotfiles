#!/bin/sh

set -u

say() {
    printf '%s\n' "$*"
}

err() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

warn() {
    printf 'WARN: %s\n' "$*" >&2
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || err "need command: $1"
}

is_git_clean() {
    [ -z "$(git -C "$DOTFILES_ROOT" status --porcelain)" ]
}

detect_os() {
    case "$(uname -s 2>/dev/null || echo unknown)" in
    Linux) echo "linux" ;;
    Darwin) echo "macos" ;;
    *) echo "unknown" ;;
    esac
}

wm_process_alive() {
    case "$OS_NAME" in
    linux)
        pgrep -x mango >/dev/null 2>&1
        ;;
    macos)
        pgrep -x yabai >/dev/null 2>&1 && pgrep -x skhd >/dev/null 2>&1
        ;;
    *)
        return 1
        ;;
    esac
}

smoke_checks() {
    [ "${DOTFILES_SKIP_SMOKE:-0}" = "1" ] && return 0

    case "$OS_NAME" in
    linux)
        need_cmd mango
        if [ ! -f "$HOME/.config/mango/config.conf" ]; then
            warn "missing ~/.config/mango/config.conf after apply"
            return 1
        fi
        mango -p -c "$HOME/.config/mango/config.conf" || return 1
        wm_process_alive || return 1
        ;;
    macos)
        need_cmd yabai
        need_cmd skhd
        if ! yabai --check-config >/dev/null 2>&1; then
            warn "yabai config check failed"
            return 1
        fi
        wm_process_alive || return 1
        ;;
    *)
        return 1
        ;;
    esac
}

resolve_lkg_tag() {
    case "$OS_NAME" in
    linux) echo "lkg-wm-linux" ;;
    macos) echo "lkg-wm-macos" ;;
    *) echo "" ;;
    esac
}

resolve_packages() {
    raw="${DOTFILES_WM_PACKAGES:-mango waybar}"
    resolved=""
    for pkg in $raw; do
        if [ -d "$DOTFILES_ROOT/$pkg" ]; then
            resolved="${resolved} ${pkg}"
        fi
    done
    echo "$resolved"
}

list_package_files() {
    root="$1"
    pkg="$2"
    find "$root/$pkg" \( -type f -o -type l \) -print
}

has_effective_diff() {
    root="$1"
    for pkg in $WM_PACKAGES; do
        list_package_files "$root" "$pkg" | while IFS= read -r src; do
            rel="${src#"$root/$pkg/"}"
            dst="$HOME/$rel"

            if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
                echo 1
                return
            fi

            if [ -L "$src" ]; then
                if [ ! -L "$dst" ]; then
                    echo 1
                    return
                fi
                src_link="$(readlink "$src" 2>/dev/null || true)"
                dst_link="$(readlink "$dst" 2>/dev/null || true)"
                if [ "$src_link" != "$dst_link" ]; then
                    echo 1
                    return
                fi
            else
                if ! cmp -s "$src" "$dst"; then
                    echo 1
                    return
                fi
            fi
        done | grep -q '^1$' && return 0
    done
    return 1
}

apply_from_root() {
    root="$1"
    for pkg in $WM_PACKAGES; do
        list_package_files "$root" "$pkg" | while IFS= read -r src; do
            rel="${src#"$root/$pkg/"}"
            dst="$HOME/$rel"
            mkdir -p "$(dirname "$dst")" || return 1
            if [ -e "$dst" ] || [ -L "$dst" ]; then
                rm -rf "$dst" || return 1
            fi
            cp -a "$src" "$dst" || return 1
        done || return 1
    done
    return 0
}

rollback_from_tag() {
    tag="$1"
    tmpdir="$(mktemp -d)" || return 1

    for pkg in $WM_PACKAGES; do
        if ! git -C "$DOTFILES_ROOT" archive "$tag" "$pkg" | tar -x -C "$tmpdir"; then
            rm -rf "$tmpdir"
            return 1
        fi
    done

    # Remove files introduced by upcoming config that are not present in LKG.
    for pkg in $WM_PACKAGES; do
        list_package_files "$DOTFILES_ROOT" "$pkg" | while IFS= read -r src; do
            rel="${src#"$DOTFILES_ROOT/$pkg/"}"
            if [ ! -e "$tmpdir/$pkg/$rel" ] && [ ! -L "$tmpdir/$pkg/$rel" ]; then
                target="$HOME/$rel"
                if [ -e "$target" ] || [ -L "$target" ]; then
                    rm -rf "$target" || return 1
                fi
            fi
        done || {
            rm -rf "$tmpdir"
            return 1
        }
    done

    if ! apply_from_root "$tmpdir"; then
        rm -rf "$tmpdir"
        return 1
    fi

    rm -rf "$tmpdir"
    return 0
}

prompt_confirm() {
    [ -t 0 ] || return 1

    ans_file="$(mktemp)" || return 1
    printf 'Keep upcoming WM config? [y/N] (auto-revert in %ss): ' "$CONFIRM_TIMEOUT"

    (
        IFS= read -r ans && printf '%s' "$ans" >"$ans_file"
    ) &
    reader_pid=$!

    (
        sleep "$CONFIRM_TIMEOUT"
        kill "$reader_pid" >/dev/null 2>&1 || true
    ) &
    timer_pid=$!

    (
        while :; do
            sleep 1
            if ! wm_process_alive; then
                printf '__crash__' >"$ans_file"
                kill "$reader_pid" >/dev/null 2>&1 || true
                exit 0
            fi
            if ! smoke_checks; then
                printf '__smokefail__' >"$ans_file"
                kill "$reader_pid" >/dev/null 2>&1 || true
                exit 0
            fi
        done
    ) &
    watch_pid=$!

    wait "$reader_pid" >/dev/null 2>&1
    reader_status=$?

    kill "$timer_pid" >/dev/null 2>&1 || true
    kill "$watch_pid" >/dev/null 2>&1 || true
    wait "$timer_pid" >/dev/null 2>&1 || true
    wait "$watch_pid" >/dev/null 2>&1 || true

    answer=""
    [ -f "$ans_file" ] && answer="$(cat "$ans_file")"
    rm -f "$ans_file"

    if [ "$answer" = "__crash__" ]; then
        warn "WM process crashed during confirmation gate"
        return 1
    fi

    if [ "$answer" = "__smokefail__" ]; then
        warn "smoke checks failed during confirmation gate"
        return 1
    fi

    if [ "$reader_status" -ne 0 ]; then
        warn "confirmation timed out"
        return 1
    fi

    case "$answer" in
    y | Y | yes | YES)
        return 0
        ;;
    *)
        return 1
        ;;
    esac
}

promote_lkg() {
    git -C "$DOTFILES_ROOT" tag -f "$LKG_TAG" "$HEAD_COMMIT" >/dev/null 2>&1
}

YES_MODE=0
ACTION="run"
for arg in "$@"; do
    case "$arg" in
    run) ACTION="run" ;;
    --yes) YES_MODE=1 ;;
    --help | -h)
        cat <<'EOF'
Usage: mise run desktop:apply [--yes]

Applies WM-scoped dotfiles safely.
- No effective WM diff: exits success, no confirmation gate.
- Effective WM diff: applies config, runs smoke checks, then:
  - interactive mode: asks y/N with 30s timeout
  - --yes mode: auto-confirms immediately after smoke checks pass

Environment:
  DOTFILES_ROOT         Dotfiles checkout root (default: ~/.dotfiles)
  DOTFILES_WM_PACKAGES  WM package list (default: "mango waybar")
  DOTFILES_CONFIRM_TIMEOUT  Gate timeout seconds (default: 30)
  DOTFILES_SKIP_SMOKE   Set to 1 to skip smoke checks (testing only)
EOF
        exit 0
        ;;
    *)
        err "unknown argument: $arg (expected: run, --yes, --help)"
        ;;
    esac
done

[ "$ACTION" = "run" ] || err "unsupported action: $ACTION"

DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
CONFIRM_TIMEOUT="${DOTFILES_CONFIRM_TIMEOUT:-30}"

need_cmd git
need_cmd cmp
need_cmd cp
need_cmd rm
need_cmd mktemp
need_cmd tar
need_cmd pgrep

[ -d "$DOTFILES_ROOT/.git" ] || err "DOTFILES_ROOT is not a git repo: $DOTFILES_ROOT"

OS_NAME="$(detect_os)"
[ "$OS_NAME" != "unknown" ] || err "unsupported OS"

LKG_TAG="$(resolve_lkg_tag)"
[ -n "$LKG_TAG" ] || err "could not resolve LKG tag"

WM_PACKAGES="$(resolve_packages)"
[ -n "$WM_PACKAGES" ] || err "no WM packages found under $DOTFILES_ROOT (checked: ${DOTFILES_WM_PACKAGES:-mango waybar})"

is_git_clean || err "working tree must be clean before desktop apply (commit/stash first)"
HEAD_COMMIT="$(git -C "$DOTFILES_ROOT" rev-parse HEAD 2>/dev/null)" || err "failed to resolve HEAD"

if ! has_effective_diff "$DOTFILES_ROOT"; then
    say "desktop apply: no effective WM diff; nothing to apply"
    if ! git -C "$DOTFILES_ROOT" rev-parse -q --verify "refs/tags/$LKG_TAG" >/dev/null 2>&1; then
        promote_lkg || err "failed to initialize LKG tag: $LKG_TAG"
        say "initialized LKG anchor: $LKG_TAG -> $HEAD_COMMIT"
    fi
    exit 0
fi

if ! git -C "$DOTFILES_ROOT" rev-parse -q --verify "refs/tags/$LKG_TAG" >/dev/null 2>&1; then
    err "missing LKG anchor tag '$LKG_TAG'. First run with already-applied config to initialize anchor."
fi

say "desktop apply: applying WM packages:$WM_PACKAGES"
apply_from_root "$DOTFILES_ROOT" || err "failed to apply upcoming WM configuration"

if ! smoke_checks; then
    warn "smoke checks failed; rolling back immediately"
    rollback_from_tag "$LKG_TAG" || err "rollback failed"
    smoke_checks || warn "post-rollback smoke checks failed"
    exit 1
fi

if [ "$YES_MODE" = "1" ]; then
    promote_lkg || err "failed to promote LKG tag"
    say "confirmed (--yes). promoted $LKG_TAG -> $HEAD_COMMIT"
    exit 0
fi

if prompt_confirm; then
    promote_lkg || err "failed to promote LKG tag"
    say "confirmed. promoted $LKG_TAG -> $HEAD_COMMIT"
    exit 0
fi

warn "not confirmed; rolling back"
rollback_from_tag "$LKG_TAG" || err "rollback failed"
smoke_checks || warn "post-rollback smoke checks failed"
exit 1
