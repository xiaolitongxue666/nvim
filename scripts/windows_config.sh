#!/usr/bin/env bash
# Windows 路径、配置目录与部署（从 install.sh 原样迁出）

# Windows：规范化 HOME 为 Windows 用户目录的 Unix 形式（如 /c/Users/xxx），
# 避免 MSYS2 等环境下 HOME=/home/xxx 导致配置装到错误目录。仅 PLATFORM=windows 时执行。
normalize_windows_home() {
    [[ "${PLATFORM}" != "windows" ]] && return 0
    local need_export=0
    if [[ -z "${HOME:-}" ]] || [[ "${HOME}" == /home/* ]]; then
        local userprofile="${USERPROFILE:-}"
        if [[ -z "${userprofile}" ]]; then
            userprofile=$(cmd //c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r\n' || true)
        fi
        userprofile="${userprofile//[$'\r\n']}"
        userprofile="${userprofile#"${userprofile%%[![:space:]]*}"}"
        userprofile="${userprofile%"${userprofile##*[![:space:]]}"}"
        if [[ -n "${userprofile}" ]]; then
            if [[ "${userprofile}" =~ ^([A-Za-z]):(.*) ]]; then
                local rest="${BASH_REMATCH[2]//\\//}"
                rest="${rest#/}"
                local drive_lower
                drive_lower=$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')
                HOME="/${drive_lower}/${rest}"
                need_export=1
            elif command -v cygpath >/dev/null 2>&1; then
                HOME=$(cygpath -u "${userprofile}" 2>/dev/null || true)
                [[ -n "${HOME:-}" ]] && need_export=1
            fi
        fi
        if [[ ${need_export} -eq 0 ]] && [[ "${SCRIPT_DIR}" =~ ^(/[a-z]/[Uu]sers/[^/]+)/.config/nvim$ ]]; then
            HOME="${BASH_REMATCH[1]}"
            need_export=1
        fi
    fi
    if [[ ${need_export} -eq 1 ]] && [[ -n "${HOME:-}" ]]; then
        export HOME
    fi
}

# Windows：获取已展开的 APPDATA 路径（供 npm 使用，避免 npm 在 cwd 下创建字面量 %APPDATA% 目录）
# 返回 Windows 风格路径（反斜杠），便于 export APPDATA 后子进程正确识别；脚本内路径拼接需再转为正斜杠。
get_windows_appdata() {
    [[ "${PLATFORM}" != "windows" ]] && return 0
    local val=""
    if [[ -n "${APPDATA:-}" ]] && [[ "${APPDATA}" != *%* ]]; then
        val="${APPDATA}"
    fi
    if [[ -z "${val}" ]] && command -v cmd.exe >/dev/null 2>&1; then
        val="$(cmd.exe //c "echo %APPDATA%" 2>/dev/null | tr -d '\r\n' || echo "")"
    fi
    if [[ -z "${val}" ]] && command -v node >/dev/null 2>&1; then
        val="$(node -e "try{const c=require('child_process').execSync('cmd /c echo %APPDATA%',{encoding:'utf8',windowsHide:true}); process.stdout.write((c||'').trim().replace(/\r\n?/g,''))}catch(e){}" 2>/dev/null || echo "")"
    fi
    val="${val//[$'\r\n']}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"
    [[ -n "${val}" ]] && echo "${val}"
}


is_same_directory() {
    local dir_a dir_b
    dir_a="$(cd "${1}" 2>/dev/null && pwd)" || return 1
    dir_b="$(cd "${2}" 2>/dev/null && pwd)" || return 1
    [[ "${dir_a}" == "${dir_b}" ]]
}

# 确定配置目录（多 OS 统一：一律使用 $HOME/.config/nvim）
determine_config_dir() {
    NVIM_CONFIG_DIR="${HOME}/.config/nvim"
    log_info "Neovim config directory: ${NVIM_CONFIG_DIR}"
    if [[ -f /proc/version ]] && grep -qi Microsoft /proc/version 2>/dev/null; then
        log_info "WSL detected: ensure eval \"\$(fnm env --use-on-cd)\" and Linux-side tree-sitter-cli (avoid Windows npm in PATH)"
    fi
}

# 查询 Neovim stdpath('config')；unset_var 非空时临时取消该环境变量（探测 Git Bash 原生路径）
query_nvim_stdpath_config() {
    local unset_var="${1:-}"
    local nvim_stdpath_config="" nvim_query_log
    nvim_query_log="$(mktemp /tmp/nvim_stdpath_query.XXXXXX 2>/dev/null || echo "${SCRIPT_DIR}/.nvim_stdpath_query.log")"
    if command -v nvim >/dev/null 2>&1; then
        if [[ -n "${unset_var}" ]]; then
            run_with_timeout 10 env -u "${unset_var}" nvim --headless -u NONE \
                -c "lua io.write(vim.fn.stdpath('config'))" -c "qa!" \
                > "${nvim_query_log}" 2>/dev/null || true
        else
            run_with_timeout 10 nvim --headless -u NONE \
                -c "lua io.write(vim.fn.stdpath('config'))" -c "qa!" \
                > "${nvim_query_log}" 2>/dev/null || true
        fi
        if [[ -s "${nvim_query_log}" ]]; then
            nvim_stdpath_config="$(cat "${nvim_query_log}" | tr -d '\r')"
        fi
        rm -f "${nvim_query_log}"
    fi
    printf '%s' "${nvim_stdpath_config}"
}

# 为单个 stdpath 目标创建 junction（或跳过已存在/已一致的路径）
try_redirect_nvim_config_path() {
    local nvim_stdpath_config="$1"
    local actual_unix="${NVIM_CONFIG_DIR}"

    [[ -z "${nvim_stdpath_config}" ]] && return 0

    local nvim_config_unix
    nvim_config_unix="$(windows_path_to_unix "${nvim_stdpath_config}")"

    if [[ "${nvim_config_unix}" == "${actual_unix}" ]]; then
        log_info "Neovim 配置路径一致（${nvim_stdpath_config}），无需处理"
        return 0
    fi

    log_info "Neovim 期望的配置路径: ${nvim_config_unix}"
    log_info "实际配置路径: ${actual_unix}"

    if [[ -d "${nvim_config_unix}" ]] || [[ -L "${nvim_config_unix}" ]]; then
        log_info "目标路径已存在，跳过重定向: ${nvim_config_unix}"
        return 0
    fi

    local win_target win_source parent_dir_unix
    win_target="$(unix_path_to_windows "${nvim_config_unix}")"
    win_source="$(unix_path_to_windows "${actual_unix}")"

    parent_dir_unix="$(windows_path_to_unix "$(dirname "${win_target}")")"
    if ! is_gitbash_absolute_path "${parent_dir_unix}"; then
        log_error "路径转换异常，拒绝创建目录: ${parent_dir_unix}"
        log_error "原始 stdpath: ${nvim_stdpath_config}"
        return 1
    fi
    ensure_directory "${parent_dir_unix}"

    log_info "尝试创建目录联接 (junction): ${win_target}"
    if create_nvim_config_junction_powershell "${win_target}" "${win_source}"; then
        log_success "已创建目录联接: ${win_target} → ${win_source}"
        return 0
    fi
    if cmd.exe /c "mklink /J \"${win_target}\" \"${win_source}\"" >/dev/null 2>&1; then
        log_success "已创建目录联接: ${win_target} → ${win_source}"
        return 0
    fi
    log_info "目录联接创建失败: ${win_target}（可能需要管理员权限或开发者模式）"
    return 1
}

# 使用 PowerShell 创建 junction（Git Bash 下比 cmd mklink 转义更可靠）
create_nvim_config_junction_powershell() {
    local win_target="$1"
    local win_source="$2"
    powershell.exe -NoProfile -Command \
        "New-Item -ItemType Junction -Force -Path '${win_target}' -Target '${win_source}' | Out-Null" \
        >/dev/null 2>&1
}

# Windows：展开 USERPROFILE / LOCALAPPDATA / XDG_CONFIG_HOME（避免 headless 中 %USERPROFILE% 字面量）
ensure_windows_user_env() {
    [[ "${PLATFORM}" != "windows" ]] && return 0

    local userprofile localappdata xdg_unix

    userprofile="$(cmd //c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r\n' || true)"
    userprofile="${userprofile//[$'\r\n']}"
    if [[ -n "${userprofile}" ]] && [[ "${userprofile}" != *"%"* ]]; then
        export USERPROFILE="${userprofile}"
    elif [[ -n "${HOME:-}" ]] && command -v cygpath >/dev/null 2>&1; then
        export USERPROFILE="$(cygpath -w "${HOME}" 2>/dev/null || true)"
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
}

# Windows：清理 Win10 packer 残留（lazy checkhealth WARNING）
cleanup_legacy_packer() {
    [[ "${PLATFORM}" != "windows" ]] && return 0

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

    local old_backup
    for old_backup in "${nvim_data_unix}/site/pack/packer.backup."*; do
        [[ -e "${old_backup}" ]] || continue
        mv "${old_backup}" "${backup_root}/$(basename "${old_backup}").migrated" 2>/dev/null || rm -rf "${old_backup}"
        log_info "Moved stray packer backup out of site/pack: ${old_backup}"
    done
}

# Git Bash：写入 ~/.bashrc，确保未继承系统 XDG 时仍能找到 ~/.config/nvim
setup_gitbash_xdg_config_home() {
    [[ "${PLATFORM}" != "windows" ]] && return 0
    local bashrc="${HOME}/.bashrc"
    local marker="# nvim: XDG_CONFIG_HOME for Git Bash"
    [[ -f "${bashrc}" ]] && grep -qF "${marker}" "${bashrc}" && return 0
    {
        echo ""
        echo "${marker}"
        echo 'export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"'
    } >> "${bashrc}"
    log_success "已在 ~/.bashrc 设置 XDG_CONFIG_HOME（Git Bash 新开终端生效）"
}

# Windows：自动修复 Neovim 配置路径不匹配
# 当 stdpath('config') ≠ $HOME/.config/nvim 时，自动创建目录联接 (junction)。
# Git Bash 在未设置 XDG_CONFIG_HOME 时 stdpath 可能指向 C:\msys64\home\...\nvim，需单独探测。
setup_windows_config_redirect() {
    # 仅 Windows 需要处理；Linux/macOS/WSL 的 stdpath('config') 天然匹配 ~/.config/nvim
    [[ "${PLATFORM}" != "windows" ]] && return 0

    log_info "检测 Neovim 配置路径..."

    local candidates=() seen="" p fallback_appdata
    for p in \
        "$(query_nvim_stdpath_config "")" \
        "$(query_nvim_stdpath_config "XDG_CONFIG_HOME")"; do
        if [[ -n "${p}" ]] && [[ "${p}" != *"%"* ]] && [[ " ${seen} " != *" ${p} "* ]]; then
            candidates+=("${p}")
            seen="${seen} ${p}"
        elif [[ -n "${p}" ]] && [[ "${p}" == *"%"* ]]; then
            log_info "跳过未展开的 stdpath 候选: ${p}"
        fi
    done

    if [[ ${#candidates[@]} -eq 0 ]]; then
        fallback_appdata="$(get_windows_appdata)"
        candidates+=("${fallback_appdata:-${LOCALAPPDATA:-${USERPROFILE:-$HOME}/AppData/Local}}\\nvim")
        log_info "无法查询 Neovim stdpath('config')，使用默认值"
    fi

    local redirected=0
    for p in "${candidates[@]}"; do
        if try_redirect_nvim_config_path "${p}"; then
            redirected=1
        fi
    done

    # 若 junction 均失败且未设置 XDG，尝试 setx（需重启终端）
    if [[ ${redirected} -eq 0 ]] && [[ -z "${XDG_CONFIG_HOME:-}" ]]; then
        local win_source
        win_source="$(unix_path_to_windows "${NVIM_CONFIG_DIR}")"
        local xdg_win_path
        xdg_win_path="$(dirname "${win_source}")"
        if cmd.exe /c "setx XDG_CONFIG_HOME \"${xdg_win_path}\"" >/dev/null 2>&1; then
            log_success "已通过 setx 设置 XDG_CONFIG_HOME=${xdg_win_path}（重启终端后生效）"
            return 0
        fi
        log_warning "无法自动修复 Windows 配置路径。手动修复方式（以管理员身份运行）："
        for p in "${candidates[@]}"; do
            log_info "  mklink /J \"$(unix_path_to_windows "$(windows_path_to_unix "${p}")")\" \"${win_source}\""
        done
        log_info "或设置环境变量（重启终端后生效）："
        log_info "  setx XDG_CONFIG_HOME \"${xdg_win_path}\""
    fi
}

# 备份现有配置
backup_existing_config() {
    # Windows：若 step 1～6 中仍有子进程在项目根下创建了 %APPDATA%，在此处清理，避免用户看到该目录
    if [[ "${PLATFORM}" == "windows" ]] && [[ -d "${SCRIPT_DIR}/%APPDATA%" ]]; then
        rm -rf "${SCRIPT_DIR}/%APPDATA%"
        log_info "Removed stray %APPDATA% directory from repo (before backup)"
    fi
    if [[ -d "${NVIM_CONFIG_DIR}" ]] && [[ -n "$(ls -A "${NVIM_CONFIG_DIR}" 2>/dev/null)" ]]; then
        BACKUP_DIR="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Existing configuration detected, creating backup..."

        if cp -r "${NVIM_CONFIG_DIR}" "${BACKUP_DIR}" 2>/dev/null; then
            log_success "Configuration backed up to: ${BACKUP_DIR}"
        else
            log_info "Backup failed, continuing with installation"
            BACKUP_DIR=""
        fi
    else
        log_info "No existing configuration found, skipping backup"
    fi
}

# 部署配置文件
deploy_config() {
    log_info "Deploying Neovim configuration..."

    if is_same_directory "${SCRIPT_DIR}" "${NVIM_CONFIG_DIR}"; then
        log_info "Config source equals target, skipping deploy"
        return 0
    fi

    # Windows：若目标下存在误建的 %APPDATA% 目录则删除，避免 cp 报 same file
    if [[ "${PLATFORM}" == "windows" ]] && [[ -d "${NVIM_CONFIG_DIR}/%APPDATA%" ]]; then
        rm -rf "${NVIM_CONFIG_DIR}/%APPDATA%"
        log_info "Removed stray %APPDATA% directory from config"
    fi

    # 创建配置目录
    ensure_directory "${NVIM_CONFIG_DIR}"

    # 复制配置文件
    log_info "Copying configuration files..."
    if command -v rsync >/dev/null 2>&1; then
        # 使用 rsync（更高效，支持排除模式）；排除 %APPDATA% 等误建目录
        rsync -av --exclude='.git' --exclude='.gitignore' --exclude='test_dir' --exclude='%APPDATA%' \
            "${SCRIPT_DIR}/" "${NVIM_CONFIG_DIR}/" >/dev/null 2>&1 || {
            log_info "rsync failed, trying alternative method"
            deploy_config_cp
        }
    else
        deploy_config_cp
    fi

    log_success "Configuration files deployed to: ${NVIM_CONFIG_DIR}"
}

# 使用 cp 部署配置（rsync 不可用时的备选方案）
deploy_config_cp() {
    # 使用 find 和 cp 复制文件（排除不需要的目录及误建的 %APPDATA%）
    find "${SCRIPT_DIR}" -mindepth 1 -maxdepth 1 \
        ! -name '.git' ! -name '.gitignore' ! -name 'test_dir' ! -name '%APPDATA%' \
        -exec cp -r {} "${NVIM_CONFIG_DIR}/" \;
}

