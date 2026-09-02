#!/usr/bin/env bash
# Run the dotfiles installer in an isolated, disposable Linux container.
set -Eeuo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
scenario='fresh'
distro='ubuntu'
profile='common'
source_mode='local'
with_tools=0
inside=0
matrix=0
image=''
container_name=''
dns_servers=()

usage() {
    cat <<'EOF'
Usage: test-podman.sh [OPTIONS]

Run the dotfiles installer in a disposable Podman container.

Options:
  --scenario SCENARIO  fresh or existing (default: fresh)
  --distro DISTRO      ubuntu, debian, fedora, arch, or opensuse
  --profile PROFILE    Dotfiles profile (default: common)
  --source SOURCE      local checkout or release bootstrap (default: local)
  --with-tools         Install all locked mise tools after setup
  --matrix              Run all supported Linux distributions
  --image IMAGE        Override the container image
  --inside              Internal entry point used inside the container
  -h, --help            Show this help

Examples:
  test-podman.sh --scenario fresh --distro ubuntu
  test-podman.sh --scenario existing --distro fedora --with-tools
  test-podman.sh --matrix
EOF
}

fail() {
    printf 'podman-test: %s\n' "$*" >&2
    exit 2
}

parse_args() {
    while (($#)); do
        case "$1" in
        --scenario)
            (($# >= 2)) || fail '--scenario requires a value'
            scenario="$2"
            shift
            ;;
        --scenario=*) scenario="${1#--scenario=}" ;;
        --distro)
            (($# >= 2)) || fail '--distro requires a value'
            distro="$2"
            shift
            ;;
        --distro=*) distro="${1#--distro=}" ;;
        --profile)
            (($# >= 2)) || fail '--profile requires a value'
            profile="$2"
            shift
            ;;
        --profile=*) profile="${1#--profile=}" ;;
        --source)
            (($# >= 2)) || fail '--source requires a value'
            source_mode="$2"
            shift
            ;;
        --source=*) source_mode="${1#--source=}" ;;
        --with-tools) with_tools=1 ;;
        --matrix) matrix=1 ;;
        --image)
            (($# >= 2)) || fail '--image requires a value'
            image="$2"
            shift
            ;;
        --image=*) image="${1#--image=}" ;;
        --inside) inside=1 ;;
        -h | --help)
            usage
            exit 0
            ;;
        *) fail "unknown option: $1" ;;
        esac
        shift
    done
}

validate_args() {
    case "$scenario" in
    fresh | existing) ;;
    *) fail "unsupported scenario: $scenario" ;;
    esac

    case "$profile" in
    common | linux-desktop) ;;
    *) fail "unsupported Linux profile: $profile" ;;
    esac

    case "$source_mode" in
    local | release) ;;
    *) fail "unsupported source mode: $source_mode" ;;
    esac

    case "$distro" in
    ubuntu | debian | fedora | arch | opensuse) ;;
    *) fail "unsupported distro: $distro" ;;
    esac
}

image_for_distro() {
    case "$distro" in
    ubuntu) printf '%s\n' "${DOTFILES_TEST_UBUNTU_IMAGE:-ubuntu:24.04}" ;;
    debian) printf '%s\n' "${DOTFILES_TEST_DEBIAN_IMAGE:-debian:bookworm-slim}" ;;
    fedora) printf '%s\n' "${DOTFILES_TEST_FEDORA_IMAGE:-fedora:latest}" ;;
    arch) printf '%s\n' "${DOTFILES_TEST_ARCH_IMAGE:-archlinux:base}" ;;
    opensuse) printf '%s\n' "${DOTFILES_TEST_OPENSUSE_IMAGE:-opensuse/tumbleweed}" ;;
    esac
}

add_dns_server() {
    local candidate="${1//[[:space:]]/}"
    local existing=''

    [[ -n "$candidate" && "$candidate" != -* ]] || return 0
    [[ "$candidate" =~ ^[0-9A-Fa-f:.]+$ ]] || return 0
    for existing in "${dns_servers[@]}"; do
        [[ "$existing" == "$candidate" ]] && return 0
    done
    dns_servers+=("$candidate")
}

discover_dns_servers() {
    local device='' type='' state='' dns=''

    if [[ -n "${DOTFILES_TEST_DNS:-}" ]]; then
        local -a requested_dns=()
        IFS=',' read -r -a requested_dns <<<"$DOTFILES_TEST_DNS"
        for dns in "${requested_dns[@]}"; do
            add_dns_server "$dns"
        done
        ((${#dns_servers[@]} > 0)) ||
            fail 'DOTFILES_TEST_DNS must contain one or more DNS server IP addresses'
        printf 'podman-test: dns=%s source=DOTFILES_TEST_DNS\n' \
            "$(
                IFS=,
                printf '%s' "${dns_servers[*]}"
            )"
        return 0
    fi

    if command -v nmcli >/dev/null 2>&1; then
        while IFS=: read -r device type state; do
            [[ "$state" == connected* ]] || continue
            case "$type" in
            tun | loopback | bridge) continue ;;
            esac
            while IFS= read -r dns; do
                add_dns_server "$dns"
            done < <(
                nmcli -g IP4.DNS,IP6.DNS device show "$device" 2>/dev/null |
                    tr '|' '\n'
            )
        done < <(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null)
    fi

    if ((${#dns_servers[@]} > 0)); then
        printf 'podman-test: dns=%s source=NetworkManager\n' \
            "$(
                IFS=,
                printf '%s' "${dns_servers[*]}"
            )"
    else
        printf 'podman-test: dns=podman-default\n'
    fi
}

run_outer() {
    command -v podman >/dev/null 2>&1 || fail 'podman is required on the host'

    if ((matrix)); then
        local matrix_distro=''
        local status=0
        local -a matrix_args=(--source "$source_mode")
        ((with_tools)) && matrix_args+=(--with-tools)
        [[ -n "$image" ]] && matrix_args+=(--image "$image")
        for matrix_distro in ubuntu debian fedora arch opensuse; do
            if ! "$0" --scenario "$scenario" --distro "$matrix_distro" \
                --profile "$profile" "${matrix_args[@]}"; then
                status=1
            fi
        done
        return "$status"
    fi

    validate_args
    [[ -n "$image" ]] || image="$(image_for_distro)"
    container_name="dotfiles-test-${scenario}-${distro}-$$"

    if podman container exists "$container_name"; then
        fail "container name is already in use: $container_name"
    fi

    discover_dns_servers
    printf 'podman-test: distro=%s image=%s scenario=%s source=%s tools=%s\n' \
        "$distro" "$image" "$scenario" "$source_mode" "$with_tools"
    printf 'podman-test: checkout mounted read-only at /input\n'

    cleanup() {
        local status=$?
        trap - EXIT HUP INT TERM
        if [[ -n "$container_name" ]] && podman container exists "$container_name"; then
            podman rm --force "$container_name" >/dev/null || status=1
        fi
        exit "$status"
    }
    trap cleanup EXIT HUP INT TERM

    local -a command=(
        podman run
        --rm
        --userns=keep-id
        --user 0:0
        --name "$container_name"
        --volume "$repo_root:/input:ro"
        --env "DOTFILES_TEST_SCENARIO=$scenario"
        --env "DOTFILES_TEST_DISTRO=$distro"
        --env "DOTFILES_TEST_PROFILE=$profile"
        --env "DOTFILES_TEST_SOURCE=$source_mode"
        --env "DOTFILES_TEST_WITH_TOOLS=$with_tools"
    )
    local dns_server=''
    for dns_server in "${dns_servers[@]}"; do
        command+=(--dns "$dns_server")
    done
    command+=(
        "$image"
        /bin/bash
        /input/scripts/test-podman.sh
        --inside
    )
    local started finished status
    started="$(date +%s%3N)"
    if "${command[@]}"; then
        status=0
    else
        status=$?
    fi
    finished="$(date +%s%3N)"
    printf 'podman-test: phase=container-total seconds=%d.%03d status=%s\n' \
        "$(((finished - started) / 1000))" "$(((finished - started) % 1000))" "$status"
    return "$status"
}

install_base_packages() {
    local -a packages=(ca-certificates curl findutils git rsync sudo tar unzip)
    if ((with_tools)); then
        case "${ID:-}" in
        ubuntu | debian) packages+=(openssh-client python3 zsh) ;;
        fedora | opensuse*) packages+=(openssh-clients python3 zsh) ;;
        arch) packages+=(openssh python zsh) ;;
        esac
    fi
    if [[ "$source_mode" == local ]]; then
        packages+=(make perl)
        case "${ID:-}" in
        ubuntu | debian) packages+=(build-essential libatomic1) ;;
        fedora) packages+=(gcc gcc-c++ libatomic) ;;
        arch) packages+=(base-devel) ;;
        opensuse*) packages+=(gcc gcc-c++ libatomic1) ;;
        esac
    fi

    case "${ID:-}" in
    ubuntu | debian)
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        apt-get install --yes --no-install-recommends "${packages[@]}"
        ;;
    fedora)
        dnf install --assumeyes "${packages[@]}"
        ;;
    arch)
        pacman --sync --refresh --noconfirm "${packages[@]}"
        ;;
    opensuse*)
        zypper --non-interactive refresh
        zypper --non-interactive install --no-recommends "${packages[@]}"
        ;;
    *) fail "unsupported container OS: ${ID:-unknown}" ;;
    esac
}

create_test_user() {
    local test_user='dotfiles-test'
    local test_home="/home/$test_user"

    useradd --create-home --shell /bin/bash "$test_user"
    printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$test_user" >/etc/sudoers.d/dotfiles-test
    chmod 0440 /etc/sudoers.d/dotfiles-test
    mkdir -p -- "$test_home/.config"
    chown -R "$test_user:$test_user" "$test_home"
}

seed_existing_home() {
    local test_home='/home/dotfiles-test'

    mkdir -p -- "$test_home/.config/alacritty"
    printf 'existing shell configuration\n' >"$test_home/.zshrc"
    printf 'existing Bash configuration\n' >"$test_home/.bashrc"
    printf 'existing Bash login configuration\n' >"$test_home/.bash_profile"
    printf 'existing terminal configuration\n' >"$test_home/.config/alacritty/local.toml"
    chown -R dotfiles-test:dotfiles-test "$test_home"
    printf 'podman-test: seeded existing configuration files\n'
}

run_as_test_user() {
    local test_home='/home/dotfiles-test'
    local test_path="$test_home/.local/bin:$test_home/.cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    sudo --non-interactive --set-home --user dotfiles-test \
        env HOME="$test_home" PATH="$test_path" "$@"
}

prepare_local_source() {
    local source_dir

    source_dir="$(mktemp -d /var/tmp/dotfiles-test.source.XXXXXX)"
    rsync -a \
        --exclude='.git' \
        --exclude='personal' \
        --exclude='plans' \
        --exclude='hermes/.config' \
        --exclude='hermes/.hermes/SOUL.md' \
        --exclude='bin/.local/bin/palworld-pal-editor' \
        /input/ "$source_dir/"
    chown -R dotfiles-test:dotfiles-test "$source_dir"
    printf '%s\n' "$source_dir"
}

install_local_mise() {
    local test_home='/home/dotfiles-test'
    local installer="$test_home/mise-install.sh"

    run_as_test_user curl --silent --show-error --fail --location \
        https://mise.run --output "$installer"
    run_as_test_user env MISE_INSTALL_PATH="$test_home/.local/bin/mise" \
        sh "$installer"
    run_as_test_user rm -f -- "$installer"
}

measure_phase() {
    local label="$1"
    shift
    local started finished status elapsed

    started="$(date +%s%3N)"
    if "$@"; then
        status=0
    else
        status=$?
    fi
    finished="$(date +%s%3N)"
    elapsed=$((finished - started))
    printf 'podman-test: phase=%s seconds=%d.%03d status=%s\n' \
        "$label" "$((elapsed / 1000))" "$((elapsed % 1000))" "$status"
    return "$status"
}

verify_setup() {
    local test_home='/home/dotfiles-test'
    local backup=''

    if [[ "$source_mode" == release ]]; then
        [[ -d "$test_home/.dotfiles" ]] || fail 'installer did not create ~/.dotfiles'
    fi
    [[ -L "$test_home/.zshrc" ]] || fail 'installer did not link ~/.zshrc'
    [[ -L "$test_home/.bashrc" ]] || fail 'installer did not link ~/.bashrc'
    [[ -L "$test_home/.bash_profile" ]] || fail 'installer did not link ~/.bash_profile'
    [[ -L "$test_home/.config/alacritty/local.toml" ]] ||
        fail 'installer did not link the Alacritty overlay'

    if [[ "$scenario" == existing ]]; then
        backup="$(find "$test_home/.stow-backup" -type f -path '*/.zshrc' -print -quit 2>/dev/null || true)"
        [[ -n "$backup" ]] || fail 'installer did not back up the existing .zshrc'
        backup="$(find "$test_home/.stow-backup" -type f -path '*/.bashrc' -print -quit 2>/dev/null || true)"
        [[ -n "$backup" ]] || fail 'installer did not back up the existing .bashrc'
        backup="$(find "$test_home/.stow-backup" -type f -path '*/.bash_profile' -print -quit 2>/dev/null || true)"
        [[ -n "$backup" ]] || fail 'installer did not back up the existing .bash_profile'
    fi
}

verify_bash_tool_path() {
    local test_home='/home/dotfiles-test'
    local check_script=''
    local -a tools=(
        atuin bat cargo codex fd fzf gitleaks gh hermes hermes-acp hermes-agent
        herdr jq julia just lsd lua-language-server navi node npm nvim ollama pi
        prek rg ruff rust-analyzer rustc rustup shellcheck shfmt starship stylua
        uv vicinae wt
        yazi zoxide
    )

    # shellcheck disable=SC2016
    check_script='
        set -eu
        for tool in "$@"; do
            tool_path="$(command -v "$tool" 2>/dev/null || true)"
            [[ -n "$tool_path" ]] || {
                printf "podman-test: missing Bash PATH tool: %s\\n" "$tool" >&2
                exit 1
            }
            printf "podman-test: bash-path tool=%s path=%s\\n" "$tool" "$tool_path"
        done
    '

    run_as_test_user env \
        MISE_CONFIG_FILE="$test_home/.config/mise/config.toml" \
        MISE_TRUSTED_CONFIG_PATHS="$test_home/.config/mise" \
        bash --noprofile --rcfile "$test_home/.bashrc" -i -c "$check_script" \
        bash-rcfile "${tools[@]}"
    run_as_test_user env \
        MISE_CONFIG_FILE="$test_home/.config/mise/config.toml" \
        MISE_TRUSTED_CONFIG_PATHS="$test_home/.config/mise" \
        bash --login -i -c "$check_script" bash-login "${tools[@]}"
}

run_inner() {
    local test_home='/home/dotfiles-test'
    local profile_arg=(--profile "$profile")

    [[ "${EUID:-$(id -u)}" -eq 0 ]] || fail 'container entry point must run as root'
    [[ -f /etc/os-release ]] || fail 'container has no /etc/os-release'
    # shellcheck disable=SC1091
    source /etc/os-release

    printf 'podman-test: container_os=%s version=%s\n' "${ID:-unknown}" "${VERSION_ID:-unknown}"
    measure_phase prerequisites install_base_packages
    create_test_user
    [[ "$scenario" == existing ]] && seed_existing_home

    local source_root='/input'
    if [[ "$source_mode" == local ]]; then
        source_root="$(prepare_local_source)"
    fi

    if [[ "$source_mode" == release ]]; then
        measure_phase bootstrap \
            run_as_test_user sh /input/bootstrap.sh "${profile_arg[@]}" --yes
    else
        measure_phase mise-bootstrap install_local_mise
        measure_phase setup \
            run_as_test_user env LOCAL_SOURCE="$source_root" sh "$source_root/install.sh" \
            --local "${profile_arg[@]}" --yes
    fi
    verify_setup

    measure_phase machine-check \
        run_as_test_user "$test_home/.local/bin/loom" check --machine

    if ((with_tools)); then
        measure_phase mise-install \
            run_as_test_user "$test_home/.local/bin/loom" tools install
        measure_phase mise-reshim \
            run_as_test_user env MISE_CONFIG_FILE="$test_home/.config/mise/config.toml" \
            "$test_home/.local/bin/mise" reshim
        measure_phase bash-path-check verify_bash_tool_path
        measure_phase repository-check \
            run_as_test_user "$test_home/.local/bin/loom" check --repo
    else
        printf 'podman-test: phase=mise-install status=skipped\n'
        printf 'podman-test: phase=repository-check status=skipped\n'
    fi

    measure_phase reapply \
        run_as_test_user "$test_home/.local/bin/loom" apply "${profile_arg[@]}"
    printf 'podman-test: result=ok\n'
}

parse_args "$@"
if ((inside)); then
    profile="${DOTFILES_TEST_PROFILE:-$profile}"
    scenario="${DOTFILES_TEST_SCENARIO:-$scenario}"
    distro="${DOTFILES_TEST_DISTRO:-$distro}"
    source_mode="${DOTFILES_TEST_SOURCE:-$source_mode}"
    with_tools="${DOTFILES_TEST_WITH_TOOLS:-$with_tools}"
    validate_args
    run_inner
else
    run_outer
fi
