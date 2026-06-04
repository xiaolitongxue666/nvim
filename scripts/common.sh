#!/usr/bin/env bash
# 本仓库安装脚本使用的通用日志与错误处理函数（独立于父仓库）

log_info() {
    printf '\033[0;36m[INFO]\033[0m %s\n' "$*"
}

log_success() {
    printf '\033[0;32m[SUCCESS]\033[0m %s\n' "$*"
}

log_warning() {
    printf '\033[0;33m[WARN]\033[0m %s\n' "$*" >&2
}

log_error() {
    printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2
}

error_exit() {
    log_error "$1"
    exit 1
}

start_script() {
    local title="${1:-Script}"
    printf '\n\033[0;34m========== %s ==========\033[0m\n' "${title}"
}

end_script() {
    printf '\033[0;34m========== Done ==========\033[0m\n\n'
}

# 确保目录存在，不存在则创建（mkdir -p）
ensure_directory() {
    local dir="$1"
    if [[ -z "${dir}" ]]; then
        return 1
    fi
    if [[ ! -d "${dir}" ]]; then
        mkdir -p "${dir}"
    fi
}

# 带超时运行命令（macOS 无 timeout 时直接执行）
run_with_timeout() {
    local seconds="$1"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${seconds}" "$@"
    else
        "$@"
    fi
}

# Windows 路径 → Git Bash Unix 绝对路径
# 例：C:\Users\foo → /c/Users/foo
windows_path_to_unix() {
    local p="$1"
    p="${p//\\//}"
    if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
        printf '/%s/%s\n' "${BASH_REMATCH[1],,}" "${BASH_REMATCH[2]}"
    elif [[ "$p" =~ ^([a-zA-Z]):/(.*)$ ]]; then
        printf '/%s/%s\n' "${BASH_REMATCH[1],,}" "${BASH_REMATCH[2]}"
    elif [[ "$p" =~ ^([a-zA-Z]):(.*)$ ]]; then
        printf '/%s/%s\n' "${BASH_REMATCH[1],,}" "${BASH_REMATCH[2]}"
    else
        printf '%s\n' "$p"
    fi
}

# Git Bash Unix 绝对路径 → Windows 路径（供 cmd.exe / mklink）
# 例：/c/Users/foo → C:\Users\foo
unix_path_to_windows() {
    local p="$1"
    p="${p//\\//}"
    if [[ "$p" =~ ^/([a-z])/(.*)$ ]]; then
        local drive
        drive="$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')"
        printf '%s:\\%s\n' "${drive}" "${BASH_REMATCH[2]//\//\\}"
    else
        printf '%s\n' "$p"
    fi
}

# 校验 Git Bash 绝对路径（必须以 /x/ 开头，防止相对路径误建目录）
is_gitbash_absolute_path() {
    local p="$1"
    [[ "$p" =~ ^/[a-zA-Z]/ ]]
}

# 检测是否为 Windows Git Bash 环境
is_windows_platform() {
    local os
    os="$(uname -s 2>/dev/null || echo "")"
    [[ "${os}" == MINGW* ]] || [[ "${os}" == MSYS* ]] || [[ "${os}" == CYGWIN* ]]
}

# 无头/安装脚本共用：展开 USERPROFILE / LOCALAPPDATA / XDG_CONFIG_HOME
ensure_windows_user_env() {
    is_windows_platform || return 0

    local userprofile localappdata xdg_unix

    userprofile="$(cmd //c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r\n' || true)"
    userprofile="${userprofile//[$'\r\n']}"
    if [[ -n "${userprofile}" ]] && [[ "${userprofile}" != *"%"* ]]; then
        export USERPROFILE="${userprofile//\\//}"
    elif [[ -n "${HOME:-}" ]] && command -v cygpath >/dev/null 2>&1; then
        export USERPROFILE="$(cygpath -w "${HOME}" 2>/dev/null || true)"
    fi

    if [[ -z "${HOME:-}" ]] || [[ "${HOME}" == /home/* ]]; then
        if [[ -n "${USERPROFILE:-}" ]] && [[ "${USERPROFILE}" =~ ^([A-Za-z]):\\?(.*)$ ]]; then
            local rest="${BASH_REMATCH[2]//\\//}"
            rest="${rest#/}"
            HOME="/$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')/${rest}"
            export HOME
        fi
    fi

    localappdata="$(cmd //c "echo %LOCALAPPDATA%" 2>/dev/null | tr -d '\r\n' || true)"
    localappdata="${localappdata//[$'\r\n']}"
    if [[ -n "${localappdata}" ]] && [[ "${localappdata}" != *"%"* ]]; then
        export LOCALAPPDATA="${localappdata}"
    fi

    xdg_unix="${XDG_CONFIG_HOME:-${HOME}/.config}"
    if command -v cygpath >/dev/null 2>&1; then
        export XDG_CONFIG_HOME="$(cygpath -w "${xdg_unix}" 2>/dev/null || echo "${xdg_unix}")"
    else
        export XDG_CONFIG_HOME="${xdg_unix}"
    fi
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME//\\//}"
}

# Windows：展开 APPDATA，避免 npm/fnm 在 cwd 下创建字面量 %APPDATA% 目录
get_windows_appdata_value() {
    is_windows_platform || return 1
    local val=""
    if [[ -n "${APPDATA:-}" ]] && [[ "${APPDATA}" != *%* ]]; then
        val="${APPDATA}"
    fi
    if [[ -z "${val}" ]] && command -v cmd.exe >/dev/null 2>&1; then
        val="$(cmd.exe //c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n' || true)"
    fi
    if [[ -z "${val}" ]] && command -v cmd >/dev/null 2>&1; then
        val="$(cmd //c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n' || true)"
    fi
    if [[ -z "${val}" ]] && command -v node >/dev/null 2>&1; then
        val="$(node -e "try{const c=require('child_process').execSync('cmd /c echo %APPDATA%',{encoding:'utf8',windowsHide:true}); process.stdout.write((c||'').trim().replace(/\r\n?/g,''))}catch(e){}" 2>/dev/null || true)"
    fi
    if [[ -z "${val}" ]] || [[ "${val}" == *%* ]]; then
        local roaming=""
        for roaming in \
            "${HOME}/AppData/Roaming" \
            "${USERPROFILE}/AppData/Roaming"; do
            [[ -n "${roaming}" ]] && [[ -d "${roaming}" ]] || continue
            if command -v cygpath >/dev/null 2>&1; then
                val="$(cygpath -w "${roaming}" 2>/dev/null || true)"
            elif [[ "${roaming}" =~ ^/([a-zA-Z])/(.*)$ ]]; then
                val="$(printf '%s:\\%s' "$(echo "${BASH_REMATCH[1]}" | tr '[:lower:]' '[:upper:]')" "${BASH_REMATCH[2]//\//\\}")"
            fi
            [[ -n "${val}" ]] && [[ "${val}" != *%* ]] && break
        done
    fi
    val="${val//[$'\r\n']}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    [[ -n "${val}" ]] && [[ "${val}" != *%* ]] && printf '%s\n' "${val}"
}

ensure_windows_appdata_export() {
    is_windows_platform || return 0
    local appdata
    appdata="$(get_windows_appdata_value 2>/dev/null || true)"
    if [[ -n "${appdata}" ]]; then
        export APPDATA="${appdata}"
    else
        log_warning "Could not resolve APPDATA; subprocesses may create literal %APPDATA% in cwd"
    fi
}

cleanup_stray_appdata_in_dir() {
    local dir="$1"
    [[ -n "${dir}" ]] || return 0
    [[ -d "${dir}/%APPDATA%" ]] || return 0
    rm -rf "${dir}/%APPDATA%"
    log_info "Removed stray %APPDATA% directory from ${dir}"
}

# Windows：在 APPDATA/HOME 下 eval fnm，避免在仓库根创建 %APPDATA%/fnm
fnm_env_safe() {
    command -v fnm >/dev/null 2>&1 || return 0
    local saved_wd="${PWD}"
    if is_windows_platform; then
        [[ -z "${APPDATA:-}" || "${APPDATA}" == *%* ]] && ensure_windows_appdata_export
        local safe_dir=""
        if [[ -n "${APPDATA:-}" ]] && [[ "${APPDATA}" != *%* ]]; then
            safe_dir="${APPDATA//\\//}"
            if [[ "${safe_dir}" =~ ^([A-Za-z]):(.*)$ ]]; then
                safe_dir="/${BASH_REMATCH[1],,}${BASH_REMATCH[2]}"
            fi
        fi
        [[ -z "${safe_dir}" || ! -d "${safe_dir}" ]] && safe_dir="${HOME:-}"
        if [[ -n "${safe_dir}" ]] && [[ -d "${safe_dir}" ]]; then
            cd "${safe_dir}" || true
        fi
    fi
    eval "$(fnm env --use-on-cd)" || true
    cd "${saved_wd}" 2>/dev/null || true
}

# Windows：清理 Win10 packer 残留（lazy checkhealth WARNING）
cleanup_legacy_packer() {
    is_windows_platform || return 0

    local nvim_data_unix=""
    if [[ -n "${LOCALAPPDATA:-}" ]] && [[ "${LOCALAPPDATA}" != *"%"* ]]; then
        nvim_data_unix="$(windows_path_to_unix "${LOCALAPPDATA}/nvim-data")"
    elif [[ -n "${HOME:-}" ]] && [[ -d "${HOME}/AppData/Local/nvim-data" ]]; then
        nvim_data_unix="${HOME}/AppData/Local/nvim-data"
    fi
    [[ -z "${nvim_data_unix}" ]] && return 0

    local packer_dir="${nvim_data_unix}/site/pack/packer"
    local backup_root="${nvim_data_unix}/backups"
    ensure_directory "${backup_root}"

    if [[ -d "${packer_dir}" ]]; then
        local backup_dir="${backup_root}/packer.$(date +%Y%m%d_%H%M%S)"
        log_info "Backing up legacy packer plugins (Win10 migration residue): ${packer_dir}"
        if mv "${packer_dir}" "${backup_dir}" 2>/dev/null; then
            log_success "Legacy packer removed (backup: ${backup_dir})"
        else
            log_warning "Could not remove legacy packer directory: ${packer_dir}"
        fi
    fi

    # 旧版 cleanup 曾放在 site/pack/ 下，lazy 仍会误报
    local old_backup
    for old_backup in "${nvim_data_unix}/site/pack/packer.backup."*; do
        [[ -e "${old_backup}" ]] || continue
        mv "${old_backup}" "${backup_root}/$(basename "${old_backup}").migrated" 2>/dev/null || rm -rf "${old_backup}"
        log_info "Moved stray packer backup out of site/pack: ${old_backup}"
    done
}

# 跨平台默认代理（USE_PROXY=0 关闭；WSL 用宿主机 :7890，其它 OS 用 127.0.0.1:7890）
# 代理端口不可达时不 export，避免 git/npm 在无代理环境下无限挂起
PROXY_PROBE_TIMEOUT="${PROXY_PROBE_TIMEOUT:-2}"

is_wsl_platform() {
    [[ -f /proc/version ]] && grep -qi Microsoft /proc/version 2>/dev/null
}

resolve_wsl_host_ip() {
    local gw=""
    if command -v ip >/dev/null 2>&1; then
        gw="$(ip route show default 2>/dev/null | awk '{print $3; exit}')"
        if [[ -n "${gw}" ]]; then
            printf '%s\n' "${gw}"
            return 0
        fi
    fi
    if [[ -f /etc/resolv.conf ]]; then
        gw="$(awk '/^nameserver/ { print $2; exit }' /etc/resolv.conf 2>/dev/null)"
        if [[ -n "${gw}" ]]; then
            printf '%s\n' "${gw}"
            return 0
        fi
    fi
    return 1
}

# stdout: host；stderr: 解析方式说明（供日志）
resolve_default_proxy_host() {
    if [[ -n "${PROXY_HOST:-}" ]]; then
        printf 'user-override\n' >&2
        printf '%s\n' "${PROXY_HOST}"
        return 0
    fi
    if is_wsl_platform; then
        local wsl_host=""
        wsl_host="$(resolve_wsl_host_ip 2>/dev/null || true)"
        if [[ -n "${wsl_host}" ]]; then
            printf 'wsl-gateway\n' >&2
            printf '%s\n' "${wsl_host}"
            return 0
        fi
        log_warning "WSL: could not resolve host IP, falling back to 127.0.0.1"
    fi
    printf 'native-localhost\n' >&2
    printf '127.0.0.1\n'
}

proxy_port_reachable() {
    local host="$1"
    local port="$2"
    run_with_timeout "${PROXY_PROBE_TIMEOUT}" bash -c "echo >/dev/tcp/${host}/${port}" 2>/dev/null
}

export_proxy_env() {
    local proxy_url="$1"
    local no_proxy_list="${2:-127.0.0.1,localhost}"
    export http_proxy="${proxy_url}"
    export https_proxy="${proxy_url}"
    export HTTP_PROXY="${proxy_url}"
    export HTTPS_PROXY="${proxy_url}"
    export all_proxy="${proxy_url}"
    export no_proxy="${no_proxy_list}"
    export NO_PROXY="${no_proxy_list}"
    export NVIM_PROXY_URL="${proxy_url}"
    if is_windows_platform; then
        export npm_config_proxy="${proxy_url}"
        export npm_config_https_proxy="${proxy_url}"
    fi
}

setup_default_proxy() {
    if [[ "${USE_PROXY:-1}" != "1" ]]; then
        log_info "Proxy setup: USE_PROXY=0, skipping"
        return 0
    fi

    local proxy_port="${PROXY_PORT:-7890}"
    local resolve_method=""
    local proxy_host=""
    local platform_label="native"
    local resolve_stderr=""

    if is_wsl_platform; then
        platform_label="WSL"
    fi

    resolve_stderr="$(mktemp 2>/dev/null || echo "/tmp/nvim_proxy_resolve.$$")"
    proxy_host="$(resolve_default_proxy_host 2>"${resolve_stderr}" || true)"
    resolve_method="$(head -n1 "${resolve_stderr}" 2>/dev/null || echo "unknown")"
    rm -f "${resolve_stderr}"

    if [[ -z "${proxy_host}" ]]; then
        proxy_host="127.0.0.1"
        resolve_method="fallback-localhost"
    fi

    log_info "Proxy setup: USE_PROXY=1 platform=${platform_label} host=${proxy_host} port=${proxy_port} (resolve=${resolve_method})"
    log_info "Proxy probe: ${proxy_host}:${proxy_port} (timeout ${PROXY_PROBE_TIMEOUT}s)..."

    if ! proxy_port_reachable "${proxy_host}" "${proxy_port}"; then
        log_info "Proxy ${proxy_host}:${proxy_port} unreachable, skipping (set USE_PROXY=0 to silence)"
        return 0
    fi

    local no_proxy_list="127.0.0.1,localhost"
    if is_wsl_platform && [[ "${proxy_host}" != "127.0.0.1" ]]; then
        no_proxy_list="${no_proxy_list},${proxy_host}"
    fi

    export_proxy_env "http://${proxy_host}:${proxy_port}" "${no_proxy_list}"
    log_info "Proxy enabled: http://${proxy_host}:${proxy_port}"
}

setup_headless_proxy() {
    setup_default_proxy
}
