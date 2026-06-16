#!/usr/bin/env bash
# 依赖模块加载入口（由 install.sh source）

DEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=manifest.sh
source "${DEPS_DIR}/manifest.sh"
# shellcheck source=version.sh
source "${DEPS_DIR}/version.sh"
# shellcheck source=runtime_context.sh
source "${DEPS_DIR}/runtime_context.sh"
# shellcheck source=platform_pkg.sh
source "${DEPS_DIR}/platform_pkg.sh"
# shellcheck source=install_prereqs.sh
source "${DEPS_DIR}/install_prereqs.sh"
# shellcheck source=install_neovim.sh
source "${DEPS_DIR}/install_neovim.sh"
# shellcheck source=install_system_utils.sh
source "${DEPS_DIR}/install_system_utils.sh"
# shellcheck source=sync_mason.sh
source "${DEPS_DIR}/sync_mason.sh"
