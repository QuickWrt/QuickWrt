#!/bin/bash -e
export RED_COLOR='\e[1;31m'
export GREEN_COLOR='\e[1;32m'
export YELLOW_COLOR='\e[1;33m'
export BLUE_COLOR='\e[1;34m'
export PINK_COLOR='\e[1;35m'
export SHAN='\e[1;33;5m'
export RES='\e[0m'

GROUP=
group() {
    endgroup
    echo "::group::  $1"
    GROUP=1
}
endgroup() {
    if [ -n "$GROUP" ]; then
        echo "::endgroup::"
    fi
    GROUP=
}

# 查看
if [ "$(whoami)" != "zhao" ] && [ -z "$git_name" ] && [ -z "$git_password" ]; then
    echo -e "\n${RED_COLOR} Not authorized. Execute the following command to provide authorization information:${RES}\n"
    echo -e "${BLUE_COLOR} export git_name=your_username git_password=your_password${RES}\n"
    exit 1
fi

# 打印头部
echo -e ""
echo -e "${BLUE_COLOR}╔═════════════════════════════════════════════════════════════╗${RES}"
echo -e "${BLUE_COLOR}║${RES}                     OPENWRT BUILD SYSTEM                    ${BLUE_COLOR}║${RES}"
echo -e "${BLUE_COLOR}╚═════════════════════════════════════════════════════════════╝${RES}"
echo -e "${BLUE_COLOR}┌─────────────────────────────────────────────────────────────┐${RES}"
echo -e "${BLUE_COLOR}│${RES}  🛠️   ${YELLOW_COLOR}Developer:${RES} OPPEN321                                    ${BLUE_COLOR}│${RES}"
echo -e "${BLUE_COLOR}│${RES}  🌐  ${YELLOW_COLOR}Blog:${RES} www.kejizero.online                              ${BLUE_COLOR}│${RES}"
echo -e "${BLUE_COLOR}│${RES}  💡  ${YELLOW_COLOR}Philosophy:${RES} Open Source · Customization · Performance  ${BLUE_COLOR}│${RES}"
echo -e "${BLUE_COLOR}└─────────────────────────────────────────────────────────────┘${RES}"
echo -e "${BLUE_COLOR}🔧 ${GREEN_COLOR}Building:${RES} $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${BLUE_COLOR}══════════════════════════════════════════════════════════════${RES}"
echo -e ""

# 检测 Root
if [ "$(id -u)" = "0" ]; then
    export FORCE_UNSAFE_CONFIGURE=1 FORCE=1
fi

# 开始时间
starttime=`date +'%Y-%m-%d %H:%M:%S'`
CURRENT_DATE=$(date +%s)

# 处理器核心数设置
cores=`expr $(nproc --all) + 1`

# 进度条设置
if curl --help | grep progress-bar >/dev/null 2>&1; then
    CURL_BAR="--progress-bar";
fi

SUPPORTED_BOARDS="rockchip x86_64"
if [ -z "$1" ] || ! echo "$SUPPORTED_BOARDS" | grep -qw "$2"; then
    echo -e "\n${RED_COLOR}Building type not specified or unsupported board: '$2'.${RES}\n"
    echo -e "Usage:\n"

    for board in $SUPPORTED_BOARDS; do
        echo -e "$board releases: ${GREEN_COLOR}bash build.sh v24 $board${RES}"
    done
    echo
    exit 1
fi

