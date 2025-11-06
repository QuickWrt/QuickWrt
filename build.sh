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
export gcc=${gcc_version:-13}
export password="MzE4MzU3M2p6"
export supported_boards="x86_64 rockchip"

# 编译模式
case "$2" in
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
    
    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}开始克隆源代码仓库...${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 📦 仓库: ${CYAN_COLOR}https://github.com/openwrt/openwrt${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🏷️  版本: ${YELLOW_COLOR}v$tag_version${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    
    # 显示克隆进度
    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}正在下载源代码，请稍候...${RESET}"
    
    # 克隆源代码（隐藏所有错误输出）
    if git -c advice.detachedHead=false clone --depth=1 --branch "v$tag_version" --single-branch --quiet https://github.com/openwrt/openwrt && cd openwrt 2>/dev/null; then
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
    sed -i 's#^src-git packages .*#src-git packages https://github.com/openwrt/packages.git;openwrt-24.10#' feeds.conf.default
    sed -i 's#^src-git luci .*#src-git luci https://github.com/openwrt/luci.git;openwrt-24.10#' feeds.conf.default
    sed -i 's#^src-git routing .*#src-git routing https://github.com/openwrt/routing.git;openwrt-24.10#' feeds.conf.default
    sed -i 's#^src-git telephony .*#src-git telephony https://github.com/openwrt/telephony.git;openwrt-24.10#' feeds.conf.default
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
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo -e "${BOLD}${WHITE}                         加载配置文件 [7/7]${RESET}"
    echo -e "${BOLD}${BLUE_COLOR}■ ■ ■ ■ ■ ■ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □ □${RESET}"
    echo ""
    
    echo -e "  ${BOLD}${CYAN_COLOR}⟳${RESET} ${BOLD}加载配置文件...${RESET}"
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    
    # 根据架构下载对应的配置文件
    case "$arch" in
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
            echo -e "  ${BOLD}${MAGENTA_COLOR}├─ ${YELLOW_COLOR}⚠${RESET} ${BOLD}未知架构: $ARCH，使用默认配置${RESET}"
            ;;
    esac
    
    # 应用 GCC 补丁
    echo -e "  ${BOLD}${MAGENTA_COLOR}├─ 🔧 应用 GCC 补丁...${RESET}"
    if curl -s $mirror/openwrt/patch/generic-24.10/202-toolchain-gcc-add-support-for-GCC-15.patch | patch -p1; then
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
    echo -e "  ${BOLD}${MAGENTA_COLOR}│${RESET}"
    echo -e "  ${BOLD}${GREEN_COLOR}✓${RESET} ${BOLD}配置文件加载完成${RESET}"
    echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}架构: ${CYAN_COLOR}${arch}${RESET}"
    echo -e "  ${BOLD}${YELLOW_COLOR}➤${RESET} ${BOLD}GCC 版本: ${CYAN_COLOR}${gcc}${RESET}"
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
