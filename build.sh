#!/usr/bin/env bash
set -euo pipefail  # 更严格的安全设置

# =============================================================================
# 颜色和样式配置
# =============================================================================
readonly RED_COLOR='\033[1;31m'
readonly GREEN_COLOR='\033[1;32m'
readonly YELLOW_COLOR='\033[1;33m'
readonly BLUE_COLOR='\033[1;34m'
readonly MAGENTA_COLOR='\033[1;35m'
readonly CYAN_COLOR='\033[1;36m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'
readonly BLINK='\033[5m'

# =============================================================================
# 全局常量定义
# =============================================================================
readonly SCRIPT_NAME="OpenWRT Build System"
readonly SCRIPT_VERSION="1.0.0"
readonly AUTHOR="OPPEN321"
readonly BLOG="www.kejizero.online"
readonly SUPPORTED_ARCHITECTURES=("rockchip" "x86_64")
readonly REQUIRED_USER="zhao"
readonly MIRROR="${mirror:-https://raw.githubusercontent.com/your-repo}"  # 设置默认镜像

# =============================================================================
# 全局变量
# =============================================================================
GROUP_FLAG=false
START_TIME=$(date +%s)
CPU_CORES=$(( $(nproc --all) + 1 ))
CURRENT_DATE=$(date +%s)

# 构建选项（可以从环境变量覆盖）
BUILD_FAST="${BUILD_FAST:-n}"
BUILD="${BUILD:-y}"
BUILD_TOOLCHAIN="${BUILD_TOOLCHAIN:-n}"
GCC_VERSION="${GCC_VERSION:-12.3.0}"

# =============================================================================
# 函数定义
# =============================================================================

# 打印带颜色的消息
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${RESET}"
}

# 打印错误消息并退出
error_exit() {
    print_color "$RED_COLOR" "❌ 错误: $1"
    exit 1
}

# 打印警告消息
print_warning() {
    print_color "$YELLOW_COLOR" "⚠️  警告: $1"
}

# 打印成功消息
print_success() {
    print_color "$GREEN_COLOR" "✅ $1"
}

# 打印信息消息
print_info() {
    print_color "$BLUE_COLOR" "ℹ️  信息: $1"
}

# GitHub Actions 日志分组
start_group() {
    local title="$1"
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::group::$title"
        GROUP_FLAG=true
    else
        echo -e "\n${BOLD}${CYAN_COLOR}▶ ${title}${RESET}"
        echo "${CYAN_COLOR}────────────────────────────────────────────${RESET}"
    fi
}

end_group() {
    if [[ "$GROUP_FLAG" == true ]]; then
        echo "::endgroup::"
        GROUP_FLAG=false
    else
        echo "${CYAN_COLOR}────────────────────────────────────────────${RESET}"
    fi
}

# 验证必需的环境变量
validate_environment() {
    if [[ "$(whoami)" != "$REQUIRED_USER" ]] && [[ -z "${git_name:-}" || -z "${git_password:-}" ]]; then
        error_exit "未授权访问。请设置认证信息后再执行此脚本。"
    fi
}

# 显示使用帮助
show_usage() {
    echo -e "\n${BOLD}使用方法:${RESET}"
    echo -e "  bash $0 <version> <architecture>"
    echo -e "\n${BOLD}支持的架构:${RESET}"
    for arch in "${SUPPORTED_ARCHITECTURES[@]}"; do
        echo -e "  • ${GREEN_COLOR}$arch${RESET}"
    done
    echo -e "\n${BOLD}环境变量:${RESET}"
    echo -e "  BUILD_FAST=${BUILD_FAST} - 快速构建模式"
    echo -e "  BUILD_TOOLCHAIN=${BUILD_TOOLCHAIN} - 仅构建工具链"
    echo -e "  MIRROR=${MIRROR} - 镜像地址"
    echo -e "\n${BOLD}示例:${RESET}"
    echo -e "  BUILD_FAST=y bash $0 v24 x86_64"
    echo -e "  bash $0 v24 rockchip"
}

# 验证参数
validate_arguments() {
    local version="$1"
    local arch="$2"
    
    if [[ -z "$version" ]]; then
        error_exit "未指定版本号"
    fi
    
    if [[ -z "$arch" ]]; then
        error_exit "未指定目标架构"
    fi
    
    local valid_arch=false
    for supported_arch in "${SUPPORTED_ARCHITECTURES[@]}"; do
        if [[ "$arch" == "$supported_arch" ]]; then
            valid_arch=true
            break
        fi
    done
    
    if [[ "$valid_arch" == false ]]; then
        error_exit "不支持的架构: '$arch'"
    fi
}

# 显示横幅
show_banner() {
    clear
    echo -e ""
    echo -e "${BOLD}${BLUE_COLOR}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}                        OPENWRT 自动化构建系统                    ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}┌────────────────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}│${RESET}  🛠️   ${BOLD}开发者:${RESET} $AUTHOR                                              ${BOLD}${BLUE_COLOR}│${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}│${RESET}  🌐   ${BOLD}博客:${RESET} $BLOG                                    ${BOLD}${BLUE_COLOR}│${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}│${RESET}  💡   ${BOLD}理念:${RESET} 开源 · 定制化 · 高性能                                 ${BOLD}${BLUE_COLOR}│${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}│${RESET}  📦   ${BOLD}版本:${RESET} $SCRIPT_VERSION                                                  ${BOLD}${BLUE_COLOR}│${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}└────────────────────────────────────────────────────────────────────┘${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}══════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}🔧 ${GREEN_COLOR}构建开始时间:${RESET} $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${BOLD}⚡ ${GREEN_COLOR}处理器核心数:${RESET} $CPU_CORES"
    echo -e "${BOLD}🐧 ${GREEN_COLOR}系统用户:${RESET} $(whoami)"
    echo -e "${BOLD}🏗️  ${GREEN_COLOR}构建模式:${RESET} $([ "$BUILD_FAST" = "y" ] && echo "快速" || echo "标准")"
    echo -e "${BOLD}${BLUE_COLOR}══════════════════════════════════════════════════════════════════════${RESET}"
    echo -e ""
}

# 初始化构建环境
setup_build_environment() {
    if [[ "$(id -u)" == "0" ]]; then
        export FORCE_UNSAFE_CONFIGURE=1
        export FORCE=1
        print_warning "以 root 权限运行，已启用强制不安全配置"
    fi
}

# 设置下载进度条
setup_curl_progress() {
    if curl --help | grep -q progress-bar; then
        CURL_BAR="--progress-bar"
    else
        CURL_BAR="--silent"
    fi
    export CURL_BAR
}

# 设置平台相关变量
setup_platform() {
    local architecture="$1"
    
    case "$architecture" in
        rockchip)
            platform="rockchip"
            toolchain_arch="aarch64_generic"
            core="arm64"
            ;;
        x86_64)
            platform="x86_64"
            toolchain_arch="x86_64"
            core="amd64"
            ;;
        *)
            error_exit "不支持的架构: $architecture"
            ;;
    esac
    
    export platform toolchain_arch core
    print_info "目标平台: $platform, 工具链架构: $toolchain_arch, 核心类型: $core"
}

# 获取最新 OpenWRT 版本
get_latest_version() {
    start_group "获取最新 OpenWRT 版本"
    local latest_version
    latest_version="$(curl -s https://github.com/openwrt/openwrt/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" | sed -n '/[2-9][4-9]/p' | sed -n 1p | sed 's/v//g' | sed 's/.tar.gz//g')"
    
    if [[ -z "$latest_version" ]]; then
        error_exit "无法获取最新版本号"
    fi
    
    print_success "检测到最新版本: v$latest_version"
    echo "$latest_version"
    end_group
}

# 克隆源代码
clone_source_code() {
    start_group "克隆源代码"
    local version="$1"
    
    print_info "正在克隆 OpenWRT 源代码..."
    if ! git clone -b "v$version" https://github.com/openwrt/openwrt; then
        error_exit "克隆 OpenWRT 源代码失败"
    fi
    
    print_info "正在克隆 ImmortalWRT 源代码..."
    git clone -b openwrt-24.10 https://github.com/immortalwrt/immortalwrt || print_warning "克隆 ImmortalWRT 失败，继续构建..."
    
    print_info "正在克隆 OpenWRT 快照..."
    git clone -b openwrt-24.10 https://github.com/openwrt/openwrt openwrt_snap || print_warning "克隆 OpenWRT 快照失败，继续构建..."
    
    if [[ ! -d "openwrt" ]]; then
        error_exit "OpenWRT 源代码目录不存在"
    fi
    
    cd openwrt || error_exit "无法进入 openwrt 目录"
    
    # 下载密钥和补丁
    print_info "下载构建密钥和补丁..."
    curl -Os "$MIRROR/openwrt/patch/key.tar.gz" && tar zxf key.tar.gz && rm -f key.tar.gz
    curl -Os "$MIRROR/info.md" || print_warning "无法下载 info.md"
    
    end_group
}

# 更新 feeds
update_feeds() {
    start_group "更新和安装 Feeds"
    
    print_info "更新 feeds..."
    if ! ./scripts/feeds update -a; then
        error_exit "Feeds 更新失败"
    fi
    
    print_info "安装 feeds..."
    if ! ./scripts/feeds install -a; then
        error_exit "Feeds 安装失败"
    fi
    
    end_group
}

# 应用补丁脚本
apply_patches() {
    start_group "应用补丁和配置"
    
    local scripts=(
        00-prepare_base.sh
        01-prepare_package.sh
        02-prepare_adguard_core.sh
        03-preset_mihimo_core.sh
        04-preset_homeproxy.sh
        06-fix-source.sh
        10-custom.sh
        99_clean_build_cache.sh
    )
    
    # 下载补丁脚本
    print_info "下载补丁脚本..."
    for script in "${scripts[@]}"; do
        if curl -sO "$MIRROR/openwrt/scripts/$script"; then
            print_success "下载 $script 成功"
        else
            print_warning "下载 $script 失败"
        fi
    done
    
    # 下载平台特定脚本
    if [[ "$platform" = "rockchip" ]]; then
        curl -sO "$MIRROR/openwrt/scripts/05-rockchip_target_only.sh"
    elif [[ "$platform" = "x86_64" ]]; then
        curl -sO "$MIRROR/openwrt/scripts/05-x86_64_target_only.sh"
    fi
    
    # 设置执行权限并运行脚本
    chmod 0755 ./*.sh
    
    print_info "执行补丁脚本..."
    local patch_scripts=(
        "00-prepare_base.sh"
        "01-prepare_package.sh" 
        "02-prepare_adguard_core.sh"
        "03-preset_mihimo_core.sh"
        "04-preset_homeproxy.sh"
        "06-fix-source.sh"
    )
    
    for script in "${patch_scripts[@]}"; do
        if [[ -f "$script" ]]; then
            print_info "执行 $script..."
            bash "$script" || print_warning "$script 执行出现警告"
        fi
    done
    
    # 执行平台特定脚本
    if [[ "$platform" = "rockchip" ]] && [[ -f "05-rockchip_target_only.sh" ]]; then
        bash 05-rockchip_target_only.sh
    elif [[ "$platform" = "x86_64" ]] && [[ -f "05-x86_64_target_only.sh" ]]; then
        bash 05-x86_64_target_only.sh
    fi
    
    # 执行自定义脚本
    if [[ -f "10-custom.sh" ]]; then
        print_info "执行自定义脚本..."
        bash 10-custom.sh
    fi
    
    # 清理临时文件
    find feeds -type f -name "*.orig" -exec rm -f {} \;
    rm -f 0*-*.sh 10-custom.sh
    
    end_group
}

# 下载工具链缓存
download_toolchain_cache() {
    if [[ "$BUILD_FAST" != "y" ]]; then
        return 0
    fi
    
    start_group "下载工具链缓存"
    
    print_info "正在下载工具链缓存..."
    local TOOLCHAIN_URL="https://github.com/NeonPulse-Zero/openwrt_caches/releases/download/openwrt-24.10"
    local toolchain_file="toolchain_musl_${toolchain_arch}_gcc-${GCC_VERSION}.tar.zst"
    
    if curl -L "${TOOLCHAIN_URL}/$toolchain_file" -o toolchain.tar.zst $CURL_BAR; then
        print_success "工具链下载成功"
        print_info "解压工具链..."
        if tar -I "zstd" -xf toolchain.tar.zst; then
            print_success "工具链解压成功"
            rm -f toolchain.tar.zst
            mkdir -p bin
            
            # 更新文件时间戳
            find ./staging_dir/ -name '*' -exec touch {} \; >/dev/null 2>&1
            find ./tmp/ -name '*' -exec touch {} \; >/dev/null 2>&1
        else
            print_warning "工具链解压失败，将继续从源码编译"
        fi
    else
        print_warning "工具链下载失败，将继续从源码编译"
    fi
    
    end_group
}

# 配置编译选项
configure_build() {
    start_group "配置编译选项"
    
    # 清理临时文件
    rm -rf tmp/*
    
    if [[ "$BUILD" = "n" ]]; then
        print_info "构建模式设置为 NO，退出配置"
        exit 0
    fi
    
    # 下载平台配置文件
    print_info "下载平台配置文件..."
    if [[ "$platform" = "x86_64" ]]; then
        curl -s "$MIRROR/openwrt/24-config-musl-x86" > .config
    elif [[ "$platform" = "rockchip" ]]; then
        curl -s "$MIRROR/openwrt/24-config-musl-rockchip" > .config
    fi
    
    # 添加通用配置
    print_info "添加通用配置..."
    curl -s "$MIRROR/openwrt/24-config-common" >> .config
    
    # 生成默认配置
    print_info "生成默认配置..."
    if ! make defconfig; then
        error_exit "生成默认配置失败"
    fi
    
    end_group
}

# 编译工具链
build_toolchain() {
    if [[ "$BUILD_TOOLCHAIN" != "y" ]]; then
        return 0
    fi
    
    start_group "编译工具链"
    
    print_info "开始编译工具链..."
    if make -j$CPU_CORES toolchain/compile; then
        print_success "工具链编译成功"
    else
        print_warning "工具链首次编译失败，尝试详细模式..."
        if ! make -j$CPU_CORES toolchain/compile V=s; then
            error_exit "工具链编译失败"
        fi
    fi
    
    # 打包工具链缓存
    print_info "打包工具链缓存..."
    mkdir -p toolchain-cache
    local cache_file="toolchain-cache/toolchain_musl_${toolchain_arch}_gcc-${GCC_VERSION}.tar.zst"
    
    if tar -I "zstd -19 -T$(nproc --all)" -cf "$cache_file" ./{build_dir,dl,staging_dir,tmp}; then
        print_success "工具链缓存打包成功: $cache_file"
    else
        print_warning "工具链缓存打包失败"
    fi
    
    end_group
    exit 0
}

# 编译 OpenWRT
build_openwrt() {
    start_group "编译 OpenWRT"
    
    if [[ "$BUILD_TOOLCHAIN" = "y" ]]; then
        return 0
    fi
    
    print_info "开始编译 OpenWRT..."
    
    # 更新构建日期
    sed -i "/BUILD_DATE/d" package/base-files/files/usr/lib/os-release
    sed -i "/BUILD_ID/aBUILD_DATE=\"$CURRENT_DATE\"" package/base-files/files/usr/lib/os-release
    
    # 开始编译
    if ! make -j$CPU_CORES IGNORE_ERRORS="n m"; then
        error_exit "OpenWRT 编译失败"
    fi
    
    print_success "OpenWRT 编译完成"
    end_group
}

# 显示构建统计信息
show_build_stats() {
    local endtime=$(date +'%Y-%m-%d %H:%M:%S')
    local start_seconds=$(date --date="$starttime" +%s)
    local end_seconds=$(date --date="$endtime" +%s)
    local duration=$((end_seconds - start_seconds))
    
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo -e ""
    echo -e "${BOLD}${GREEN_COLOR}══════════════════════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}🏁 ${GREEN_COLOR}构建完成!${RESET}"
    echo -e "${BOLD}⏰ ${GREEN_COLOR}开始时间:${RESET} $starttime"
    echo -e "${BOLD}⏱️  ${GREEN_COLOR}结束时间:${RESET} $endtime"
    echo -e "${BOLD}📊 ${GREEN_COLOR}总耗时:${RESET} ${minutes}分${seconds}秒"
    echo -e "${BOLD}📦 ${GREEN_COLOR}输出目录:${RESET} $(pwd)/bin/targets/"
    echo -e "${BOLD}${GREEN_COLOR}══════════════════════════════════════════════════════════════════════${RESET}"
    echo -e ""
}

# =============================================================================
# 主程序逻辑
# =============================================================================
main() {
    local version="${1:-}"
    local architecture="${2:-}"
    
    # 参数验证
    validate_arguments "$version" "$architecture"
    
    # 显示横幅
    show_banner
    
    # 环境验证
    validate_environment
    
    # 环境设置
    setup_build_environment
    setup_curl_progress
    setup_platform "$architecture"
    
    print_success "初始化完成，开始构建 $architecture 架构的 $version 版本"
    
    # 记录开始时间
    START_TIME=$(date +%s)
    local starttime=$(date +'%Y-%m-%d %H:%M:%S')
    
    # 获取版本并克隆代码
    local latest_version
    latest_version=$(get_latest_version)
    clone_source_code "$latest_version"
    
    # 更新 feeds
    update_feeds
    
    # 应用补丁
    apply_patches
    
    # 下载工具链缓存（快速模式）
    download_toolchain_cache
    
    # 配置构建选项
    configure_build
    
    # 编译工具链（如果需要）
    build_toolchain
    
    # 编译 OpenWRT
    build_openwrt
    
    # 显示统计信息
    show_build_stats
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 如果没有提供足够的参数，显示使用帮助
    if [[ $# -lt 2 ]]; then
        show_usage
        error_exit "参数不足，需要指定版本号和目标架构"
    fi
    
    # 执行主程序
    main "$@"
fi
