#!/usr/bin/env bash
# 依赖模块单元测试（语法 + 版本解析）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
COMMON_LIB="${NVIM_ROOT}/scripts/common.sh"
DEPS_DIR="${NVIM_ROOT}/scripts/deps"

# shellcheck source=../common.sh
source "${COMMON_LIB}"
# shellcheck source=../deps/manifest.sh
source "${DEPS_DIR}/manifest.sh"
# shellcheck source=../deps/version.sh
source "${DEPS_DIR}/version.sh"

failures=0

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "${expected}" != "${actual}" ]]; then
        log_error "FAIL: ${desc} (expected=${expected}, actual=${actual})"
        failures=$((failures + 1))
    else
        log_success "PASS: ${desc}"
    fi
}

log_info "=== manifest arrays non-empty ==="
[[ ${#NVIM_PYTHON_PACKAGES[@]} -gt 0 ]] && log_success "NVIM_PYTHON_PACKAGES" || { log_error "empty python"; failures=$((failures + 1)); }
[[ ${#NVIM_NPM_PACKAGES[@]} -gt 0 ]] && log_success "NVIM_NPM_PACKAGES" || { log_error "empty npm"; failures=$((failures + 1)); }
[[ ${#NVIM_MASON_LSP_PACKAGES[@]} -gt 0 ]] && log_success "NVIM_MASON_LSP_PACKAGES" || { log_error "empty mason lsp"; failures=$((failures + 1)); }

log_info "=== parse_nvim_version ==="
read -r major minor <<< "$(parse_nvim_version "NVIM v0.11.5")"
assert_eq "nvim 0.11.5 major" "0" "${major}"
assert_eq "nvim 0.11.5 minor" "11" "${minor}"

read -r major minor <<< "$(parse_nvim_version "NVIM v0.10.4")"
assert_eq "nvim 0.10.4 minor" "10" "${minor}"

log_info "=== nvim_mason_all_packages dedupe ==="
mason_count=0
while IFS= read -r _; do
    mason_count=$((mason_count + 1))
done < <(nvim_mason_all_packages)
[[ ${mason_count} -ge ${#NVIM_MASON_LSP_PACKAGES[@]} ]] && log_success "mason dedupe count=${mason_count}" || {
    log_error "mason list too short: ${mason_count}"
    failures=$((failures + 1))
}

log_info "=== syntax check deps ==="
for f in "${DEPS_DIR}"/*.sh; do
    bash -n "${f}" || failures=$((failures + 1))
done
bash -n "${NVIM_ROOT}/install.sh" || failures=$((failures + 1))

if [[ ${failures} -gt 0 ]]; then
    log_error "test_deps: ${failures} failure(s)"
    exit 1
fi
log_success "test_deps: all passed"
