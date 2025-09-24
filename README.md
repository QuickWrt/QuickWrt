QuickWrt - OpenWRT 快速构建系统
https://img.shields.io/badge/OpenWRT-v24.10-blue.svg
https://img.shields.io/badge/License-GPLv3-green.svg
https://img.shields.io/badge/Platform-Linux-x86__64%2520%257C%2520Rockchip-orange.svg

一个高度优化的 OpenWRT 自动化构建系统，支持快速编译和定制化固件生成。

🌟 特性
快速构建: 支持预编译工具链加速，大幅缩短编译时间

多架构支持: 支持 x86_64 和 Rockchip 架构

智能缓存: 工具链缓存机制，避免重复编译

自动化流程: 一键式构建，简化复杂配置过程

定制化配置: 集成 ImmortalWRT 组件，增强设备兼容性

安全可靠: 严格的错误处理和验证机制

📋 系统要求
硬件要求
内存: 至少 8GB RAM（推荐 16GB+）

存储: 至少 100GB 可用空间

CPU: 多核心处理器（核心数越多，编译越快）

软件要求
操作系统: Ubuntu 20.04+ / Debian 11+ / CentOS 8+

依赖包: 确保安装以下软件包：

bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y build-essential clang flex g++ gawk gcc-multilib gettext \
git libncurses5-dev libssl-dev python3 python3-distutils zlib1g-dev zstd

# CentOS/RHEL
sudo yum install -y epel-release
sudo yum groupinstall -y "Development Tools"
sudo yum install -y clang flex gcc-c++ gawk gettext git ncurses-devel \
openssl-devel python3 python3-distutils zlib-devel zstd
🚀 快速开始
1. 克隆仓库
bash
git clone https://github.com/BlueStack-Sky/QuickWrt.git
cd QuickWrt
2. 运行构建脚本
bash
# 基本用法
bash build.sh <version> <architecture> [build_mode]

# 示例：构建 x86_64 架构的 v24 版本，使用加速模式
bash build.sh v24 x86_64 accelerated

# 示例：构建 Rockchip 架构的 v24 版本，使用普通模式
bash build.sh v24 rockchip normal

# 示例：仅编译工具链（用于缓存）
bash build.sh v24 x86_64 toolchain-only
3. 参数说明
参数	必选	说明	可选值
version	✅	OpenWRT 版本	v24 (当前支持)
architecture	✅	目标架构	x86_64, rockchip
build_mode	❌	编译模式	accelerated, normal, toolchain-only
编译模式说明
accelerated: 下载预编译工具链，编译速度最快（推荐）

normal: 完整编译所有组件，包括工具链

toolchain-only: 仅编译工具链，用于创建本地缓存

📁 项目结构
text
QuickWrt/
├── build.sh                 # 主构建脚本
├── scripts/                 # 构建子脚本
│   ├── 00-prepare_base.sh
│   ├── 01-prepare_package.sh
│   ├── 02-x86_64_target_only.sh
│   └── 02-rockchip_target_only.sh
├── OpenBox/                 # 定制化配置和软件包
│   ├── Config/
│   │   ├── X86_64.config
│   │   └── Rockchip.config
│   └── key.tar.gz
└── README.md
🔧 架构支持详情
x86_64 架构
目标设备: 标准 x86_64 硬件、虚拟机、软路由

特性: 通用 x86 优化，支持大多数 x86 网卡和硬件

Rockchip 架构
目标设备: Rockchip 系列开发板（RK3568、RK3588 等）

特性: 集成 ImmortalWRT 组件，增强设备兼容性

⚙️ 高级配置
自定义软件包
构建系统会自动集成 OpenBox 仓库中的定制化软件包。要添加自定义软件包：

将软件包放入 OpenBox/package/ 目录

在对应的配置文件中启用相关选项

重新执行构建脚本

网络配置
构建过程中需要访问以下资源：

GitHub (源码仓库)

OpenWRT 官方源

自定义镜像源（用于加速下载）

代理设置（如需要）
如果网络环境需要代理，请设置环境变量：

bash
export http_proxy=http://your-proxy:port
export https_proxy=http://your-proxy:port
🛠️ 故障排除
常见问题
Q: 构建过程中出现权限错误

bash
# 解决方案：确保以正确用户运行
sudo chown -R $USER:$USER .
Q: 内存不足导致编译失败

bash
# 解决方案：增加交换空间或减少编译线程数
export CPU_CORES=$(($(nproc) / 2))  # 使用一半核心数
Q: 网络下载失败

bash
# 解决方案：检查网络连接或使用代理
export CURL_OPTIONS="--retry 3 --retry-delay 5"
日志文件
构建过程中会生成详细的日志：

主要日志输出到终端

详细错误信息可在 openwrt/tmp/ 目录下找到

📊 性能对比
模式	预计时间	磁盘占用	推荐场景
accelerated	30-60分钟	中等	快速部署、日常使用
normal	2-4小时	较大	完全自定义、调试
toolchain-only	1-2小时	大	创建缓存、多设备编译
🤝 贡献指南
我们欢迎各种形式的贡献！请参考以下步骤：

Fork 本仓库

创建特性分支 (git checkout -b feature/AmazingFeature)

提交更改 (git commit -m 'Add some AmazingFeature')

推送到分支 (git push origin feature/AmazingFeature)

开启 Pull Request

代码规范
使用清晰的注释说明复杂逻辑

保持 Bash 脚本的兼容性和可读性

添加适当的错误处理机制

📄 许可证
本项目基于 GPLv3 许可证发布 - 查看 LICENSE 文件了解详情。

🙏 致谢
OpenWRT - 优秀的开源路由器系统

ImmortalWRT - 提供增强的 Rockchip 支持

所有为项目做出贡献的开发者

📞 支持与联系
作者: OPPEN321

博客: www.kejizero.online

问题反馈: GitHub Issues

注意: 本项目仍在积极开发中，API 和功能可能会有变动。建议定期拉取最新版本获取更新和改进。

⭐ 如果这个项目对你有帮助，请给我们一个 Star！
