#!/usr/bin/env bash
# 版本解析与比较（避免 MSYS2 grep -E 花括号问题）

# 从 nvim --version 首行解析 major/minor；stdout: major minor
parse_nvim_version() {
    local first_line="${1:-}"
    local major="" minor=""
    if [[ "${first_line}" =~ [vV]([0-9]+)\.([0-9]+) ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
    fi
    printf '%s %s\n' "${major}" "${minor}"
}

# Neovim >= 0.11.0
is_nvim_version_ge_0_11() {
    if ! command -v nvim >/dev/null 2>&1; then
        return 1
    fi
    local first_line major minor
    first_line="$(nvim --version 2>/dev/null | head -n 1)" || return 1
    read -r major minor <<< "$(parse_nvim_version "${first_line}")"
    [[ -z "${major}" || -z "${minor}" ]] && return 1
    if [[ "${major}" -gt 0 ]]; then
        return 0
    fi
    [[ "${major}" -eq 0 && "${minor}" -ge 11 ]]
}

# 检测 Rust 是否来自 rustup（~/.cargo/bin）
is_rust_from_rustup() {
    local r
    r="$(command -v rustc 2>/dev/null)"
    [[ -n "${r}" && "${r}" == *".cargo"* ]] && return 0
    r="$(command -v cargo 2>/dev/null)"
    [[ -n "${r}" && "${r}" == *".cargo"* ]] && return 0
    return 1
}
