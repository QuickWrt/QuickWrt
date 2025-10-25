#!/usr/bin/env bash
set -euo pipefail

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

# =============================================================================
# 全局常量定义
# =============================================================================
readonly SCRIPT_NAME="OpenWRT 构建系统"
readonly SCRIPT_VERSION="2.0.1"
readonly AUTHOR="OPPEN321"
readonly BLOG="www.kejizero.online"
readonly MIRROR="https://raw.githubusercontent.com/QuickWrt/QuickWrt/refs/heads/master"
readonly SUPPORTED_ARCHITECTURES=("rockchip" "x86_64")
readonly REQUIRED_USER="zhao"
readonly BUILD_MODES=("accelerated" "normal" "toolchain-only")

# =============================================================================
# 全局变量
# =============================================================================
GROUP_FLAG=false
START_TIME=$(date +%s)
CPU_CORES=$(nproc)
BUILD_MODE="normal"
TOOLCHAIN_ARCH=""
CURRENT_DATE=$(date +%s)

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

# 显示使用帮助
show_usage() {
    echo -e "\n${BOLD}使用方法:${RESET}"
    echo -e "  bash $0 <version> <architecture> [build_mode]"
    echo -e "\n${BOLD}支持的架构:${RESET}"
    for arch in "${SUPPORTED_ARCHITECTURES[@]}"; do
        echo -e "  • ${GREEN_COLOR}$arch${RESET}"
    done
    echo -e "\n${BOLD}支持的编译模式:${RESET}"
    echo -e "  • ${GREEN_COLOR}accelerated${RESET}   - 加速编译（下载预编译工具链）"
    echo -e "  • ${GREEN_COLOR}normal${RESET}        - 普通编译（完整编译所有组件）"
    echo -e "  • ${GREEN_COLOR}toolchain-only${RESET} - 仅编译工具链（用于缓存）"
    echo -e "\n${BOLD}示例:${RESET}"
    echo -e "  bash $0 v24 x86_64 accelerated"
    echo -e "  bash $0 v24 rockchip normal"
    echo -e "  bash $0 v24 x86_64 toolchain-only"
}

# 验证参数
validate_arguments() {
    local version="$1"
    local arch="$2"
    local mode="${3:-normal}"
    
    if [[ -z "$version" ]]; then
        error_exit "未指定版本号"
    fi
    
    if [[ -z "$arch" ]]; then
        error_exit "未指定目标架构"
    fi
    
    # 验证架构
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
    
    # 验证编译模式
    local valid_mode=false
    for supported_mode in "${BUILD_MODES[@]}"; do
        if [[ "$mode" == "$supported_mode" ]]; then
            valid_mode=true
            BUILD_MODE="$mode"
            break
        fi
    done
    
    if [[ "$valid_mode" == false ]]; then
        error_exit "不支持的编译模式: '$mode'"
    fi
}

show_banner() {
    clear
    echo -e ""
    echo -e "${BOLD}${BLUE_COLOR}╔══════════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}                       ZeroWRT 自动化构建系统                     ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}╠══════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}                                                                  ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}${BOLD}${BLUE_COLOR}   ██████╗███████╗██████╗  ██████╗ ██╗    ██╗██████╗ ████████╗    ${RESET}${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}${BOLD}${CYAN_COLOR}   ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗██║    ██║██╔══██╗╚══██╔══╝   ${RESET}${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}${BOLD}${CYAN_COLOR}     ███╔╝ █████╗  ██████╔╝██║   ██║██║ █╗ ██║██████╔╝   ██║      ${RESET}${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}${BOLD}${YELLOW_COLOR}    ███╔╝  ██╔══╝  ██╔══██╗██║   ██║██║███╗██║██╔══██╗   ██║      ${RESET}${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}${BOLD}${YELLOW_COLOR}   ███████╗███████╗██║  ██║╚██████╔╝╚███╔███╔╝██║  ██║   ██║      ${RESET}${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}${BOLD}${YELLOW_COLOR}   ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝  ╚══╝╚══╝ ╚═╝  ╚═╝   ╚═╝      ${RESET}${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}${BOLD}${YELLOW_COLOR}         Open Source · Tailored · High Performance                ${RESET}${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET}                                                                  ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}╠══════════════════════════════════════════════════════════════════╣${RESET}"
    
    printf "${BOLD}${BLUE_COLOR}║${RESET} %-8s %-50s ${BOLD}${BLUE_COLOR}   ║${RESET}\n" "🛠️  开发者:" "OPPEN321"
    printf "${BOLD}${BLUE_COLOR}║${RESET} %-8s %-50s ${BOLD}${BLUE_COLOR}     ║${RESET}\n" "🌐 博客:" "www.kejizero.online"
    printf "${BOLD}${BLUE_COLOR}║${RESET} %-8s %-50s ${BOLD}${BLUE_COLOR}               ║${RESET}\n" "💡 理念:" "开源 · 定制化 · 高性能"
    printf "${BOLD}${BLUE_COLOR}║${RESET} %-8s %-50s ${BOLD}${BLUE_COLOR}     ║${RESET}\n" "📦 版本:" "2.0.0"
    
    echo -e "${BOLD}${BLUE_COLOR}╠══════════════════════════════════════════════════════════════════╣${RESET}"
    
    printf "${BOLD}${BLUE_COLOR}║${RESET} %-8s %-50s ${BOLD}${BLUE_COLOR} ║${RESET}\n" "🔧 构建开始:" "$(date '+%Y-%m-%d %H:%M:%S')"
    printf "${BOLD}${BLUE_COLOR}║${RESET} %-8s %-50s ${BOLD}${BLUE_COLOR}║${RESET}\n" "⚡ 处理器核心:" "$CPU_CORES 个"
    printf "${BOLD}${BLUE_COLOR}║${RESET} %-8s %-50s ${BOLD}${BLUE_COLOR} ║${RESET}\n" "🐧 系统用户:" "$(whoami)"
    
    local mode_display
    case "$BUILD_MODE" in
        "accelerated") mode_display="加速编译" ;;
        "normal") mode_display="普通编译" ;;
        "toolchain-only") mode_display="仅工具链" ;;
        *) mode_display="$BUILD_MODE" ;;
    esac
    printf "${BOLD}${BLUE_COLOR}║${RESET} %-8s %-50s ${BOLD}${BLUE_COLOR}     ║${RESET}\n" "🚀 编译模式:" "$mode_display"
    
    echo -e "${BOLD}${BLUE_COLOR}╚══════════════════════════════════════════════════════════════════╝${RESET}"
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
        CURL_OPTIONS="--progress-bar"
    else
        CURL_OPTIONS="--silent"
    fi
    export CURL_OPTIONS
}

# 设置工具链架构
setup_toolchain_arch() {
    local arch="$1"
    case "$arch" in
        "x86_64")
            TOOLCHAIN_ARCH="x86_64"
            ;;
        "rockchip")
            TOOLCHAIN_ARCH="aarch64_generic"
            ;;
        *)
            error_exit "未知架构: $arch"
            ;;
    esac
    export TOOLCHAIN_ARCH
    print_success "工具链架构设置为: $TOOLCHAIN_ARCH"
}

# 编译脚本 - 准备源代码
prepare_source_code() {
    print_info "开始查询最新 OpenWRT 版本..."
    tag_version="$(curl -s https://github.com/openwrt/openwrt/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" | sed -n '/[2-9][4-9]/p' | sed -n 1p | sed 's/v//g' | sed 's/.tar.gz//g')"
    export tag_version="$tag_version"
    print_success "检测到最新版本: $tag_version"

    print_info "开始克隆源代码仓库..."
    git -c advice.detachedHead=false clone --depth=1 --branch "v$tag_version" --single-branch --quiet https://github.com/openwrt/openwrt
    git clone --depth=1 --quiet -b openwrt-24.10 https://github.com/immortalwrt/immortalwrt
    git clone --depth=1 --quiet -b openwrt-24.10 https://github.com/openwrt/openwrt openwrt_snap

    print_info "正在进行源代码处理..."
    find openwrt/package/* -maxdepth 0 ! -name 'firmware' ! -name 'kernel' ! -name 'base-files' ! -name 'Makefile' -exec rm -rf {} +
    rm -rf ./openwrt_snap/package/firmware ./openwrt_snap/package/kernel ./openwrt_snap/package/base-files ./openwrt_snap/package/Makefile
    cp -rf ./openwrt_snap/package/* ./openwrt/package/

    print_info "为 Rockchip 架构替换 ImmortalWRT 组件以增强设备兼容性..."
    rm -rf openwrt/package/boot/{rkbin,uboot-rockchip,arm-trusted-firmware-rockchip}
    rm -rf openwrt/target/linux/rockchip
    cp -rf immortalwrt/target/linux/rockchip openwrt/target/linux/rockchip
    cp -rf immortalwrt/package/boot/uboot-rockchip openwrt/package/boot/uboot-rockchip
    cp -rf immortalwrt/package/boot/arm-trusted-firmware-rockchip openwrt/package/boot/arm-trusted-firmware-rockchip

    print_info "正在克隆 OpenBox 仓库以支持后续编译"
    git clone --depth=1 --quiet -b main https://github.com/QuickWrt/OpenBox
    cp -rf ./OpenBox/doc/feeds/feeds.conf.default ./openwrt/feeds.conf.default
    
    print_info "正在复制密钥文件..."
    if [ -d "openwrt" ]; then
        cd openwrt || error_exit "进入 openwrt 目录失败"
        
        if cp -rf ../OpenBox/key.tar.gz ./key.tar.gz; then
            if tar zxf key.tar.gz; then
                rm -f key.tar.gz
                print_info "密钥已复制并解压完成"
            else
                error_exit "解压 key.tar.gz 失败"
            fi
        else
            error_exit "复制 key.tar.gz 失败"
        fi
    else
        error_exit "未找到 openwrt 源码目录，下载源码失败"
    fi

    print_info "正在更新软件源 feeds..."
    echo -e "${BLUE_COLOR}├─ 更新软件包列表...${RESET}"
    if ./scripts/feeds update -a > /dev/null 2>&1; then
        echo -e "${GREEN_COLOR}├─ 软件包列表更新成功${RESET}"
    else
        error_exit "feeds 更新失败"
    fi
    
    echo -e "${BLUE_COLOR}├─ 安装软件包依赖...${RESET}"
    if ./scripts/feeds install -a > /dev/null 2>&1; then
        echo -e "${GREEN_COLOR}└─ 软件包依赖安装完成${RESET}"
        print_success "Feeds 更新和安装完成"
    else
        error_exit "feeds 安装失败"
    fi
}

# 执行构建脚本
execute_build_scripts() {
    local arch="$1"
    
    print_info "下载并执行构建脚本..."
    local scripts=(
        00-prepare_base.sh
        01-prepare_package.sh
        02-rockchip_target_only.sh
        02-x86_64_target_only.sh
    )

    # 下载所有脚本
    echo -e "${BLUE_COLOR}├─ 下载构建脚本...${RESET}"
    for script in "${scripts[@]}"; do
        if curl -sO "$MIRROR/scripts/$script"; then
            echo -e "${GREEN_COLOR}│   ✓ 已下载: $script${RESET}"
        else
            error_exit "下载脚本 $script 失败"
        fi
    done

    echo -e "${BLUE_COLOR}├─ 设置脚本执行权限...${RESET}"
    if chmod 0755 ./*.sh; then
        echo -e "${GREEN_COLOR}│   ✓ 权限设置完成${RESET}"
    else
        error_exit "设置脚本权限失败"
    fi

    # 执行基础准备脚本
    echo -e "${BLUE_COLOR}├─ 执行基础环境准备...${RESET}"
    local base_scripts=(
        "00-prepare_base.sh"
        "01-prepare_package.sh" 
    )

    for script in "${base_scripts[@]}"; do
        echo -e "${BLUE_COLOR}│   ├─ 执行: $script${RESET}"
        if bash "$script" > /dev/null 2>&1; then
            echo -e "${GREEN_COLOR}│   │   ✓ 完成${RESET}"
        else
            error_exit "脚本 $script 执行失败"
        fi
    done

    # 执行架构特定脚本
    echo -e "${BLUE_COLOR}├─ 执行架构特定配置...${RESET}"
    if [[ "$arch" == "rockchip" ]]; then
        echo -e "${BLUE_COLOR}│   ├─ 配置 Rockchip 架构${RESET}"
        if bash 02-rockchip_target_only.sh > /dev/null 2>&1; then
            echo -e "${GREEN_COLOR}│   │   ✓ Rockchip 架构配置完成${RESET}"
            print_success "Rockchip 架构配置完成"
        else
            error_exit "Rockchip 架构配置脚本执行失败"
        fi
    elif [[ "$arch" == "x86_64" ]]; then
        echo -e "${BLUE_COLOR}│   ├─ 配置 x86_64 架构${RESET}"
        if bash 02-x86_64_target_only.sh > /dev/null 2>&1; then
            echo -e "${GREEN_COLOR}│   │   ✓ x86_64 架构配置完成${RESET}"
            print_success "x86_64 架构配置完成"
        else
            error_exit "x86_64 架构配置脚本执行失败"
        fi
    fi

    # 清理临时脚本文件
    echo -e "${BLUE_COLOR}├─ 清理临时文件...${RESET}"
    if rm -f 0*-*.sh; then
        echo -e "${GREEN_COLOR}└─ ✓ 临时文件清理完成${RESET}"
    else
        print_warning "清理临时文件时出现警告，但可继续执行"
    fi

    print_success "构建环境准备完成"
}

# 加载配置文件
load_configuration() {
    local arch="$1"
    local config_file=""

    print_info "加载配置文件..."

    # 根据架构选择配置文件
    case "$arch" in
        rockchip)
            config_file="../OpenBox/config/config-rockchip"
            echo -e "${BLUE_COLOR}├─ 选择 Rockchip 架构配置${RESET}"
            ;;
        x86_64)
            config_file="../OpenBox/config/config-x86_64"
            echo -e "${BLUE_COLOR}├─ 选择 x86_64 架构配置${RESET}"
            ;;
    esac

    # 复制配置文件
    if [[ -n "$config_file" ]] && cp -rf "$config_file" ./.config; then
        echo -e "${GREEN_COLOR}└─ ✓ 配置文件加载完成${RESET}"
        print_success "$arch 架构配置文件已加载"
    fi

    # 更新版本号
    if [[ -n "$tag_version" ]]; then
        echo -e "${BLUE_COLOR}├─ 更新版本信息...${RESET}"
        sed -i "s|^CONFIG_VERSION_NUMBER=\".*\"|CONFIG_VERSION_NUMBER=\"$tag_version\"|" .config
        sed -i "s|^CONFIG_VERSION_REPO=\".*\"|CONFIG_VERSION_REPO=\"https://downloads.openwrt.org/releases/$tag_version\"|" .config
        echo -e "${GREEN_COLOR}└─ ✓ 已更新版本号为：$tag_version${RESET}"
    fi
}

# 生成 Config 文件
generate_config_file() {
    print_info "生成 Config 文件..."
    
    echo -e "${BLUE_COLOR}├─ 清理临时目录...${RESET}"
    if [ -d tmp ]; then
        if rm -rf tmp/*; then
            echo -e "${GREEN_COLOR}│   ✓ 临时目录已清理${RESET}"
        else
            print_warning "清理临时目录时出现警告"
        fi
    else
        echo -e "${YELLOW_COLOR}│   ⚠ 未找到 tmp 目录，跳过清理${RESET}"
    fi

    echo -e "${BLUE_COLOR}├─ 执行 make defconfig...${RESET}"
    if make defconfig > /dev/null 2>&1; then
        echo -e "${GREEN_COLOR}└─ ✓ Config 文件生成完成${RESET}"
    else
        error_exit "执行 make defconfig 失败"
    fi

    print_success "Config 文件生成完成"
}

# 下载预编译工具链（加速模式）
download_prebuilt_toolchain() {
    print_info "下载预编译工具链（加速模式）..."
    
    echo -e "${BLUE_COLOR}├─ 检测系统信息...${RESET}"
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        echo -e "${GREEN_COLOR}│   ✓ 检测到系统: $PRETTY_NAME${RESET}"
    else
        echo -e "${YELLOW_COLOR}│   ⚠ 无法检测系统信息${RESET}"
    fi
    
    echo -e "${BLUE_COLOR}├─ 下载工具链文件...${RESET}"
    local TOOLCHAIN_URL="https://github.com/QuickWrt/ZeroWrt/releases/download/Toolchain-Cache"
    local toolchain_file="toolchain_musl_${TOOLCHAIN_ARCH}_gcc-13.tar.zst"
    
    if curl -L "${TOOLCHAIN_URL}/${toolchain_file}" -o toolchain.tar.zst ${CURL_OPTIONS}; then
        echo -e "${GREEN_COLOR}│   ✓ 工具链下载完成${RESET}"
    else
        error_exit "工具链下载失败"
    fi
    
    echo -e "${BLUE_COLOR}├─ 解压工具链...${RESET}"
    if command -v zstd >/dev/null 2>&1; then
        if tar -I "zstd" -xf toolchain.tar.zst; then
            echo -e "${GREEN_COLOR}│   ✓ 工具链解压完成${RESET}"
        else
            error_exit "工具链解压失败"
        fi
    else
        error_exit "未找到 zstd 命令，请先安装 zstd"
    fi
    
    echo -e "${BLUE_COLOR}├─ 清理临时文件...${RESET}"
    if rm -f toolchain.tar.zst; then
        echo -e "${GREEN_COLOR}│   ✓ 临时文件清理完成${RESET}"
    else
        print_warning "清理临时文件时出现警告"
    fi
    
    echo -e "${BLUE_COLOR}├─ 创建目录结构...${RESET}"
    if mkdir -p bin; then
        echo -e "${GREEN_COLOR}│   ✓ 目录创建完成${RESET}"
    else
        error_exit "创建目录失败"
    fi
    
    echo -e "${BLUE_COLOR}├─ 更新文件时间戳...${RESET}"
    if find ./staging_dir/ -name '*' -exec touch {} \; >/dev/null 2>&1 && \
       find ./tmp/ -name '*' -exec touch {} \; >/dev/null 2>&1; then
        echo -e "${GREEN_COLOR}└─ ✓ 文件时间戳更新完成${RESET}"
    else
        print_warning "更新文件时间戳时出现警告"
    fi
    
    print_success "预编译工具链准备完成"
}

# 编译工具链（普通模式或工具链模式）
compile_toolchain() {
    print_info "开始编译工具链..."
    local starttime=$(date +'%Y-%m-%d %H:%M:%S')
    
    echo -e "${BLUE_COLOR}├─ 编译工具链...${RESET}"
    if make -j"$CPU_CORES" toolchain/compile || make -j"$CPU_CORES" toolchain/compile V=s; then
        echo -e "${GREEN_COLOR}│   ✓ 工具链编译完成${RESET}"
    else
        error_exit "工具链编译失败"
    fi
    
    # 如果是工具链模式，打包并退出
    if [[ "$BUILD_MODE" == "toolchain-only" ]]; then
        echo -e "${BLUE_COLOR}├─ 打包工具链缓存...${RESET}"
        if mkdir -p toolchain-cache && \
           tar -I "zstd -19 -T$(nproc --all)" -cf "toolchain-cache/toolchain_musl_${TOOLCHAIN_ARCH}_gcc-13.tar.zst" \
                ./build_dir ./dl ./staging_dir ./tmp; then
            echo -e "${GREEN_COLOR}│   ✓ 工具链缓存完成${RESET}"
        else
            error_exit "工具链缓存打包失败"
        fi
        
        local endtime=$(date +'%Y-%m-%d %H:%M:%S')
        local start_seconds=$(date --date="$starttime" +%s)
        local end_seconds=$(date --date="$endtime" +%s)
        local SEC=$((end_seconds-start_seconds))
        
        echo -e "${GREEN_COLOR}└─ ✓ 工具链任务完成，耗时: $(( SEC / 3600 ))h,$(( (SEC % 3600) / 60 ))m,$(( (SEC % 3600) % 60 ))s${RESET}"
        exit 0
    fi
    
    print_success "工具链编译完成"
}

# 编译 OpenWRT
compile_openwrt() {
    print_info "开始编译 OpenWRT..."
    local starttime=$(date +'%Y-%m-%d %H:%M:%S')

    echo -e "${BLUE_COLOR}├─ 更新 os-release 构建日期...${RESET}"
    sed -i "/BUILD_DATE/d" package/base-files/files/usr/lib/os-release
    sed -i "/BUILD_ID/aBUILD_DATE=\"$CURRENT_DATE\"" package/base-files/files/usr/lib/os-release
    
    echo -e "${BLUE_COLOR}├─ 执行 make 编译...${RESET}"
    if make -j"$CPU_CORES" IGNORE_ERRORS="n m"; then
        echo -e "${GREEN_COLOR}│   ✓ 编译过程完成${RESET}"
    else
        error_exit "OpenWrt 编译失败"
    fi

    # 计算编译时间
    local endtime=$(date +'%Y-%m-%d %H:%M:%S')
    local start_seconds=$(date --date="$starttime" +%s)
    local end_seconds=$(date --date="$endtime" +%s)
    local SEC=$((end_seconds-start_seconds))

    echo -e "${BLUE_COLOR}├─ 检查编译结果...${RESET}"
    if [ -f bin/targets/*/*/sha256sums ]; then
        echo -e "${GREEN_COLOR}│   ✓ Build success! ${RESET}"
    else
        echo -e "${RED_COLOR}│   ✗ Build error... ${RESET}"
        echo -e "${BLUE_COLOR}└─ 编译耗时: $(( SEC / 3600 ))h,$(( (SEC % 3600) / 60 ))m,$(( (SEC % 3600) % 60 ))s${RESET}"
        exit 1
    fi

    echo -e "${BLUE_COLOR}└─ 编译耗时: $(( SEC / 3600 ))h,$(( (SEC % 3600) / 60 ))m,$(( (SEC % 3600) % 60 ))s${RESET}"
}

# 获取内核版本并设置 kmod 包名
setup_kmod_package_name() {
    print_info "设置 KMOD 包名..."
    
    # 检查本地内核版本文件是否存在
    if [ ! -f "include/kernel-6.6" ]; then
        error_exit "内核版本文件 include/kernel-6.6 不存在"
    fi
    
    echo -e "${BLUE_COLOR}├─ 读取内核版本信息...${RESET}"
    get_kernel_version=$(cat include/kernel-6.6)
    
    if [ -z "$get_kernel_version" ]; then
        error_exit "无法读取内核版本信息"
    fi
    
    echo -e "${BLUE_COLOR}├─ 计算 KMOD 哈希值...${RESET}"
    kmod_hash=$(echo -e "$get_kernel_version" | awk -F'HASH-' '{print $2}' | awk '{print $1}' | tail -1 | md5sum | awk '{print $1}')
    
    if [ -z "$kmod_hash" ]; then
        error_exit "KMOD 哈希值计算失败"
    fi
    
    kmodpkg_name=$(echo $(echo -e "$get_kernel_version" | awk -F'HASH-' '{print $2}' | awk '{print $1}')~$(echo $kmod_hash)-r1)
    
    if [ -z "$kmodpkg_name" ]; then
        error_exit "KMOD 包名生成失败"
    fi
    
    echo -e "${GREEN_COLOR}└─ ✓ KMOD 包名设置为: $kmodpkg_name${RESET}"
    print_success "KMOD 包配置完成"
}

# 打包和生成OTA文件
package_and_generate_ota() {
    local architecture="$1"
    
    print_info "开始打包和生成OTA文件..."
    
    if [ "$architecture" = "x86_64" ]; then
        process_x86_64
    elif [ "$architecture" = "rockchip" ]; then
        process_rockchip
    else
        print_warning "未知架构: $architecture，跳过打包和OTA生成"
    fi
    
    print_success "打包和OTA生成完成"
}

# 处理 x86_64 架构
process_x86_64() {
    
    print_info "处理 x86_64 架构的打包..."
    
    # KMOD 包处理
    echo -e "${BLUE_COLOR}├─ 准备 KMOD 包...${RESET}"
    if cp -a bin/targets/x86/*/packages $kmodpkg_name/ && \
       rm -f $kmodpkg_name/Packages* && \
       cp -a bin/packages/x86_64/base/rtl88*a-firmware*.ipk $kmodpkg_name/ && \
       cp -a bin/packages/x86_64/base/natflow*.ipk $kmodpkg_name/; then
        echo -e "${GREEN_COLOR}│   ✓ KMOD 文件复制完成${RESET}"
    else
        print_warning "KMOD 文件复制过程中出现警告"
    fi
    
    echo -e "${BLUE_COLOR}├─ 签名 KMOD 包...${RESET}"
    if [ -f "kmod-sign" ] && bash kmod-sign $kmodpkg_name; then
        echo -e "${GREEN_COLOR}│   ✓ KMOD 包签名完成${RESET}"
    else
        print_warning "跳过 KMOD 签名（未找到 kmod-sign 脚本）"
    fi
    
    echo -e "${BLUE_COLOR}├─ 打包 KMOD...${RESET}"
    if tar zcf x86_64-$kmodpkg_name.tar.gz $kmodpkg_name; then
        echo -e "${GREEN_COLOR}│   ✓ KMOD 打包完成${RESET}"
    else
        error_exit "KMOD 打包失败"
    fi
    
    echo -e "${BLUE_COLOR}├─ 清理临时文件...${RESET}"
    rm -rf $kmodpkg_name
    echo -e "${GREEN_COLOR}└─ ✓ 临时文件清理完成${RESET}"
    
    # 生成 OTA JSON
    generate_x86_64_ota_json "$version"
}

# 生成 x86_64 OTA JSON
generate_x86_64_ota_json() {
    
    print_info "生成 x86_64 OTA JSON 文件..."
    
    echo -e "${BLUE_COLOR}├─ 创建 OTA 目录...${RESET}"
    mkdir -p ota
    
    echo -e "${BLUE_COLOR}├─ 计算 SHA256 校验和...${RESET}"
    local OTA_URL="https://github.com/QuickWrt/ZeroWrt/releases/download"
    local VERSION_NUMBER=$(echo "$tag_version" | sed 's/v//g')
    local SHA256=$(sha256sum bin/targets/x86/64*/*-generic-squashfs-combined-efi.img.gz | awk '{print $1}')
    
    echo -e "${BLUE_COLOR}├─ 生成 JSON 文件...${RESET}"
    cat > ota/x86_64.json <<EOF
{
  "x86_64": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-x86-64-generic-squashfs-combined-efi.img.gz"
    }
  ]
}
EOF
    
    if [ -f "ota/x86_64.json" ]; then
        echo -e "${GREEN_COLOR}└─ ✓ x86_64 OTA JSON 文件生成完成${RESET}"
        print_success "OTA 文件位置: ota/x86_64.json"
    else
        error_exit "OTA JSON 文件生成失败"
    fi
}

# 处理 rockchip 架构
process_rockchip() {
    
    print_info "处理 rockchip 架构的打包..."
    
    # KMOD 包处理
    echo -e "${BLUE_COLOR}├─ 准备 KMOD 包...${RESET}"
    if cp -a bin/targets/rockchip/armv8*/packages $kmodpkg_name && \
       rm -f $kmodpkg_name/Packages* && \
       cp -a bin/packages/aarch64_generic/base/rtl88*-firmware*.ipk $kmodpkg_name/ && \
       cp -a bin/packages/aarch64_generic/base/natflow*.ipk $kmodpkg_name/; then
        echo -e "${GREEN_COLOR}│   ✓ KMOD 文件复制完成${RESET}"
    else
        print_warning "KMOD 文件复制过程中出现警告"
    fi
    
    echo -e "${BLUE_COLOR}├─ 签名 KMOD 包...${RESET}"
    if [ -f "kmod-sign" ] && bash kmod-sign $kmodpkg_name; then
        echo -e "${GREEN_COLOR}│   ✓ KMOD 包签名完成${RESET}"
    else
        print_warning "跳过 KMOD 签名（未找到 kmod-sign 脚本）"
    fi
    
    echo -e "${BLUE_COLOR}├─ 打包 KMOD...${RESET}"
    if tar zcf armv8-$kmodpkg_name.tar.gz $kmodpkg_name; then
        echo -e "${GREEN_COLOR}│   ✓ KMOD 打包完成${RESET}"
    else
        error_exit "KMOD 打包失败"
    fi
    
    echo -e "${BLUE_COLOR}├─ 清理临时文件...${RESET}"
    rm -rf $kmodpkg_name
    echo -e "${GREEN_COLOR}└─ ✓ 临时文件清理完成${RESET}"
    
    # 生成 OTA JSON
    generate_rockchip_ota_json "$version"
}

# 生成 rockchip OTA JSON
generate_rockchip_ota_json() {
    
    print_info "生成 rockchip OTA JSON 文件..."
    
    echo -e "${BLUE_COLOR}├─ 创建 OTA 目录...${RESET}"
    mkdir -p ota
    
    echo -e "${BLUE_COLOR}├─ 计算各设备的 SHA256 校验和...${RESET}"
    local OTA_URL="https://github.com/QuickWrt/ZeroWrt/releases/download"
    local VERSION_NUMBER=$(echo "$tag_version" | sed 's/v//g')
    
    # 计算各个设备的SHA256
    local SHA256_armsom_sige3=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-armsom_sige3-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_armsom_sige7=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-armsom_sige7-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_t4=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopc-t4-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_t6=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopc-t6-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r2c_plus=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r2c-plus-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r2c=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r2c-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r2s=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r2s-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r3s=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r3s-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r4s=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r4s-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r4se=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r4se-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r5c=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r5c-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r5s=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r5s-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r6c=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r6c-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r6s=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r6s-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_huake_guangmiao_g4c=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-huake_guangmiao-g4c-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r66s=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-lunzn_fastrhino-r66s-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_r68s=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-lunzn_fastrhino-r68s-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_radxa_rock_5a=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-radxa_rock-5a-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_radxa_rock_5b=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-radxa_rock-5b-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_xunlong_orangepi_5_plus=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-xunlong_orangepi-5-plus-squashfs-sysupgrade.img.gz | awk '{print $1}')
    local SHA256_xunlong_orangepi_5=$(sha256sum bin/targets/rockchip/armv8*/zerowrt-$VERSION_NUMBER-rockchip-armv8-xunlong_orangepi-5-squashfs-sysupgrade.img.gz | awk '{print $1}')
    
    echo -e "${BLUE_COLOR}├─ 生成 rockchip JSON 文件...${RESET}"
    cat > ota/rockchip.json <<EOF
{
  "armsom,sige3": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_armsom_sige3",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-armsom_sige3-squashfs-sysupgrade.img.gz"
    }
  ],
  "armsom,sige7": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_armsom_sige7",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-armsom_sige7-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopc-t4": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_t4",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopc-t4-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopc-t6": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_t6",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopc-t6-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r2c-plus": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r2c_plus",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r2c-plus-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r2c": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r2c",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r2c-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r2s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r2s",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r2s-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r3s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r3s",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r3s-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r4s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r4s",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r4s-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r4se": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r4se",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r4se-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r5c": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r5c",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r5c-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r5s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r5s",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r5s-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r6c": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r6c",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r6c-squashfs-sysupgrade.img.gz"
    }
  ],
  "friendlyarm,nanopi-r6s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r6s",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-friendlyarm_nanopi-r6s-squashfs-sysupgrade.img.gz"
    }
  ],
  "huake,guangmiao-g4c": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_huake_guangmiao_g4c",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-huake_guangmiao-g4c-squashfs-sysupgrade.img.gz"
    }
  ],
  "lunzn,fastrhino-r66s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r66s",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-lunzn_fastrhino-r66s-squashfs-sysupgrade.img.gz"
    }
  ],
  "lunzn,fastrhino-r68s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_r68s",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-lunzn_fastrhino-r68s-squashfs-sysupgrade.img.gz"
    }
  ],
  "radxa,rock-5a": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_radxa_rock_5a",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-radxa_rock-5a-squashfs-sysupgrade.img.gz"
    }
  ],
  "radxa,rock-5b": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_radxa_rock_5b",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-radxa_rock-5b-squashfs-sysupgrade.img.gz"
    }
  ],
  "xunlong,orangepi-5-plus": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_xunlong_orangepi_5_plus",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-xunlong_orangepi-5-plus-squashfs-sysupgrade.img.gz"
    }
  ],
  "xunlong,orangepi-5": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256_xunlong_orangepi_5",
      "url": "$OTA_URL/OpenWrt-$VERSION_NUMBER/zerowrt-$VERSION_NUMBER-rockchip-armv8-xunlong_orangepi-5-squashfs-sysupgrade.img.gz"
    }
  ]
}
EOF
    
    if [ -f "ota/rockchip.json" ]; then
        echo -e "${GREEN_COLOR}└─ ✓ rockchip OTA JSON 文件生成完成${RESET}"
        print_success "OTA 文件位置: ota/rockchip.json"
    else
        error_exit "OTA JSON 文件生成失败"
    fi
}

# =============================================================================
# 主程序逻辑
# =============================================================================
main() {
    local version="${1:-}"
    local architecture="${2:-}"
    local build_mode="${3:-normal}"
    
    # 参数验证
    validate_arguments "$version" "$architecture" "$build_mode"
    
    # 设置工具链架构
    setup_toolchain_arch "$architecture"
    
    # 显示横幅
    show_banner
    
    # 环境设置
    setup_build_environment
    setup_curl_progress
    
    print_success "初始化完成，开始构建 $architecture 架构的 $version 版本，模式：$BUILD_MODE"
    
    # 记录开始时间
    START_TIME=$(date +%s)
    
    # 步骤1: 准备源代码
    prepare_source_code
    
    # 步骤2: 执行构建脚本
    execute_build_scripts "$architecture"
    
    # 步骤3: 加载配置文件
    load_configuration "$architecture"
    
    # 步骤4: 生成 Config 文件（必须在工具链之前）
    generate_config_file
    
    # 根据编译模式执行不同逻辑
    case "$BUILD_MODE" in
        "accelerated")
            # 加速模式：下载预编译工具链
            download_prebuilt_toolchain
            # 然后直接编译 OpenWRT
            compile_openwrt
            ;;
        "normal")
            # 普通模式：完整编译工具链和 OpenWRT
            compile_toolchain
            compile_openwrt
            ;;
        "toolchain-only")
            # 仅编译工具链模式
            compile_toolchain
            ;;
    esac

    if [[ "$BUILD_MODE" != "toolchain-only" ]]; then
        setup_kmod_package_name
        package_and_generate_ota "$architecture"
    fi
    
    # 计算总耗时
    local END_TIME=$(date +%s)
    local TOTAL_SEC=$((END_TIME - START_TIME))
    print_success "构建完成！总耗时: $((TOTAL_SEC / 3600))h,$(( (TOTAL_SEC % 3600) / 60 ))m,$((TOTAL_SEC % 60))s"
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
