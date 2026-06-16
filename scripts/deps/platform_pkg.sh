#!/usr/bin/env bash
# 平台包管理器封装（apt/pacman/brew/winget；不走 HTTP 代理）

# 参数: brew_name apt_name pacman_name [winget_id]
pkg_install() {
    local brew_name="${1:-}" apt_name="${2:-}" pacman_name="${3:-}" winget_id="${4:-}"
    case "${PKG_MANAGER:-}" in
        brew)
            [[ -n "${brew_name}" ]] && brew install "${brew_name}"
            ;;
        apt)
            [[ -n "${apt_name}" ]] && sudo apt-get install -y "${apt_name}"
            ;;
        pacman)
            if [[ "${PLATFORM}" == "windows" ]]; then
                [[ -n "${pacman_name}" ]] && pacman.exe -S --noconfirm "${pacman_name}"
            else
                [[ -n "${pacman_name}" ]] && sudo pacman -S --noconfirm "${pacman_name}"
            fi
            ;;
        dnf)
            [[ -n "${apt_name}" ]] && sudo dnf install -y "${apt_name}"
            ;;
        yum)
            [[ -n "${apt_name}" ]] && sudo yum install -y "${apt_name}"
            ;;
        winget)
            [[ -n "${winget_id}" ]] && winget install --id "${winget_id}" -e \
                --source winget \
                --accept-package-agreements --accept-source-agreements 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

pkg_upgrade() {
    local brew_name="${1:-}" apt_name="${2:-}" pacman_name="${3:-}" winget_id="${4:-}"
    case "${PKG_MANAGER:-}" in
        brew)
            if [[ -n "${brew_name}" ]] && brew list "${brew_name}" >/dev/null 2>&1; then
                brew upgrade "${brew_name}" 2>/dev/null || true
            fi
            ;;
        apt)
            if [[ -n "${apt_name}" ]]; then
                sudo apt-get install -y --only-upgrade "${apt_name}" 2>/dev/null || \
                    sudo apt-get install -y "${apt_name}" 2>/dev/null || true
            fi
            ;;
        pacman)
            if [[ -n "${pacman_name}" ]]; then
                if [[ "${PLATFORM}" == "windows" ]]; then
                    pacman.exe -S --needed --noconfirm "${pacman_name}" 2>/dev/null || true
                else
                    sudo pacman -S --needed --noconfirm "${pacman_name}" 2>/dev/null || true
                fi
            fi
            ;;
        dnf)
            [[ -n "${apt_name}" ]] && sudo dnf upgrade -y "${apt_name}" 2>/dev/null || true
            ;;
        yum)
            [[ -n "${apt_name}" ]] && sudo yum update -y "${apt_name}" 2>/dev/null || true
            ;;
        winget)
            if [[ -n "${winget_id}" ]]; then
                winget upgrade --id "${winget_id}" -e \
                    --source winget \
                    --accept-package-agreements --accept-source-agreements 2>/dev/null || true
            fi
            ;;
    esac
}

# 语言工具升级（已安装时调用）
upgrade_language_tool_packages() {
    log_info "Upgrading language tools to latest available..."

    case "${PLATFORM}" in
        macos)
            if [[ "${PKG_MANAGER}" == "brew" ]]; then
                pkg_upgrade "go" "" "" ""
                pkg_upgrade "ruby" "" "" ""
                pkg_upgrade "composer" "" "" ""
                pkg_upgrade "llvm" "" "" ""
            fi
            ;;
        linux)
            pkg_upgrade "" "golang-go" "go" "GoLang.Go"
            pkg_upgrade "" "ruby" "ruby" ""
            pkg_upgrade "" "composer" "composer" ""
            pkg_upgrade "" "build-essential" "base-devel" ""
            ;;
        windows)
            pkg_upgrade "" "" "" "GoLang.Go"
            pkg_upgrade "" "" "" "Rustlang.Rustup"
            pkg_upgrade "" "" "" "LLVM.LLVM"
            ;;
    esac

    if is_rust_from_rustup && command -v rustup >/dev/null 2>&1; then
        log_info "Updating Rust stable via rustup..."
        rustup update stable 2>/dev/null || record_failed "rustup update"
    fi
}
