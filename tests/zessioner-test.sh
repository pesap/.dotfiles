#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
picker="$repo_root/bin/.local/bin/zessioner"
test_dir=$(mktemp -d /var/tmp/dotfiles-test.zessioner.XXXXXX)

cleanup() {
    status=$?
    trap - EXIT HUP INT TERM
    case "$test_dir" in
    /var/tmp/dotfiles-test.zessioner.*)
        [[ -d "$test_dir" && ! -L "$test_dir" ]] && rm -rf -- "$test_dir"
        ;;
    *)
        printf 'refusing to clean unexpected test path: %s\n' "$test_dir" >&2
        status=1
        ;;
    esac
    exit "$status"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$test_dir/home/bin/project" "$test_dir/home/bin/other" "$test_dir/fake-bin"

cat >"$test_dir/adapter" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  --rows)
    printf 'fake\tctx-current\t%s\tcurrent-context\tcurrent\t0\tcurrent\n' "$HOME/bin/project"
    ;;
  --select)
    printf '%s:%s:%s\n' "${3:-}" "${4:-}" "${5:-}" > "${PICKER_TEST_RESULT:?}"
    ;;
  --close)
    printf 'closed:%s\n' "${2:-}" > "${PICKER_TEST_RESULT:?}"
    ;;
  *) exit 2 ;;
esac
EOF

cat >"$test_dir/fake-bin/zoxide" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$HOME/bin/project" "$HOME/bin/other"
EOF

cat >"$test_dir/fake-bin/fzf" <<'EOF'
#!/usr/bin/env bash
if [[ -n "${PICKER_TEST_SELECT_PROJECT:-}" ]]; then
  awk -F '\t' '$1 == "project" { print; exit }'
else
  head -n 1
fi
EOF

chmod +x "$test_dir/adapter" "$test_dir/fake-bin/zoxide" "$test_dir/fake-bin/fzf"

rows=$(HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" ZESSIONER_ROOTS="$test_dir/home/bin" "$picker" --adapter "$test_dir/adapter" --rows)
[[ "$(printf '%s\n' "$rows" | sed -n '1p' | cut -f2)" == ctx-current ]]
[[ "$(printf '%s\n' "$rows" | awk -F '\t' '$1 == "project" { c++ } END { print c+0 }')" == 1 ]]
awk -F '\t' '$1 == "project" && $2 == "-" && $3 ~ /\/other$/ { found=1 } END { exit !found }' <<<"$rows"

HOME="$test_dir/home" PATH="$test_dir/fake-bin:$PATH" ZESSIONER_ROOTS="$test_dir/home/bin" PICKER_TEST_RESULT="$test_dir/result" \
    PICKER_TEST_SELECT_PROJECT=1 "$picker" --adapter "$test_dir/adapter"
[[ "$(<"$test_dir/result")" == ":${test_dir}/home/bin/other:other" ]]

printf 'zessioner tests: ok\n'
