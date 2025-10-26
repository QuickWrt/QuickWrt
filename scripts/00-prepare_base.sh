#!/bin/bash -e

### Core Settings ###
# Enable compiler optimizations at O2 level for enhanced performance and efficiency
sed -i 's/Os/O2/g' include/target.mk

# Integrates UPX toolchain support for executable compression.
patch -p1 < ../OpenBox/generic-24.10/0001-tools-add-upx-tools.patch

# Enables firmware-wide UPX compression for reduced binary footprint.
patch -p1 < ../OpenBox/generic-24.10/0002-rootfs-add-upx-compression-support.patch

# Grants persistent read/write access to UCI config files.
patch -p1 < ../OpenBox/generic-24.10/0003-rootfs-add-r-w-permissions-for-UCI-configuration-fil.patch

# Facilitates local kmod installation from custom sources.
patch -p1 < ../OpenBox/generic-24.10/0004-rootfs-Add-support-for-local-kmod-installation-sourc.patch

# Kernel Vermagic Handling（Extracts the HASH from kernel metadata, computes its MD5 checksum,and stores it in the .vermagic file to ensure build consistency and module compatibility）
sed -ie 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
grep HASH include/kernel-6.6 | awk -F'HASH-' '{print $2}' | awk '{print $1}' | md5sum | awk '{print $1}' > .vermagic

# Kernel Version Configuration: apply a specific video module patch to the kernel source to enhance multimedia support
cp -rf ../OpenBox/kernel-6.6/kernel/0001-linux-module-video.patch ./package/0001-linux-module-video.patch
git apply package/0001-linux-module-video.patch
rm -rf package/0001-linux-module-video.patch

# Rust Build Fix: disable CI LLVM to prevent compilation errors
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile

### FW4 ###
# Integrate custom Firewall4 with extended nft command support
cp -rf ../OpenBox/firewall4/Makefile ./package/network/config/firewall4/Makefile
sed -i 's|$(PROJECT_GIT)/project|https://github.com/openwrt|g' package/network/config/firewall4/Makefile
mkdir -p package/network/config/firewall4/patches
patch -p1 < ../OpenBox/firewall4/100-openwrt-firewall4-add-custom-nft-command-support.patch
cp -rf ../OpenBox/firewall4/firewall4_patches package/network/config/firewall4/patches/

# libnftnl patches
# Apply required patches to libnftnl library to enhance nftables functionality
mkdir -p package/libs/libnftnl/patches
cp -f ../OpenBox/firewall4/libnftnl/*.patch ./package/libs/libnftnl/patches/

# nftables patches
# Integrate customized nftables patches for improved firewall capabilities
mkdir -p package/network/utils/nftables/patches
cp -f ../OpenBox/firewall4/nftables/*.patch ./package/network/utils/nftables/patches/

# Kernel patches
# Apply architecture-specific and network kernel patches for optimized performance
cp -f ../OpenBox/kernel-6.6/btf/*.patch ./target/linux/generic/hack-6.6/
cp -f ../OpenBox/kernel-6.6/arm/*.patch ./target/linux/generic/hack-6.6/
cp -f ../OpenBox/kernel-6.6/net/*.patch ./target/linux/generic/hack-6.6/

# FullCone NAT module
# Clone the FullCone NAT module for enhanced network address translation
git clone https://git.cooluc.com/sbwml/nft-fullcone package/new/nft-fullcone

# IPv6 NAT support
# Integrate IPv6 NAT packages for dual-stack environments
git clone https://github.com/sbwml/packages_new_nat6 package/new/nat6

# Natflow support
# Integrate Natflow for dynamic network flow management
git clone https://github.com/sbwml/package_new_natflow package/new/natflow

# Shortcut Forwarding Engine
# Include Shortcut Forwarding Engine to accelerate packet forwarding
git clone https://git.cooluc.com/sbwml/shortcut-fe package/new/shortcut-fe

# BBRv3 congestion control
# Apply BBRv3 kernel backports for improved network throughput and latency
cp -rf ../OpenBox/kernel-6.6/bbr3/* ./target/linux/generic/backport-6.6/

# LRNG (Linux Random Number Generator)
# Apply LRNG kernel patches and enable secure random number generation features
cp -rf ../OpenBox/kernel-6.6/lrng/* ./target/linux/generic/hack-6.6/
echo '
# CONFIG_RANDOM_DEFAULT_IMPL is not set
CONFIG_LRNG=y
CONFIG_LRNG_DEV_IF=y
# CONFIG_LRNG_IRQ is not set
CONFIG_LRNG_JENT=y
CONFIG_LRNG_CPU=y
# CONFIG_LRNG_SCHED is not set
CONFIG_LRNG_SELFTEST=y
# CONFIG_LRNG_SELFTEST_PANIC is not set
' >>./target/linux/generic/config-6.6

# Kernel PPP performance patches
wget https://github.com/torvalds/linux/commit/95d0d094ba26432ec467e2260f4bf553053f1f8f.patch -O target/linux/generic/pending-6.6/999-1-95d0d09.patch
wget https://github.com/torvalds/linux/commit/1a3e9b7a6b09e8ab3d2af019e4a392622685855e.patch -O target/linux/generic/pending-6.6/999-2-1a3e9b7.patch
wget https://github.com/torvalds/linux/commit/7eebd219feda99df8292a97faff895a5da8159d6.patch -O target/linux/generic/pending-6.6/999-3-7eebd21.patch

# PPP fix applied directly from ImmortalWrt upstream commit
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/9d852a05bd50b1c332301eecbcac1fa71be637d6.patch | patch -p1

### Other Kernel Hacks ###
# Apply the kernel default configuration for enhanced stability and consistency
patch -p1 < ../OpenBox/kernel-6.6/kernel/0003-include-kernel-defaults.mk.patch

# Apply IGC network driver fixes to ensure reliable Ethernet performance
cp -rf ../OpenBox/kernel-6.6/igc-fix/* ./target/linux/x86/patches-6.6/

# Apply BTF (BPF Type Format) enhancements to improve kernel introspection and debugging
cp -rf ../OpenBox/kernel-6.6/btf/* ./target/linux/generic/hack-6.6/

### Personalized modifications ###
# Update LAN gateway, branding, and banner to custom ZeroWrt settings
sed -i "s/192.168.1.1/10.0.0.1/g" package/base-files/files/bin/config_generate

sed -i 's/OpenWrt/ZeroWrt/' package/base-files/files/bin/config_generate

cp -rf ../OpenBox/doc/base-files/etc/banner ./package/base-files/files/etc/banner

# Luci modules enhancements for Firewall, NAT, and FullCone support
pushd feeds/luci
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0002-luci-app-firewall-add-shortcut-fe-option.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0003-luci-app-firewall-add-ipv6-nat-option.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0004-luci-add-firewall-add-custom-nft-rule-support.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0005-luci-app-firewall-add-natflow-offload-support.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0006-luci-app-firewall-enable-hardware-offload-only-on-de.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0007-luci-app-firewall-add-fullcone6-option-for-nftables-.patch
popd

# Additional Luci enhancements for system status, modal dialogs, and storage display optimizations
pushd feeds/luci
patch -p1 <../../../OpenBox/luci/0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch
patch -p1 <../../../OpenBox/luci/0002-luci-mod-status-displays-actual-process-memory-usage.patch
patch -p1 <../../../OpenBox/luci/0003-luci-mod-status-storage-index-applicable-only-to-val.patch
patch -p1 <../../../OpenBox/luci/0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch
patch -p1 <../../../OpenBox/luci/0005-luci-mod-system-add-refresh-interval-setting.patch
patch -p1 <../../../OpenBox/luci/0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch
patch -p1 <../../../OpenBox/luci/0007-luci-mod-system-add-ucitrack-luci-mod-system-zram.js.patch
popd

# OPKG patches integration
mkdir -p package/system/opkg/patches
cp -rf ../OpenBox/opkg/* ./package/system/opkg/patches/

# TTYD menu and logging enhancements
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# Shell profile and PATH customization for enhanced UX
sed -i 's#\\u@\\h:\\w\\\$#\\[\\e[32;1m\\][\\u@\\h\\[\\e[0m\\] \\[\\033[01;34m\\]\\W\\[\\033[00m\\]\\[\\e[32;1m\\]]\\[\\e[0m\\]\\\$#g' package/base-files/files/etc/profile
sed -ri 's/(export PATH=")[^"]*/\1%PATH%:\/opt\/bin:\/opt\/sbin:\/opt\/usr\/bin:\/opt\/usr\/sbin/' package/base-files/files/etc/profile
sed -i '/ENV/i\export TERM=xterm-color' package/base-files/files/etc/profile

# Default shell set to bash with HISTCONTROL optimization
sed -i 's#ash#bash#g' package/base-files/files/etc/passwd
sed -i '\#export ENV=/etc/shinit#a export HISTCONTROL=ignoredups' package/base-files/files/etc/profile

# Copy custom files with execution permissions
mkdir files
cp -rf ../OpenBox/files/* ./files/
chmod -R +x files

# NTP server customization for faster and more reliable time sync
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/time1.cloud.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time2.cloud.tencent.com/g' package/base-files/files/bin/config_generate

# Luci-theme-bootstrap font-size enhancement for better readability
sed -i 's/font-size: 13px/font-size: 14px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css
sed -i 's/9.75px/10.75px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css

# Status page enhancement: add social and firmware links
cat << 'EOF' >> feeds/luci/modules/luci-mod-status/ucode/template/admin_status/index.ut
<script>
function addLinks() {
    var section = document.querySelector(".cbi-section");
    if (section) {
        // 创建表格容器
        var table = document.createElement('div');
        table.className = 'table';
        
        // 创建行
        var row = document.createElement('div');
        row.className = 'tr';
        
        // 左列：帮助与反馈
        var leftCell = document.createElement('div');
        leftCell.className = 'td left';
        leftCell.style.width = '33%';
        leftCell.textContent = '帮助与反馈';
        
        // 右列：三个按钮
        var rightCell = document.createElement('div');
        rightCell.className = 'td left';
        
        // 创建QQ交流群按钮
        var qqLink = document.createElement('a');
        qqLink.href = 'https://qm.qq.com/q/JbBVnkjzKa';
        qqLink.target = '_blank';
        qqLink.className = 'cbi-button';
        qqLink.style.marginRight = '10px';
        qqLink.textContent = 'QQ交流群';
        
        // 创建TG交流群按钮
        var tgLink = document.createElement('a');
        tgLink.href = 'https://t.me/kejizero';
        tgLink.target = '_blank';
        tgLink.className = 'cbi-button';
        tgLink.style.marginRight = '10px';
        tgLink.textContent = 'TG交流群';
        
        // 创建固件地址按钮
        var firmwareLink = document.createElement('a');
        firmwareLink.href = 'https://openwrt.kejizero.online';
        firmwareLink.target = '_blank';
        firmwareLink.className = 'cbi-button';
        firmwareLink.textContent = '固件地址';
        
        // 组装元素
        rightCell.appendChild(qqLink);
        rightCell.appendChild(tgLink);
        rightCell.appendChild(firmwareLink);
        
        row.appendChild(leftCell);
        row.appendChild(rightCell);
        table.appendChild(row);
        section.appendChild(table);
    } else {
        setTimeout(addLinks, 100);
    }
}

document.addEventListener("DOMContentLoaded", addLinks);
</script>
EOF

# Custom firmware version and author metadata
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='ZeroWrt-$(date +%Y%m%d)'/g"  package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' By OPPEN321'/g" package/base-files/files/etc/openwrt_release
sed -i "s|^OPENWRT_RELEASE=\".*\"|OPENWRT_RELEASE=\"ZeroWrt 标准版 @R$(date +%Y%m%d) BY OPPEN321\"|" package/base-files/files/usr/lib/os-release
