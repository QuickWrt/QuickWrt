#!/bin/bash -e

# 定义全局颜色
export RED_COLOR='\e[1;31m'
export GREEN_COLOR='\e[1;32m'
export YELLOW_COLOR='\e[1;33m'
export BLUE_COLOR='\e[1;34m'
export MAGENTA_COLOR='\e[1;35m'
export CYAN_COLOR='\e[1;36m'
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

validate_password() {
    clear
    local attempts=0
    local max_attempts=3
    
    while [ $attempts -lt $max_attempts ]; do
        echo -e "${BOLD}${MAGENTA}════════════════════════════════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}                   🔐 ZeroWrt 私有系统访问验证 🔐${RESET}"
        echo -e "${BOLD}${MAGENTA}════════════════════════════════════════════════════════════════${RESET}"
        echo ""
        echo -e "${BOLD}${YELLOW}⚠️  此系统为授权用户专用，请验证您的身份${RESET}"
        echo ""
        echo -e "${BOLD}${GOLD}请输入访问密码：${RESET}"
        echo -n -e "${BOLD}${GREEN}➤ ${RESET}"
        read -s user_input
        echo ""
        
        local reversed_input=$(echo "$user_input" | rev)
        local encoded_reversed_input=$(echo -n "$reversed_input" | base64)
        encoded_reversed_input=$(echo -n "$encoded_reversed_input" | tr -d '\n')
        
        if [ "$encoded_reversed_input" = "$PASSWORD" ]; then
            echo ""
            echo -e "${BOLD}${GREEN}✅ 身份验证成功！正在加载系统...${RESET}"
            echo -e "${BOLD}${MAGENTA}════════════════════════════════════════════════════════════════${RESET}"
            sleep 1
            return 0
        else
            attempts=$((attempts + 1))
            remaining=$((max_attempts - attempts))
            echo ""
            echo -e "${BOLD}${RED}❌ 密码错误！剩余尝试次数: ${remaining}${RESET}"
            
            if [ $attempts -eq $max_attempts ]; then
                echo ""
                echo -e "${BOLD}${RED}🚫 验证失败次数过多，系统退出！${RESET}"
                echo -e "${BOLD}${YELLOW}📞 请联系系统管理员获取访问权限${RESET}"
                echo -e "${BOLD}${MAGENTA}════════════════════════════════════════════════════════════════${RESET}"
                exit 1
            fi
            sleep 2
            clear
        fi
    done
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

validate_password
show_banner
