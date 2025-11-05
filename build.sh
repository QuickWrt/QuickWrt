#!/bin/bash -e

# 定义全局颜色
export RED_COLOR='\e[1;31m'
export GREEN_COLOR='\e[1;32m'
export YELLOW_COLOR='\e[1;33m'
export BLUE_COLOR='\e[1;34m'
export MAGENTA_COLOR='\e[1;35m'
export CYAN_COLOR='\e[1;36m'
export GOLD_COLOR='\e[1;33m'
export BOLD='\e[1m'
export RESET='\e[0m'

# 当前脚本版本号
VERSION='v1.2.0 (2025.11.04)'

# 各变量默认值
export AUTHOR="OPPEN321"
export BLOG="www.kejizero.online"
export MIRROR="https://openwrt.kejizero.xyz"
export CPU_CORES=$(nproc)
export GCC_VERSION=${gcc_version:-13}
export PASSWORD="MzE4MzU3M2p6"

# 编译模式
case "$2" in
    "accelerated") 
        export BUILD_MODE="加速编译"
        ;;
    "normal") 
        export BUILD_MODE="普通编译"
        ;;
    "toolchain-only") 
        export BUILD_MODE="仅工具链"
        ;;
    *) 
        export BUILD_MODE="加速编译"
        ;;
esac

# 密码验证
validate_password() {
    clear
    local attempts=0
    local max_attempts=3
    
    while [ $attempts -lt $max_attempts ]; do
        echo -e "${BOLD}${MAGENTA_COLOR}════════════════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN_COLOR}                   🔐 ZeroWrt 私有系统访问验证 🔐${RESET}"
        echo -e "${BOLD}${MAGENTA_COLOR}════════════════════════════════════════════════════════════════${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW_COLOR}⚠️  此系统为授权用户专用，请验证您的身份${RESET}"
        echo ""
        echo -e "${BOLD}${GOLD_COLOR}请输入访问密码：${RESET}"
        echo -n -e "${BOLD}${GREEN_COLOR}➤ ${RESET}"
        read -s user_input
        echo ""
        
        local reversed_input=$(echo "$user_input" | rev)
        local encoded_reversed_input=$(echo -n "$reversed_input" | base64)
        encoded_reversed_input=$(echo -n "$encoded_reversed_input" | tr -d '\n')
        
        if [ "$encoded_reversed_input" = "$PASSWORD" ]; then
            echo ""
            echo -e "${BOLD}${GREEN_COLOR}✅ 身份验证成功！正在加载系统...${RESET}"
            echo -e "${BOLD}${MAGENTA_COLOR}════════════════════════════════════════════════════════════════${RESET}"
            sleep 2
            return 0
        else
            attempts=$((attempts + 1))
            remaining=$((max_attempts - attempts))
            echo ""
            echo -e "${BOLD}${RED_COLOR}❌ 密码错误！剩余尝试次数: ${remaining}${RESET}"
            
            if [ $attempts -eq $max_attempts ]; then
                echo ""
                echo -e "${BOLD}${RED_COLOR}🚫 验证失败次数过多，系统退出！${RESET}"
                echo -e "${BOLD}${YELLOW_COLOR}📞 请联系系统管理员获取访问权限${RESET}"
                echo -e "${BOLD}${MAGENTA_COLOR}════════════════════════════════════════════════════════════════${RESET}"
                exit 1
            fi
            echo -e "${BOLD}${YELLOW_COLOR}⏳ 2秒后重新尝试...${RESET}"
            sleep 2
            clear
        fi
    done
}

# 打印
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
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🛠️  开发者: $AUTHOR                                              ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🌐 博客: $BLOG                                     ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 💡 理念: 开源 · 定制化 · 高性能                                  ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 📦 版本: $VERSION                                     ${BOLD}${BLUE_COLOR}║${RESET}"    
    echo -e "${BOLD}${BLUE_COLOR}╠══════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🔧 构建开始: $(date '+%Y-%m-%d %H:%M:%S')                                 ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} ⚡ 处理器核心: $CPU_CORES 个                                              ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🐧 系统用户: $(whoami)                                                ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🔬 GCC 版本: $GCC_VERSION                                                  ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🚀 编译模式: $BUILD_MODE                                            ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}╚══════════════════════════════════════════════════════════════════╝${RESET}"
    echo -e ""
}

# 初始化构建环境
setup_build_environment() {
    if [[ "$(id -u)" == "0" ]]; then
        export FORCE_UNSAFE_CONFIGURE=1 FORCE=1
        echo -e "${BOLD}${RED_COLOR}以 root 权限运行，已启用强制不安全配置${RESET}"
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

# 编译脚本 - 克隆源代码
prepare_source_code() {
    ### 第一步：查询版本 ###
    clear
    echo -e "${BOLD}${BLUE_COLOR}■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                   准备源代码 [1/4]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""    
    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}查询最新 OpenWRT 版本${RESET}"
    
    # 获取版本号
    tag_version="$(curl -s https://github.com/openwrt/openwrt/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*.tar.gz" | sed -n '/[2-9][4-9]/p' | sed -n 1p | sed 's/v//g' | sed 's/.tar.gz//g')"
    export tag_version="$tag_version"
    
    echo -e "  ${BOLD}${GREEN_COLOR}✓${RESET} ${BOLD}版本检测完成${RESET}"
    echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}最新版本: ${GREEN_COLOR}$tag_version${RESET}"
    echo ""

    ### 第二步：克隆代码 ###
    clear
    echo -e "${BOLD}${BLUE_COLOR}■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                   克隆源代码 [2/4]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""
    
    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}开始克隆源代码仓库...${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📦 仓库: ${CYAN_COLOR}https://github.com/openwrt/openwrt${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🏷️  版本: ${YELLOW_COLOR}v$tag_version${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    
    # 显示克隆进度
    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}正在下载源代码，请稍候...${RESET}"
    
    # 克隆源代码（隐藏所有错误输出）
    if git -c advice.detachedHead=false clone --depth=1 --branch "v$tag_version" --single-branch --quiet https://github.com/openwrt/openwrt 2>/dev/null; then
        echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
        echo -e "  ${BOLD}${GREEN_COLOR}✓${RESET} ${BOLD}源代码克隆成功${RESET}"
        echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}存储位置: ${GREEN_COLOR}$(pwd)/openwrt${RESET}"
        echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}分支版本: ${GREEN_COLOR}v$tag_version${RESET}"
    else
        echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
        echo -e "  ${BOLD}${RED_COLOR}✗${RESET} ${BOLD}源代码克隆失败${RESET}"
        return 1
    fi
    echo ""

    ### 第三步：更新 feeds.conf.default ###
    clear
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                   更新 feeds.conf.default [3/4]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""

    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📁 目标文件: ${CYAN_COLOR}feeds.conf.default${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🔄 正在更新软件源配置...${RESET}"
    sed -i 's#^src-git packages .*#src-git packages https://github.com/openwrt/packages.git;openwrt-24.10#' feeds.conf.default
    sed -i 's#^src-git luci .*#src-git luci https://github.com/openwrt/luci.git;openwrt-24.10#' feeds.conf.default
    sed -i 's#^src-git routing .*#src-git routing https://github.com/openwrt/routing.git;openwrt-24.10#' feeds.conf.default
    sed -i 's#^src-git telephony .*#src-git telephony https://github.com/openwrt/telephony.git;openwrt-24.10#' feeds.conf.default
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${GREEN_COLOR}✓${RESET} ${BOLD}软件源配置完成${RESET}"
    echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}已更新 4 个软件源到 openwrt-24.10 分支${RESET}"
    echo ""

    ### 第四步：更新和安装 feeds ###
    clear
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                   更新和安装 Feeds [4/4]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""

    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}开始更新和安装软件包源...${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"

    # 检查是否在 openwrt 目录中
    if [ ! -f "feeds.conf.default" ] || [ ! -d "scripts" ]; then
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}✗${RESET} ${BOLD}错误: 请在 openwrt 根目录中运行此脚本${RESET}"
        echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
        echo -e "  ${BOLD}${RED_COLOR}✗${RESET} ${BOLD}Feeds 更新失败${RESET}"
        return 1
    fi

    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📦 操作: 更新所有软件包源${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ⚡ 命令: ./scripts/feeds update -a${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"

    # 更新 feeds
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🔄 正在更新软件包源列表...${RESET}"
    if ./scripts/feeds update -a >/dev/null 2>&1; then
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}软件包源更新成功${RESET}"
    else
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}✗${RESET} ${BOLD}软件包源更新失败${RESET}"
        echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
        echo -e "  ${BOLD}${RED_COLOR}✗${RESET} ${BOLD}Feeds 更新失败${RESET}"
        return 1
    fi

    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📦 操作: 安装所有软件包${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ⚡ 命令: ./scripts/feeds install -a${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"

    # 安装 feeds
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🔧 正在安装软件包...${RESET}"
    if ./scripts/feeds install -a >/dev/null 2>&1; then
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}软件包安装成功${RESET}"
    else
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}✗${RESET} ${BOLD}软件包安装失败${RESET}"
        echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
        echo -e "  ${BOLD}${RED_COLOR}✗${RESET} ${BOLD}Feeds 安装失败${RESET}"
        return 1
    fi

    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${GREEN_COLOR}✓${RESET} ${BOLD}Feeds 更新和安装完成${RESET}"
    echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}所有软件包源已就绪，可以开始配置编译${RESET}"
    echo ""
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■${RESET}"
    echo -e "${BOLD}${GREEN_COLOR}                   源代码准备阶段完成！${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■${RESET}"
    echo ""
}
    
# 主执行逻辑
main() {
    validate_password
    show_banner
    setup_build_environment
    setup_curl_progress
    prepare_source_code
}

main "$@"
