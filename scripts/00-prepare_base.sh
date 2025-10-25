#!/bin/bash -e

### 基础部分 ###
# 使用 O2 级别的优化
sed -i 's/Os/O2/g' include/target.mk

# kenrel Vermagic
sed -ie 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
grep HASH include/kernel-6.6 | awk -F'HASH-' '{print $2}' | awk '{print $1}' | md5sum | awk '{print $1}' > .vermagic

# 内核版本设置
cp -rf ../OpenBox/kernel-6.6/kernel/0001-linux-module-video.patch ./package/0001-linux-module-video.patch
git apply package/0001-linux-module-video.patch
rm -rf package/0001-linux-module-video.patch

# 修复 Rust 报错
sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile

### FW4 ###
cp -rf ../OpenBox/firewall4/Makefile ./package/network/config/firewall4/Makefile
sed -i 's|$(PROJECT_GIT)/project|https://github.com/openwrt|g' package/network/config/firewall4/Makefile
mkdir -p package/network/config/firewall4/patches
patch -p1 < ../OpenBox/firewall4/100-openwrt-firewall4-add-custom-nft-command-support.patch
cp -rf ../OpenBox/firewall4/firewall4_patches package/network/config/firewall4/patches/

# libnftnl
mkdir -p package/libs/libnftnl/patches
cp -f ../OpenBox/firewall4/libnftnl/*.patch ./package/libs/libnftnl/patches/

# nftables
mkdir -p package/network/utils/nftables/patches
cp -f ../OpenBox/firewall4/nftables/*.patch ./package/network/utils/nftables/patches/

# kernel patch
cp -f ../OpenBox/kernel-6.6/btf/*.patch ./target/linux/generic/hack-6.6/
cp -f ../OpenBox/kernel-6.6/arm/*.patch ./target/linux/generic/hack-6.6/
cp -f ../OpenBox/kernel-6.6/net/*.patch ./target/linux/generic/hack-6.6/

# FullCone module
git clone https://git.cooluc.com/sbwml/nft-fullcone package/new/nft-fullcone

# IPv6 NAT
git clone https://github.com/sbwml/packages_new_nat6 package/new/nat6

# Natflow
git clone https://github.com/sbwml/package_new_natflow package/new/natflow

# Shortcut Forwarding Engine
git clone https://git.cooluc.com/sbwml/shortcut-fe package/new/shortcut-fe

# BBRv3
cp -rf ../OpenBox/kernel-6.6/bbr3/* ./target/linux/generic/backport-6.6/

# LRNG
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

# 6.17_ppp_performance
wget https://github.com/torvalds/linux/commit/95d0d094ba26432ec467e2260f4bf553053f1f8f.patch -O target/linux/generic/pending-6.6/999-1-95d0d09.patch
wget https://github.com/torvalds/linux/commit/1a3e9b7a6b09e8ab3d2af019e4a392622685855e.patch -O target/linux/generic/pending-6.6/999-2-1a3e9b7.patch
wget https://github.com/torvalds/linux/commit/7eebd219feda99df8292a97faff895a5da8159d6.patch -O target/linux/generic/pending-6.6/999-3-7eebd21.patch

# ppp_fix
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/9d852a05bd50b1c332301eecbcac1fa71be637d6.patch | patch -p1

### Other Kernel Hack 部分 ###
# make olddefconfig
patch -p1 < ../OpenBox/kernel-6.6/kernel/0003-include-kernel-defaults.mk.patch
# igc-fix
cp -rf ../OpenBox/kernel-6.6/igc-fix/* ./target/linux/x86/patches-6.6/
# btf
cp -rf ../OpenBox/kernel-6.6/btf/* ./target/linux/generic/hack-6.6/

### 个性化修改 ###
sed -i "s/192.168.1.1/10.0.0.1/g" package/base-files/files/bin/config_generate

sed -i 's/OpenWrt/ZeroWrt/' package/base-files/files/bin/config_generate

cp -rf ../OpenBox/doc/base-files/etc/banner ./package/base-files/files/etc/banner

# luci-mod extra
pushd feeds/luci
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0002-luci-app-firewall-add-shortcut-fe-option.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0003-luci-app-firewall-add-ipv6-nat-option.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0004-luci-add-firewall-add-custom-nft-rule-support.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0005-luci-app-firewall-add-natflow-offload-support.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0006-luci-app-firewall-enable-hardware-offload-only-on-de.patch
patch -p1 <../../../OpenBox/firewall4/luci-24.10/0007-luci-app-firewall-add-fullcone6-option-for-nftables-.patch
popd

# luci-mod extra
pushd feeds/luci
patch -p1 <../../../OpenBox/luci/0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch
patch -p1 <../../../OpenBox/luci/0002-luci-mod-status-displays-actual-process-memory-usage.patch
patch -p1 <../../../OpenBox/luci/0003-luci-mod-status-storage-index-applicable-only-to-val.patch
patch -p1 <../../../OpenBox/luci/0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch
patch -p1 <../../../OpenBox/luci/0005-luci-mod-system-add-refresh-interval-setting.patch
patch -p1 <../../../OpenBox/luci/0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch
patch -p1 <../../../OpenBox/luci/0007-luci-mod-system-add-ucitrack-luci-mod-system-zram.js.patch
popd

# opkg
mkdir -p package/system/opkg/patches
cp -rf ../OpenBox/opkg/* ./package/system/opkg/patches/

# TTYD
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# profile
sed -i 's#\\u@\\h:\\w\\\$#\\[\\e[32;1m\\][\\u@\\h\\[\\e[0m\\] \\[\\033[01;34m\\]\\W\\[\\033[00m\\]\\[\\e[32;1m\\]]\\[\\e[0m\\]\\\$#g' package/base-files/files/etc/profile
sed -ri 's/(export PATH=")[^"]*/\1%PATH%:\/opt\/bin:\/opt\/sbin:\/opt\/usr\/bin:\/opt\/usr\/sbin/' package/base-files/files/etc/profile
sed -i '/ENV/i\export TERM=xterm-color' package/base-files/files/etc/profile

# bash
sed -i 's#ash#bash#g' package/base-files/files/etc/passwd
sed -i '\#export ENV=/etc/shinit#a export HISTCONTROL=ignoredups' package/base-files/files/etc/profile

# files
mkdir files
cp -rf ../OpenBox/files/* ./files/
chmod -R +x files

# NTP
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/time1.cloud.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time2.cloud.tencent.com/g' package/base-files/files/bin/config_generate

# luci-theme-bootstrap
sed -i 's/font-size: 13px/font-size: 14px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css
sed -i 's/9.75px/10.75px/g' feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/cascade.css

# 版本设置
cat << 'EOF' >> feeds/luci/modules/luci-mod-status/ucode/template/admin_status/index.ut
<script>
function addLinks() {
    var section = document.querySelector(".cbi-section");
    if (section) {
        var links = document.createElement('div');
        links.innerHTML = '<div class="table"><div class="tr"><div class="td left" width="33%"><a href="https://qm.qq.com/q/JbBVnkjzKa" target="_blank">QQ交流群</a></div><div class="td left" width="33%"><a href="https://t.me/kejizero" target="_blank">TG交流群</a></div><div class="td left"><a href="https://openwrt.kejizero.online" target="_blank">固件地址</a></div></div></div>';
        section.appendChild(links);
    } else {
        setTimeout(addLinks, 100); // 继续等待 `.cbi-section` 加载
    }
}

document.addEventListener("DOMContentLoaded", addLinks);
</script>
EOF

# 加入作者信息
sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='ZeroWrt-$(date +%Y%m%d)'/g"  package/base-files/files/etc/openwrt_release
sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' By OPPEN321'/g" package/base-files/files/etc/openwrt_release
sed -i "s|^OPENWRT_RELEASE=\".*\"|OPENWRT_RELEASE=\"ZeroWrt 标准版 @R$(date +%Y%m%d) BY OPPEN321\"|" package/base-files/files/usr/lib/os-release
