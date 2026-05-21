#!/usr/bin/env bash
# VSCode Neovim / Cursor 配置安装脚本
# 支持 macOS、Linux、Windows（Git Bash）
# 默认目标编辑器：Cursor（VSCODE_NEOVIM_EDITOR=code 可切换 VS Code）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
INIT_FILE="${SCRIPT_DIR}/vscode_neovim_init.lua"
FRAGMENT_SETTINGS="${SCRIPT_DIR}/settings.json"
EXTENSION_ID="asvetliakov.vscode-neovim"

: "${VSCODE_NEOVIM_EDITOR:=cursor}"
: "${VSCODE_NEOVIM_DRY_RUN:=}"
: "${VSCODE_NEOVIM_SKIP_EXTENSION:=}"
: "${VSCODE_NEOVIM_SKIP_NEOVIM_CHECK:=}"

log_info() { printf '[INFO] %s\n' "$*"; }
log_ok() { printf '[OK] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_err() { printf '[ERROR] %s\n' "$*" >&2; }
die() { log_err "$1"; exit "${2:-1}"; }

run_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${seconds}" "$@"
    else
        "$@"
    fi
}

OS="$(uname -s)"
if [[ "${OS}" == "Darwin" ]]; then
    PLATFORM="macos"
elif [[ "${OS}" == "Linux" ]]; then
    PLATFORM="linux"
elif [[ "${OS}" == MINGW* ]] || [[ "${OS}" == MSYS* ]] || [[ "${OS}" == CYGWIN* ]]; then
    PLATFORM="windows"
else
    die "Unsupported operating system: ${OS}"
fi

case "${VSCODE_NEOVIM_EDITOR}" in
    cursor | code) ;;
    *)
        die "VSCODE_NEOVIM_EDITOR must be 'cursor' or 'code', got: ${VSCODE_NEOVIM_EDITOR}"
        ;;
esac

# Resolve Roaming AppData on Windows (Git Bash: prefer POSIX HOME to avoid broken \ escapes in APPDATA)
resolve_appdata() {
    if [[ -n "${HOME:-}" ]] && [[ -d "${HOME}/AppData/Roaming" ]]; then
        printf '%s/AppData/Roaming' "${HOME}"
        return 0
    fi
    if [[ -n "${APPDATA:-}" ]] && [[ "${APPDATA}" != *"%"* ]] && [[ "${APPDATA}" == *:* ]]; then
        local posix_appdata=""
        if command -v cygpath >/dev/null 2>&1; then
            posix_appdata="$(cygpath -u "${APPDATA}" 2>/dev/null || true)"
        else
            posix_appdata="${APPDATA}"
        fi
        if [[ -n "${posix_appdata}" ]]; then
            printf '%s' "${posix_appdata}"
            return 0
        fi
    fi
    if [[ -n "${USERPROFILE:-}" ]] && [[ "${USERPROFILE}" != *"%"* ]]; then
        local posix_profile=""
        if command -v cygpath >/dev/null 2>&1; then
            posix_profile="$(cygpath -u "${USERPROFILE}/AppData/Roaming" 2>/dev/null || true)"
        else
            posix_profile="${USERPROFILE}/AppData/Roaming"
        fi
        if [[ -n "${posix_profile}" ]]; then
            printf '%s' "${posix_profile}"
            return 0
        fi
    fi
    if [[ "${PLATFORM}" == "windows" ]] && command -v cmd.exe >/dev/null 2>&1; then
        local win_appdata
        win_appdata="$(run_with_timeout 5 cmd.exe /c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n' || true)"
        if [[ -n "${win_appdata}" ]] && [[ "${win_appdata}" != *"%"* ]]; then
            if command -v cygpath >/dev/null 2>&1; then
                cygpath -u "${win_appdata}"
            else
                printf '%s' "${win_appdata}"
            fi
            return 0
        fi
    fi
    return 1
}

user_settings_path() {
    local editor="$1"
    local app_name
    case "${editor}" in
        cursor) app_name="Cursor" ;;
        code) app_name="Code" ;;
    esac

    case "${PLATFORM}" in
        macos)
            printf '%s/Library/Application Support/%s/User/settings.json' "${HOME}" "${app_name}"
            ;;
        linux)
            local xdg="${XDG_CONFIG_HOME:-${HOME}/.config}"
            printf '%s/%s/User/settings.json' "${xdg}" "${app_name}"
            ;;
        windows)
            local appdata=""
            local try_home=""
            # ~/.config/nvim/vscode_neovim → 用户目录为 ../../..
            for try_home in \
                "$(cd "${SCRIPT_DIR}/../../.." && pwd)" \
                "$(cd "${SCRIPT_DIR}/../.." && pwd)" \
                "${HOME:-}"; do
                if [[ -n "${try_home}" ]] && [[ -d "${try_home}/AppData/Roaming" ]]; then
                    appdata="${try_home}/AppData/Roaming"
                    break
                fi
            done
            if [[ -z "${appdata}" ]]; then
                appdata="$(resolve_appdata)" || die "Cannot resolve APPDATA for ${editor} settings path"
            fi
            [[ -n "${appdata}" ]] || die "Empty AppData path for ${editor} settings"
            printf '%s/%s/User/settings.json' "${appdata}" "${app_name}"
            ;;
    esac
}

find_editor_cli() {
    local editor="$1"
    local cli="${editor}"

    if command -v "${cli}" >/dev/null 2>&1; then
        command -v "${cli}"
        return 0
    fi

    if [[ "${PLATFORM}" == "windows" ]]; then
        local win_cli="${editor}.cmd"
        if command -v "${win_cli}" >/dev/null 2>&1; then
            command -v "${win_cli}"
            return 0
        fi
        local local_app
        local_app="$(resolve_appdata 2>/dev/null || true)"
        if [[ -n "${local_app}" ]]; then
            local prog_name="${editor}"
            [[ "${editor}" == "cursor" ]] && prog_name="Cursor"
            [[ "${editor}" == "code" ]] && prog_name="Microsoft VS Code"
            local candidates=(
                "${local_app}/../Local/Programs/${prog_name}/bin/${editor}.cmd"
                "${local_app}/../Local/Programs/${prog_name}/${editor}.cmd"
                "${local_app}/../Local/Programs/Cursor/cursor.cmd"
                "${local_app}/../Local/Programs/Microsoft VS Code/bin/code.cmd"
            )
            local c
            for c in "${candidates[@]}"; do
                if [[ -f "${c}" ]]; then
                    printf '%s' "${c}"
                    return 0
                fi
            done
        fi
    fi

    return 1
}

check_neovim() {
    if [[ "${VSCODE_NEOVIM_SKIP_NEOVIM_CHECK}" == "1" ]]; then
        log_warn "Skipping Neovim version check (VSCODE_NEOVIM_SKIP_NEOVIM_CHECK=1)"
        return 0
    fi

    if ! command -v nvim >/dev/null 2>&1; then
        log_warn "nvim not found in PATH. Install Neovim 0.10+ (see repo install.sh) before using vscode-neovim."
        return 1
    fi

    local version_line major minor
    version_line="$(nvim --version | head -n1)"
    if [[ "${version_line}" =~ v?([0-9]+)\.([0-9]+) ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
    else
        log_warn "Could not parse nvim version from: ${version_line}"
        return 1
    fi

    if ! { (( major > 0 )) || { (( major == 0 )) && (( minor >= 10 )); }; }; then
        log_warn "Neovim ${major}.${minor} detected; vscode-neovim requires 0.10+. Run repo install.sh to upgrade."
        return 1
    fi

    log_ok "Neovim ${major}.${minor} OK"
    return 0
}

verify_init_loads() {
    if [[ "${VSCODE_NEOVIM_SKIP_NEOVIM_CHECK}" == "1" ]]; then
        return 0
    fi
    if ! command -v nvim >/dev/null 2>&1; then
        return 0
    fi
    if [[ "${VSCODE_NEOVIM_DRY_RUN}" == "1" ]]; then
        log_info "[dry-run] nvim --headless -u ${INIT_FILE}"
        return 0
    fi
    if run_with_timeout 15 nvim --headless -u "${INIT_FILE}" -c 'qa!' 2>/dev/null; then
        log_ok "Init file loads: ${INIT_FILE}"
    else
        log_warn "Init file headless check failed or timed out (extension may still work): ${INIT_FILE}"
    fi
}

merge_settings() {
    local user_settings="$1"
    local fragment="$2"
    local init_file="$3"

    if [[ ! -f "${fragment}" ]]; then
        die "Missing settings fragment: ${fragment}"
    fi
    if [[ ! -f "${init_file}" ]]; then
        die "Missing init file: ${init_file}"
    fi

    local py=""
    for candidate in python python3; do
        if command -v "${candidate}" >/dev/null 2>&1 && "${candidate}" -c "import sys" >/dev/null 2>&1; then
            py="${candidate}"
            break
        fi
    done
    if [[ -z "${py}" ]]; then
        die "python or python3 required to merge settings.json (Windows Store python3 stub is not usable)"
    fi

    if [[ "${VSCODE_NEOVIM_DRY_RUN}" == "1" ]]; then
        log_info "[dry-run] merge ${fragment} -> ${user_settings}"
        return 0
    fi

    local user_dir
    user_dir="$(dirname "${user_settings}")"
    mkdir -p "${user_dir}"

    if [[ -f "${user_settings}" ]]; then
        local backup="${user_settings}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "${user_settings}" "${backup}"
        log_ok "Backed up settings to: ${backup}" >&2
    fi

    USER_SETTINGS="${user_settings}" \
        FRAGMENT_SETTINGS="${fragment}" \
        INIT_FILE="${init_file}" \
        "${py}" - <<'PY'
import json
import os
import sys
from pathlib import Path

user_path = Path(os.environ["USER_SETTINGS"])
fragment_path = Path(os.environ["FRAGMENT_SETTINGS"])
init_path = Path(os.environ["INIT_FILE"]).resolve()

def load_json(path: Path) -> dict:
    if not path.is_file():
        return {}
    text = path.read_text(encoding="utf-8").strip()
    if not text:
        return {}
    return json.loads(text)

user = load_json(user_path)
fragment = load_json(fragment_path)

# Remove stale path keys from fragment; install injects fresh paths
for key in list(fragment.keys()):
    if key.startswith("vscode-neovim.neovimInitVimPaths."):
        del fragment[key]

win32_path = os.path.normpath(str(init_path))
posix_path = init_path.as_posix()

fragment["vscode-neovim.neovimInitVimPaths.win32"] = win32_path
fragment["vscode-neovim.neovimInitVimPaths.darwin"] = posix_path
fragment["vscode-neovim.neovimInitVimPaths.linux"] = posix_path

user.update(fragment)

user_path.parent.mkdir(parents=True, exist_ok=True)
user_path.write_text(
    json.dumps(user, indent=4, ensure_ascii=False) + "\n",
    encoding="utf-8",
    newline="\n",
)

print(win32_path)
print(posix_path)
PY
}

ensure_windows_user_env() {
    if [[ "${PLATFORM}" != "windows" ]]; then
        return 0
    fi
    local win_home
    win_home="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
    if [[ -z "${HOME:-}" ]] || [[ ! -d "${HOME}/AppData/Roaming" ]]; then
        export HOME="${win_home}"
    fi
    if [[ -z "${USERPROFILE:-}" ]] || [[ "${USERPROFILE}" == *"%"* ]]; then
        if command -v cygpath >/dev/null 2>&1; then
            export USERPROFILE="$(cygpath -w "${win_home}")"
        else
            export USERPROFILE="${win_home}"
        fi
    fi
}

install_extension() {
    local cli="$1"
    ensure_windows_user_env
    if [[ "${VSCODE_NEOVIM_SKIP_EXTENSION}" == "1" ]]; then
        log_warn "Skipping extension install (VSCODE_NEOVIM_SKIP_EXTENSION=1)"
        return 0
    fi
    if [[ "${VSCODE_NEOVIM_DRY_RUN}" == "1" ]]; then
        log_info "[dry-run] ${cli} --install-extension ${EXTENSION_ID} --force"
        return 0
    fi
    log_info "Installing extension ${EXTENSION_ID} via ${cli} ..."
    if run_with_timeout 120 "${cli}" --install-extension "${EXTENSION_ID}" --force; then
        log_ok "Extension installed: ${EXTENSION_ID}"
    else
        die "Failed to install extension. Ensure ${VSCODE_NEOVIM_EDITOR} CLI is on PATH (Shell Command: Install '${VSCODE_NEOVIM_EDITOR}' command)."
    fi
}

main() {
    echo "=========================================="
    echo "VSCode Neovim 配置安装"
    echo "=========================================="
    log_info "Platform: ${PLATFORM} (${OS})"
    log_info "Editor: ${VSCODE_NEOVIM_EDITOR}"
    log_info "Config root: ${NVIM_CONFIG_ROOT}"
    log_info "Init file: ${INIT_FILE}"
    echo ""

    [[ -f "${INIT_FILE}" ]] || die "Init file not found: ${INIT_FILE}"
    [[ -f "${FRAGMENT_SETTINGS}" ]] || die "Settings fragment not found: ${FRAGMENT_SETTINGS}"

    local user_settings
    user_settings="$(user_settings_path "${VSCODE_NEOVIM_EDITOR}")"
    log_info "Target settings: ${user_settings}"

    local editor_cli
    editor_cli="$(find_editor_cli "${VSCODE_NEOVIM_EDITOR}")" || die "Cannot find '${VSCODE_NEOVIM_EDITOR}' CLI. Install Shell Command from Command Palette, or set PATH."

    check_neovim || true
    verify_init_loads

    echo ""
    echo "=========================================="
    echo "合并 settings.json"
    echo "=========================================="
    local paths_out
    paths_out="$(merge_settings "${user_settings}" "${FRAGMENT_SETTINGS}" "${INIT_FILE}")"
    if [[ -n "${paths_out}" ]]; then
        log_ok "neovimInitVimPaths.win32: $(echo "${paths_out}" | sed -n '1p')"
        log_ok "neovimInitVimPaths.darwin/linux: $(echo "${paths_out}" | sed -n '2p')"
    fi
    log_ok "Settings written: ${user_settings}"

    echo ""
    echo "=========================================="
    echo "安装扩展"
    echo "=========================================="
    install_extension "${editor_cli}"

    echo ""
    echo "=========================================="
    echo "安装完成"
    echo "=========================================="
    echo "编辑器: ${VSCODE_NEOVIM_EDITOR}"
    echo "扩展: ${EXTENSION_ID}"
    echo "Init: ${INIT_FILE}"
    echo "Settings: ${user_settings}"
    echo ""
    echo "下一步:"
    echo "1. 在 ${VSCODE_NEOVIM_EDITOR} 中执行 Developer: Reload Window"
    echo "2. 若 Neovim 未安装或版本过低，在仓库根目录运行: ./install.sh"
    echo "3. 使用 VS Code 时: VSCODE_NEOVIM_EDITOR=code ./install.sh"
    echo ""
}

main "$@"
