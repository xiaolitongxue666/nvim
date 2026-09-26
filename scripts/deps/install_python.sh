#!/usr/bin/env bash
# uv venv 与 pynvim

# 设置 Python 环境（使用 uv 管理）
setup_python_environment() {
    log_info "Setting up Python environment with uv..."

    # 检查是否使用系统级安装
    local use_system_venv="${USE_SYSTEM_NVIM_VENV:-0}"
    # 获取用户名：优先使用 INSTALL_USER，然后是 USER，最后使用 whoami 或 USERNAME
    local install_user="${INSTALL_USER:-${USER:-${USERNAME:-$(whoami 2>/dev/null || echo "user")}}}"

    # 确定虚拟环境路径
    if [[ "${use_system_venv}" == "1" ]]; then
        # 系统级安装：所有用户共享
        VENV_PATH="/usr/local/share/nvim/venv/nvim-python"
        log_info "Using system-wide Neovim Python environment (shared by all users)"
    else
        # 用户级安装：每个用户独立
        VENV_PATH="${HOME}/.config/nvim/venv/nvim-python"
        log_info "Using user-specific Neovim Python environment"
    fi

    log_info "Virtual environment path: ${VENV_PATH}"

    # 创建虚拟环境目录
    ensure_directory "$(dirname "${VENV_PATH}")"

    # 如果虚拟环境已存在，则更新包
    if [[ -d "${VENV_PATH}" ]]; then
        log_info "Virtual environment already exists, will update packages"
    else
        log_info "Creating virtual environment..."
        if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
            # 系统级：以 root 运行
            uv venv "${VENV_PATH}" || {
                log_error "Failed to create virtual environment"
                exit 1
            }
        else
            # 用户级：以当前用户运行
            uv venv "${VENV_PATH}" || {
                log_error "Failed to create virtual environment"
                exit 1
            }
        fi
        log_success "Virtual environment created"
    fi

    # Windows 上 uv 使用 Scripts/activate、Scripts/python.exe；macOS/Linux 使用 bin/
    if [[ "${PLATFORM}" == "windows" ]]; then
        if [[ -f "${VENV_PATH}/Scripts/activate" ]]; then
            VENV_ACTIVATE="${VENV_PATH}/Scripts/activate"
            if [[ -f "${VENV_PATH}/Scripts/python.exe" ]]; then
                VENV_PYTHON="${VENV_PATH}/Scripts/python.exe"
            else
                VENV_PYTHON="${VENV_PATH}/Scripts/python"
            fi
        else
            VENV_ACTIVATE="${VENV_PATH}/bin/activate"
            VENV_PYTHON="${VENV_PATH}/bin/python"
        fi
    else
        VENV_ACTIVATE="${VENV_PATH}/bin/activate"
        VENV_PYTHON="${VENV_PATH}/bin/python"
    fi

    # 确保 pip 已安装（使用 uv pip）
    log_info "Ensuring pip is installed..."
    if [[ -f "${VENV_ACTIVATE}" ]]; then
        # 检查 pip 是否可用
        local pip_available=0
        if source "${VENV_ACTIVATE}" 2>/dev/null; then
            if python -m pip --version >/dev/null 2>&1; then
                pip_available=1
            fi
        fi

        # 使用 uv pip 安装或升级 pip
        if [[ ${pip_available} -eq 0 ]]; then
            log_info "Installing pip via uv pip..."
        else
            log_info "Upgrading pip to latest version via uv pip..."
        fi

        if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
            # 系统级：以 root 运行
            (source "${VENV_ACTIVATE}" && uv pip install --upgrade pip >/dev/null 2>&1) || true
        else
            # 用户级：以当前用户运行
            (source "${VENV_ACTIVATE}" && uv pip install --upgrade pip >/dev/null 2>&1) || true
        fi

        # 验证 pip 是否可用
        if source "${VENV_ACTIVATE}" 2>/dev/null; then
            if python -m pip --version >/dev/null 2>&1; then
                local pip_version
                pip_version=$(python -m pip --version 2>&1 | head -n 1)
                log_success "pip is available: ${pip_version}"
            else
                log_info "pip may not be available, continuing with package installation"
            fi
        else
            log_info "Could not activate venv for pip verification, continuing"
        fi
    fi

    log_info "Installing/upgrading Python packages: ${NVIM_PYTHON_PACKAGES[*]}"
    log_info "This may take a few minutes..."

    local activate_script="${VENV_ACTIVATE:-${VENV_PATH}/bin/activate}"
    local install_cmd="source '${activate_script}' && uv pip install -U ${NVIM_PYTHON_PACKAGES[*]}"
    if [[ "${use_system_venv}" == "1" ]] && [[ "$EUID" -eq 0 ]]; then
        run_with_timeout 600 bash -c "${install_cmd}" || { log_warning "Some packages may have failed to install, but continuing"; }
    else
        run_with_timeout 600 bash -c "${install_cmd}" || { log_warning "Some packages may have failed to install, but continuing"; }
    fi
    log_success "Python packages install/upgrade completed"
}

