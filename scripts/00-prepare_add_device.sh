#!/bin/bash -e

# 集中同步uboot&内核补丁
rsync -av ../OpenBox/device/rockchip/uboot-rockchip/ ./package/boot/uboot-rockchip/
rsync -av ../OpenBox/device/rockchip/patches-6.6/ ./target/linux/rockchip/patches-6.6/

# 多网口设备需定义network
cp -f ../OpenBox/device/rockchip/02_network ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network

# ================================================================
# 移植RK3399示例(针对官方完全不支持的设备。采用补丁集中同步)
# ================================================================
# 增加tvi3315a设备
echo -e "\\ndefine Device/tvi_tvi3315a
  DEVICE_VENDOR := Tvi
  DEVICE_MODEL := TVI3315A
  SOC := rk3399
  UBOOT_DEVICE_NAME := tvi3315a-rk3399
  BOOT_FLOW := pine64-bin
endef
TARGET_DEVICES += tvi_tvi3315a" >> target/linux/rockchip/image/armv8.mk

# ================================================================
# 移植RK3566示例(针对官方内核支持，但固件不支持的设备。采用文件替换方式)
# ================================================================
# 增加station-m2设备
echo -e "\\ndefine Device/firefly_station-m2
  DEVICE_VENDOR := Firefly
  DEVICE_MODEL := Station M2 / RK3566 ROC PC
  SOC := rk3566
  DEVICE_DTS := rockchip/rk3566-roc-pc
  SUPPORTED_DEVICES += firefly,station-m2 firefly,rk3566-roc-pc
  UBOOT_DEVICE_NAME := station-m2-rk3566
  BOOT_FLOW := pine64-img
  DEVICE_PACKAGES := kmod-nvme kmod-scsi-core
endef
TARGET_DEVICES += firefly_station-m2" >> target/linux/rockchip/image/armv8.mk

# 复制dts至package/boot/uboot-rockchip&files/arch/arm64/boot/dts/rockchip
cp -f ../OpenBox/device/rockchip/dts/rk3568/rk3566-roc-pc.dts ./package/boot/uboot-rockchip/src/arch/arm/dts/
cp -f ../OpenBox/device/rockchip/dts/rk3568/rk3566-roc-pc.dts ./target/linux/rockchip/files/arch/arm64/boot/dts/rockchip/
