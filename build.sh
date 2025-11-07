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
version='v1.2.1 (2025.11.06)'

# 各变量默认值
export author="OPPEN321"
export blog="www.kejizero.online"
export mirror="https://openwrt.kejizero.xyz"
export gitea="gitea.kejizero.xyz"
export github="github.com"
export cpu_cores=$(nproc)
export gcc=${gcc_version:-15}
export password="MzE4MzU3M2p6"
export CURRENT_DATE=$(date +%Y%m%d)
export supported_boards="x86_64 rockchip"
export supported_build_modes=("accelerated" "normal" "toolchain-only")

# 设备类型
case "$1" in
    rockchip)
        platform="rockchip"
        toolchain_arch="aarch64_generic"
        ;;
    x86_64)
        platform="x86_64"
        toolchain_arch="x86_64"
        ;;
esac
export platform toolchain_arch

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
        
        if [ "$encoded_reversed_input" = "$password" ]; then
            echo ""
            echo -e "${BOLD}${GREEN_COLOR}✅ 身份验证成功！正在加载系统...${RESET}"
            export git_password="$user_input"
            echo -e "${BOLD}${CYAN_COLOR}🔑 Git 密码已保存到环境变量${RESET}"            
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

# 显示使用帮助
show_usage() {
    clear
    echo -e "${BOLD}${BLUE_COLOR}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║                        📚 使用帮助 📚                        ║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${BOLD}${CYAN_COLOR}📖 使用方法:${RESET}"
    echo -e "  ${BOLD}bash $0 <architecture> [build_mode]${RESET}"
    echo ""
    echo -e "${BOLD}${CYAN_COLOR}🏗️  支持的架构:${RESET}"
    for arch in "${supported_boards[@]}"; do
        echo -e "  ${BOLD}${GREEN_COLOR}▶${RESET} ${GREEN_COLOR}$arch${RESET}"
    done
    echo ""
    echo -e "${BOLD}${CYAN_COLOR}⚙️  支持的编译模式:${RESET}"
    echo -e "  ${BOLD}${GREEN_COLOR}▶${RESET} ${GREEN_COLOR}accelerated${RESET}   - 加速编译（下载预编译工具链）"
    echo -e "  ${BOLD}${GREEN_COLOR}▶${RESET} ${GREEN_COLOR}normal${RESET}        - 普通编译（完整编译所有组件）"
    echo -e "  ${BOLD}${GREEN_COLOR}▶${RESET} ${GREEN_COLOR}toolchain-only${RESET} - 仅编译工具链（用于缓存）"
    echo ""
    echo -e "${BOLD}${CYAN_COLOR}🌰 使用示例:${RESET}"
    echo -e "  ${BOLD}bash $0 x86_64 accelerated${RESET}"
    echo -e "  ${BOLD}bash $0 rockchip normal${RESET}"
    echo -e "  ${BOLD}bash $0 x86_64 toolchain-only${RESET}"
    echo ""
    echo -e "${BOLD}${BLUE_COLOR}════════════════════════════════════════════════════════════════${RESET}"
}

# 参数检测
if [ $# -eq 0 ] || [ -z "$1" ]; then
    echo -e "${BOLD}${RED_COLOR}❌ 错误：请指定架构参数！${RESET}"
    show_usage
    exit 1
fi

# 检查第一个参数是否为支持的架构
if [[ ! " ${supported_boards[@]} " =~ " ${platform} " ]]; then
    show_usage
    exit 1
fi

# 检查第二个参数是否为支持的编译模式
if [ $# -ge 2 ] && [ -n "$2" ]; then
    build_mode_input="$2"
    if [[ ! " ${supported_build_modes[@]} " =~ " ${build_mode_input} " ]]; then
        show_usage
        exit 1
    fi
fi

# 编译模式设置
case "$build_mode_input" in
    "accelerated") 
        export build_mode="加速编译"
        ;;
    "normal") 
        export build_mode="普通编译"
        ;;
    "toolchain-only") 
        export build_mode="仅工具链"
        ;;
    *) 
        export build_mode="加速编译"
        ;;
esac

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
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🛠️  开发者: $author                                              ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🌐 博客: $blog                                     ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 💡 理念: 开源 · 定制化 · 高性能                                  ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 📦 版本: $version                                     ${BOLD}${BLUE_COLOR}║${RESET}"    
    echo -e "${BOLD}${BLUE_COLOR}╠══════════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🔧 构建开始: $(date '+%Y-%m-%d %H:%M:%S')                                 ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} ⚡ 处理器核心: $cpu_cores 个                                              ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🐧 系统用户: $(whoami)                                                ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🔬 GCC 版本: $gcc                                                  ${BOLD}${BLUE_COLOR}║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║${RESET} 🚀 编译模式: $build_mode                                            ${BOLD}${BLUE_COLOR}║${RESET}"
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
    if curl --help | grep progress-bar >/dev/null 2>&1; then
        CURL_BAR="--progress-bar";
    fi
}

# 编译脚本 - 克隆源代码
prepare_source_code() {
    ### 第一步：查询版本 ###
    echo -e "${BOLD}${BLUE_COLOR}■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                   准备源代码 [1/7]${RESET}"
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
    echo -e "${BOLD}${BLUE_COLOR}■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                   克隆源代码 [2/7]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""

    # 根据用户选择克隆地址（zhao 用局域网，否则用 GitHub）
    git_url=$([ "$(whoami)" = "zhao" ] && echo "http://10.0.0.101:3000/zhao/openwrt" || echo "https://github.com/openwrt/openwrt")

    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}开始克隆源代码仓库...${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📦 仓库: ${CYAN_COLOR}$git_url${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🏷️  版本: ${YELLOW_COLOR}v$tag_version${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"

    # 显示克隆进度
    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}正在下载源代码，请稍候...${RESET}"

    # 克隆源代码（隐藏所有错误输出）
    if git -c advice.detachedHead=false clone --depth=1 --branch "v$tag_version" --single-branch --quiet "$git_url" && cd openwrt 2>/dev/null; then
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
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                   更新 feeds.conf.default [3/7]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""

    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📁 目标文件: ${CYAN_COLOR}feeds.conf.default${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🔄 正在更新软件源配置...${RESET}"

    # 判断用户选择镜像源
    if [ "$(whoami)" = "zhao" ]; then
        code_mirror="http://10.0.0.101:3000/zhao"
        source_type="私人源"
    else
        code_mirror="https://github.com/openwrt"
        source_type="官方源"
    fi

    # 输出当前使用源类型
    echo -e "  ${BOLD}${CYAN_COLOR}ℹ${RESET} 当前使用源类型: ${BOLD}${YELLOW_COLOR}$source_type${RESET}"

    # 统一替换 feeds
    sed -i "s#^src-git packages .*#src-git packages $code_mirror/packages.git;openwrt-24.10#" feeds.conf.default
    sed -i "s#^src-git luci .*#src-git luci $code_mirror/luci.git;openwrt-24.10#" feeds.conf.default
    sed -i "s#^src-git routing .*#src-git routing $code_mirror/routing.git;openwrt-24.10#" feeds.conf.default
    sed -i "s#^src-git telephony .*#src-git telephony $code_mirror/telephony.git;openwrt-24.10#" feeds.conf.default

    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${GREEN_COLOR}✓${RESET} ${BOLD}软件源配置完成${RESET}"
    echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}已更新 4 个软件源到 openwrt-24.10 分支${RESET}"
    echo ""

    ### 第四步：更新和安装 feeds ###
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                   更新和安装 Feeds [4/7]${RESET}"
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

    ### 第五步：更新密钥文件 ###
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                         更新密钥文件 [5/7]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""

    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}开始更新安全密钥文件...${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🔑 操作: 下载并安装密钥文件${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🌐 镜像源: ${CYAN_COLOR}$mirror${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"

    # 下载密钥文件
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📥 正在下载密钥文件...${RESET}"
    if curl -fs --connect-timeout 30 "$mirror/openwrt/patch/key.tar.gz" -o key.tar.gz 2>/dev/null; then
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}密钥文件下载成功${RESET}"
    
        # 解压密钥文件
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📂 正在解压密钥文件...${RESET}"
        if tar -zxf key.tar.gz 2>/dev/null; then
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}密钥文件解压成功${RESET}"
        
            # 清理临时文件
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🧹 清理临时文件...${RESET}"
            if rm -f key.tar.gz 2>/dev/null; then
                echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}临时文件已清理${RESET}"
            else
                echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${YELLOW_COLOR}⚠${RESET} ${BOLD}临时文件清理失败${RESET}"
            fi
        
            echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
            echo -e "  ${BOLD}${GREEN_COLOR}✓${RESET} ${BOLD}密钥文件更新完成${RESET}"
            echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}安全密钥已配置，准备编译环境${RESET}"
        else
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}✗${RESET} ${BOLD}密钥文件解压失败${RESET}"
            echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
            echo -e "  ${BOLD}${RED_COLOR}✗${RESET} ${BOLD}密钥更新失败${RESET}"
            return 1
        fi
    else
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}✗${RESET} ${BOLD}密钥文件下载失败${RESET}"
        echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
        echo -e "  ${BOLD}${YELLOW_COLOR}⚠${RESET} ${BOLD}请检查网络连接或镜像源可用性${RESET}"
        return 1
    fi

    ### 第六步：执行构建脚本 ###
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                         执行构建脚本 [6/7]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""

    scripts=(
        "00-prepare_base.sh"
        "01-prepare_base-mainline.sh" 
        "02-prepare_package.sh"
        "04-fix_kmod.sh"
        "05-fix-source.sh"
    )

    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}开始执行构建脚本...${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📦 下载构建脚本 (${#scripts[@]}个)${RESET}"

    # 下载脚本
    downloaded_count=0
    for script in "${scripts[@]}"; do
        echo -ne "  ${BOLD}${MAGENTA_COLOR}│   📥 ${CYAN_COLOR}$script${RESET}"
        if curl -fs --connect-timeout 30 "$mirror/openwrt/scripts/$script" -o "$script" 2>/dev/null; then
            echo -e " ${GREEN_COLOR}✅${RESET}"
            downloaded_count=$((downloaded_count + 1))
        else
            echo -e " ${RED_COLOR}❌${RESET}"
            echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
            echo -e "  ${BOLD}${RED_COLOR}✗${RESET} ${BOLD}脚本下载失败${RESET}"
            return 1
        fi
    done

    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}下载完成: ${downloaded_count}/${#scripts[@]}${RESET}"

    # 设置权限
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🔧 设置执行权限...${RESET}"
    if chmod 0755 *.sh 2>/dev/null; then
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}权限设置成功${RESET}"
    else
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}✗${RESET} ${BOLD}权限设置失败${RESET}"
        return 1
    fi

    # 执行构建脚本
    build_scripts=(
        "00-prepare_base.sh"
        "01-prepare_base-mainline.sh"
        "02-prepare_package.sh"
        "04-fix_kmod.sh"
        "05-fix-source.sh"
    )

    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🚀 执行构建脚本...${RESET}"
    executed_count=0
    for script in "${build_scripts[@]}"; do
        echo -ne "  ${BOLD}${MAGENTA_COLOR}│   ⚡ ${CYAN_COLOR}$script${RESET}"
        if bash "$script" >/dev/null 2>&1; then
            echo -e " ${GREEN_COLOR}✅${RESET}"
            executed_count=$((executed_count + 1))
        else
            echo -e " ${RED_COLOR}❌${RESET}"
        fi
    done

    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}执行完成: ${executed_count}/${#build_scripts[@]}${RESET}"

    # 清理临时文件
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🧹 清理临时文件...${RESET}"
    if rm -f 0*-*.sh 2>/dev/null; then
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}清理完成${RESET}"
    else
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${YELLOW_COLOR}⚠${RESET} ${BOLD}清理失败${RESET}"
    fi

    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${GREEN_COLOR}✓${RESET} ${BOLD}构建脚本执行完成${RESET}"
    echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}成功执行 ${executed_count}/${#build_scripts[@]} 个构建脚本${RESET}"
    echo ""

    ### 第七步：加载配置文件 ###
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                         加载配置文件 [7/7]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""
    
    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}加载配置文件...${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    
    # 根据架构下载对应的配置文件
    case "$platform" in
        "x86_64")
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🖥️  检测到 x86_64 架构${RESET}"
            curl -s $mirror/openwrt/24-config-musl-x86 > .config
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}下载 x86 配置文件${RESET}"
            ;;
        "rockchip")
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📱 检测到 Rockchip 架构${RESET}"
            curl -s $mirror/openwrt/24-config-musl-rockchip > .config
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}下载 Rockchip 配置文件${RESET}"
            ;;
        *)
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}❌${RESET} ${BOLD}错误：未知架构 '$1'${RESET}"
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${YELLOW_COLOR}ℹ️ ${RESET} ${BOLD}支持的架构: ${supported_boards[*]}${RESET}"
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}🚫${RESET} ${BOLD}脚本终止执行${RESET}"
            echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
            echo -e "  ${BOLD}${RED_COLOR}✗${RESET} ${BOLD}配置文件加载失败${RESET}"
            exit 1
            ;;
    esac
    
    # 应用 GCC 补丁
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🔧 应用 GCC 补丁...${RESET}"
    if curl -s $mirror/openwrt/patch/generic-24.10/202-toolchain-gcc-add-support-for-GCC-15.patch | patch -p1 > /dev/null 2>&1; then
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}GCC 补丁应用成功${RESET}"
    else
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}✗${RESET} ${BOLD}GCC 补丁应用失败${RESET}"
    fi
    
    # 配置 GCC 版本
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ⚙️  配置 GCC 版本 (${gcc})...${RESET}"
    {
        echo -e "\n# gcc ${gcc}"
        echo -e "CONFIG_DEVEL=y"
        echo -e "CONFIG_TOOLCHAINOPTS=y" 
        echo -e "CONFIG_GCC_USE_VERSION_${gcc}=y\n"
    } >> .config
    
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}GCC ${gcc} 配置完成${RESET}"
    
    # 生成 defconfig
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ⚙️  生成 defconfig...${RESET}"
    if make defconfig > /dev/null 2>&1; then
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${GREEN_COLOR}✓${RESET} ${BOLD}defconfig 生成成功${RESET}"
    else
        echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${RED_COLOR}✗${RESET} ${BOLD}defconfig 生成失败${RESET}"
        echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
        echo -e "  ${BOLD}${RED_COLOR}✗${RESET} ${BOLD}配置文件加载失败${RESET}"
        exit 1
    fi
    
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${GREEN_COLOR}✓${RESET} ${BOLD}配置文件加载完成${RESET}"
    echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}架构: ${CYAN_COLOR}${platform}${RESET}"
    echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}GCC 版本: ${CYAN_COLOR}${gcc}${RESET}"
    echo ""
    
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■${RESET}"
    echo -e "${BOLD}${GREEN_COLOR}                   源代码准备阶段完成！${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■ ■${RESET}"
    echo ""
}

# 编译执行函数
compile_source_code() {
    echo -e "${BOLD}${BLUE_COLOR}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║                     🚀 编译阶段开始 🚀                       ║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    # 显示编译配置信息
    echo -e "  ${BOLD}${CYAN_COLOR}⚙️  编译配置${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 架构平台: ${GREEN_COLOR}${platform}${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 编译模式: ${GREEN_COLOR}${build_mode}${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ GCC 版本: ${GREEN_COLOR}${gcc}${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 并行编译: ${GREEN_COLOR}${cpu_cores} 核心${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}└─ 开始时间: ${GREEN_COLOR}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo ""

    # 根据编译模式执行不同的编译流程
    case "$build_mode_input" in
        "normal")
            # 普通编译模式
            echo -e "${BOLD}${GREEN_COLOR}▶ 普通编译模式${RESET}"
            echo -e "  ${BOLD}${CYAN_COLOR}────────────────────────────────────────────────────────────${RESET}"
            
            # 更新构建日期
            echo -e "  ${BOLD}${YELLOW_COLOR}📝 更新构建信息...${RESET}"
            sed -i "/BUILD_DATE/d" package/base-files/files/usr/lib/os-release
            sed -i "/BUILD_ID/aBUILD_DATE=\"$CURRENT_DATE\"" package/base-files/files/usr/lib/os-release
            echo -e "    ${GREEN_COLOR}✓${RESET} 构建日期: ${CURRENT_DATE}"
            
            # 开始编译
            echo -e "  ${BOLD}${YELLOW_COLOR}🔨 开始编译固件...${RESET}"
            echo -e "    ${CYAN_COLOR}▶${RESET} 使用核心: ${cpu_cores}"
            echo -e "    ${CYAN_COLOR}▶${RESET} 编译命令: make -j${cpu_cores} IGNORE_ERRORS=\"n m\""
            echo ""
            
            if make -j$cpu_cores IGNORE_ERRORS="n m"; then
                echo -e "  ${BOLD}${GREEN_COLOR}✅ 普通编译完成${RESET}"
            else
                echo -e "  ${BOLD}${RED_COLOR}❌ 编译失败${RESET}"
                return 1
            fi
            ;;

        "toolchain-only")
            # 仅编译工具链模式
            echo -e "${BOLD}${GREEN_COLOR}▶ 工具链编译模式${RESET}"
            echo -e "  ${BOLD}${CYAN_COLOR}────────────────────────────────────────────────────────────${RESET}"
            
            # 编译工具链
            echo -e "  ${BOLD}${YELLOW_COLOR}🔧 编译工具链...${RESET}"
            echo -e "    ${CYAN_COLOR}▶${RESET} 使用核心: ${cpu_cores}"
            echo ""
            
            if make -j$cpu_cores toolchain/compile || make -j$cpu_cores toolchain/compile V=s; then
                echo -e "    ${GREEN_COLOR}✓${RESET} 工具链编译完成"
                
                # 创建工具链缓存
                echo -e "  ${BOLD}${YELLOW_COLOR}💾 创建工具链缓存...${RESET}"
                mkdir -p toolchain-cache
                
                if tar -I "zstd -19 -T$(nproc --all)" -cf toolchain-cache/toolchain_musl_${toolchain_arch}_gcc-${gcc}.tar.zst ./{build_dir,dl,staging_dir,tmp}; then
                    echo -e "    ${GREEN_COLOR}✓${RESET} 缓存文件: toolchain_musl_${toolchain_arch}_gcc-${gcc}.tar.zst"
                else
                    echo -e "    ${RED_COLOR}✗${RESET} 缓存创建失败"
                    return 1
                fi
            else
                echo -e "    ${RED_COLOR}✗${RESET} 工具链编译失败"
                return 1
            fi
            ;;

        "accelerated")
            # 加速编译模式
            echo -e "${BOLD}${GREEN_COLOR}▶ 加速编译模式${RESET}"
            echo -e "  ${BOLD}${CYAN_COLOR}────────────────────────────────────────────────────────────${RESET}"
            
            # 下载预编译工具链
            echo -e "  ${BOLD}${YELLOW_COLOR}📥 下载预编译工具链...${RESET}"
            
            # 确定工具链URL
            if [ "$(whoami)" = "zhao" ]; then
                TOOLCHAIN_URL="http://10.0.0.101:8080/openwrt_caches"
            else
                TOOLCHAIN_URL="https://$github/QuickWrt/openwrt_caches/releases/download/openwrt-24.10"
            fi
            
            echo -e "    ${CYAN_COLOR}▶${RESET} 下载源: ${TOOLCHAIN_URL}"
            echo -e "    ${CYAN_COLOR}▶${RESET} 目标文件: toolchain_musl_${toolchain_arch}_gcc-${gcc}.tar.zst"
            
            if curl -L ${TOOLCHAIN_URL}/toolchain_musl_${toolchain_arch}_gcc-${gcc}.tar.zst -o toolchain.tar.zst $CURL_BAR >/dev/null 2>&1; then
                echo -e "    ${GREEN_COLOR}✓${RESET} 工具链下载成功"
                
                # 处理工具链
                echo -e "  ${BOLD}${YELLOW_COLOR}🔄 处理工具链...${RESET}"
                if tar -I "zstd" -xf toolchain.tar.zst; then
                    echo -e "    ${GREEN_COLOR}✓${RESET} 工具链解压成功"
                    
                    # 清理和准备
                    rm -f toolchain.tar.zst
                    mkdir -p bin
                    find ./staging_dir/ -name '*' -exec touch {} \; >/dev/null 2>&1
                    find ./tmp/ -name '*' -exec touch {} \; >/dev/null 2>&1
                    echo -e "    ${GREEN_COLOR}✓${RESET} 环境准备完成"
                else
                    echo -e "    ${RED_COLOR}✗${RESET} 工具链解压失败"
                    return 1
                fi
            else
                echo -e "    ${RED_COLOR}✗${RESET} 工具链下载失败"
                return 1
            fi

            echo -e "  ${BOLD}${CYAN_COLOR}────────────────────────────────────────────────────────────${RESET}"
            
            # 编译固件（与普通模式相同的编译步骤）
            echo -e "  ${BOLD}${YELLOW_COLOR}🔨 开始编译固件...${RESET}"
            
            # 更新构建日期
            sed -i "/BUILD_DATE/d" package/base-files/files/usr/lib/os-release
            sed -i "/BUILD_ID/aBUILD_DATE=\"$CURRENT_DATE\"" package/base-files/files/usr/lib/os-release
            echo -e "    ${GREEN_COLOR}✓${RESET} 构建日期: ${CURRENT_DATE}"
            
            echo -e "    ${CYAN_COLOR}▶${RESET} 使用核心: ${cpu_cores}"
            echo -e "    ${CYAN_COLOR}▶${RESET} 编译命令: make -j${cpu_cores} IGNORE_ERRORS=\"n m\""
            echo ""
            
            if make -j$cpu_cores IGNORE_ERRORS="n m"; then
                echo -e "  ${BOLD}${GREEN_COLOR}✅ 加速编译完成${RESET}"
            else
                echo -e "  ${BOLD}${RED_COLOR}❌ 编译失败${RESET}"
                return 1
            fi
            ;;
    esac

    echo ""
    echo -e "${BOLD}${BLUE_COLOR}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}║                     🎉 编译阶段完成 🎉                       ║${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    # 显示完成信息
    echo -e "  ${BOLD}${GREEN_COLOR}✅ 编译任务执行完毕${RESET}"
    echo -e "  ${BOLD}${CYAN_COLOR}├─ 输出目录: ${GREEN_COLOR}$(pwd)/bin${RESET}"
    echo -e "  ${BOLD}${CYAN_COLOR}├─ 编译模式: ${GREEN_COLOR}${build_mode}${RESET}"
    echo -e "  ${BOLD}${CYAN_COLOR}├─ 架构平台: ${GREEN_COLOR}${platform}${RESET}"
    echo -e "  ${BOLD}${CYAN_COLOR}└─ 完成时间: ${GREEN_COLOR}$(date '+%Y-%m-%d %H:%M:%S')${RESET}"
    echo ""
}

### 私有源打包 ###
private_source_packaging() {
    echo -e "\n"
    echo -e "${BOLD}${MAGENTA_COLOR}╭──────────────────────────────────────────────╮${RESET}"
    echo -e "${BOLD}${MAGENTA_COLOR}│${RESET}   📦 ${CYAN_COLOR}私有源打包阶段${RESET}                               ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "${BOLD}${MAGENTA_COLOR}╰──────────────────────────────────────────────╯${RESET}"
    echo

    echo -e "${YELLOW_COLOR}⟳ 正在获取内核版本信息...${RESET}"
    get_kernel_version=$(cat include/kernel-6.12)
    kmod_hash=$(echo -e "$get_kernel_version" | awk -F'HASH-' '{print $2}' | awk '{print $1}' | tail -1 | md5sum | awk '{print $1}')
    kmodpkg_name=$(echo $(echo -e "$get_kernel_version" | awk -F'HASH-' '{print $2}' | awk '{print $1}')~$(echo $kmod_hash)-r1)

    echo -e "${GREEN_COLOR}✔ 生成包名：${RESET}${BOLD}${CYAN_COLOR}${kmodpkg_name}${RESET}"
    echo

    if [ "$platform" = "x86_64" ]; then
        echo -e "${BLUE_COLOR}→ 检测到平台：x86_64${RESET}"
        cp -a bin/targets/x86/*/packages "$kmodpkg_name"
        rm -f "$kmodpkg_name"/Packages*
        cp -a bin/packages/x86_64/base/rtl88*-firmware*.ipk "$kmodpkg_name"/ 2>/dev/null || true
    elif [ "$platform" = "rockchip" ]; then
        echo -e "${BLUE_COLOR}→ 检测到平台：rockchip${RESET}"
        cp -a bin/targets/rockchip/armv8*/packages "$kmodpkg_name"
        rm -f "$kmodpkg_name"/Packages*
        cp -a bin/packages/aarch64_generic/base/rtl88*-firmware*.ipk "$kmodpkg_name"/ 2>/dev/null || true
    fi

    echo
    echo -e "${YELLOW_COLOR}🔏 正在执行签名操作...${RESET}"
    bash kmod-sign "$kmodpkg_name"

    echo -e "${YELLOW_COLOR}📦 正在打包文件...${RESET}"
    tar zcf "aarch64-${kmodpkg_name}.tar.gz" "$kmodpkg_name"
    rm -rf "$kmodpkg_name"

    echo
    echo -e "${GREEN_COLOR}🎉 打包完成！${RESET}"
    echo -e "生成文件：${BOLD}${CYAN_COLOR}aarch64-${kmodpkg_name}.tar.gz${RESET}"
    echo -e "${DIM}──────────────────────────────────────────────${RESET}\n"
}

# 主执行逻辑
main() {
    show_usage
    validate_password
    show_banner
    setup_build_environment
    setup_curl_progress
    prepare_source_code
    compile_source_code
    if [[ "$build_mode_input" != "toolchain-only" ]]; then
        private_source_packaging
    fi
}

main "$@"
