#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# 颜色配置
# =============================================================================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
RESET='\033[0m'

# =============================================================================
# 基本信息
# =============================================================================
VERSION="v24"
REPO="QuickWrt/QuickWrt"
ASSET="QuickWrt.tar.gz"

# =============================================================================
# 工具函数
# =============================================================================
log() { echo -e "${BLUE}ℹ️  $*${RESET}"; }
ok() { echo -e "${GREEN}✅ $*${RESET}"; }
err() { echo -e "${RED}❌ $*${RESET}" && exit 1; }

# =============================================================================
# 获取最新 release tag
# =============================================================================
get_latest_release() {
    curl -s "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep -Po '"tag_name": "\K.*?(?=")'
}

# =============================================================================
# 菜单函数
# =============================================================================
show_menu() {
    local title="$1"
    shift
    local options=("$@")

    echo -e "\n${CYAN}=========================================${RESET}"
    echo -e "${CYAN}${title}${RESET}"
    echo -e "${CYAN}=========================================${RESET}"

    for i in "${!options[@]}"; do
        echo -e "  ${YELLOW}$((i+1))${RESET}) ${options[$i]}"
    done

    echo -en "${GREEN}请选择 (输入序号): ${RESET}"
}

# =============================================================================
# 交互选择
# =============================================================================
interactive_mode() {
    log "进入交互模式选择编译参数..."

    # 选择架构
    local arch_options=("rockchip" "x86_64")
    show_menu "请选择设备架构" "${arch_options[@]}"
    read -r arch_choice
    TARGET_ARCH="${arch_options[$((arch_choice-1))]}"

    # 选择编译模式
    local mode_options=("accelerated" "normal" "toolchain-only")
    show_menu "请选择编译模式" "${mode_options[@]}"
    read -r mode_choice
    BUILD_MODE="${mode_options[$((mode_choice-1))]}"

    echo -e "\n${GREEN}✅ 已选择:${RESET}"
    echo -e "  • 版本号     : ${CYAN}${VERSION}${RESET}"
    echo -e "  • 架构       : ${CYAN}${TARGET_ARCH}${RESET}"
    echo -e "  • 编译模式   : ${CYAN}${BUILD_MODE}${RESET}\n"

    run_build
}

# =============================================================================
# 执行 build.sh
# =============================================================================
run_build() {
    log "执行: ./build.sh ${VERSION} ${TARGET_ARCH} ${BUILD_MODE}"
    ./build.sh "${VERSION}" "${TARGET_ARCH}" "${BUILD_MODE}"
}

# =============================================================================
# 主逻辑
# =============================================================================
main() {
    log "检查系统依赖..."
    command -v curl >/dev/null || err "未找到 curl"
    command -v tar >/dev/null || err "未找到 tar"

    log "获取最新发布版..."
    LATEST_TAG=$(get_latest_release)
    ok "最新版本: ${LATEST_TAG}"

    URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ASSET}"
    log "下载 QuickWrt 发布包..."
    curl -L -o "${ASSET}" "${URL}" || err "下载失败"

    log "解压文件..."
    rm -rf QuickWrt
    mkdir QuickWrt
    tar -xzf "${ASSET}" -C QuickWrt || err "解压失败"

    # 进入构建目录
    cd QuickWrt || err "进入 QuickWrt 失败"
    
    # 如果解压后有一个顶层目录，则进入该目录
    if [ $(ls -1 | wc -l) -eq 1 ] && [ -d "$(ls -1)" ]; then
        log "检测到顶层目录，进入: $(ls -1)"
        cd "$(ls -1)" || err "进入解压目录失败"
    fi
    
    # 检查必要文件
    [ -f "./build.sh" ] || err "未找到构建脚本: build.sh"
    [ -d "./scripts" ] || err "未找到 scripts 目录"
    
    chmod +x ./build.sh
    chmod +x ./scripts/*.sh 2>/dev/null || log "为 scripts 目录下的脚本设置执行权限"

    # 交互模式选择
    interactive_mode
}

main "$@"
