#!/usr/bin/env bash
# Rust 只走 rustup 预编译包。C 编译器只检查系统是否已有 clang/gcc。

install_rust_official() {
    log_info "Installing Rust (official rustup, latest stable)..."
    if ! command -v curl >/dev/null 2>&1; then
        log_info "curl not found; cannot install rustup. Install curl or Rust manually: https://rustup.rs/"
        record_failed "rust"
        return 1
    fi
    local rustup_sh="https://sh.rustup.rs"
    if curl --proto '=https' --tlsv1.2 -sSf "${rustup_sh}" | sh -s -- -y 2>/dev/null; then
        if [[ -f "${HOME}/.cargo/env" ]]; then
            # shellcheck source=/dev/null
            source "${HOME}/.cargo/env"
        fi
        if command -v rustc >/dev/null 2>&1; then
            log_success "Rust installed (rustup): $(rustc --version 2>&1 | head -n 1)"
        else
            log_success "Rust (rustup) installed. Add to PATH: source \$HOME/.cargo/env 或重新打开终端"
        fi
    else
        log_info "Rust (rustup) installation failed. Install manually: https://rustup.rs/"
        record_failed "rust"
    fi
}

ensure_rust_and_c_compiler() {
    log_info "Checking Rust (rustup) and C compiler..."
    export PATH="${HOME}/.cargo/bin:${PATH}"

    if is_rust_from_rustup && command -v rustup >/dev/null 2>&1; then
        if command -v rustc >/dev/null 2>&1; then
            log_success "Rust already installed (rustup): $(rustc --version 2>&1 | head -n 1)"
        else
            log_success "Cargo already installed (rustup)"
        fi
        log_info "Updating Rust stable via rustup..."
        rustup update stable 2>/dev/null || record_failed "rustup update"
    else
        if command -v rustc >/dev/null 2>&1 || command -v cargo >/dev/null 2>&1; then
            log_info "Non-rustup Rust found; installing official rustup for latest stable"
        fi
        install_rust_official
    fi

    if command -v clang >/dev/null 2>&1; then
        log_success "Clang already installed: $(clang --version 2>&1 | head -n 1)"
    elif command -v gcc >/dev/null 2>&1; then
        log_success "GCC already installed: $(gcc --version 2>&1 | head -n 1)"
    else
        log_warning "No clang or gcc in PATH; Tree-sitter parser compile may fail"
        record_failed "c_compiler (optional)"
    fi
}
