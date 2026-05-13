#!/bin/bash

# 修改默认 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 写入完整 .config
cat > .config <<'EOF'
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_x86_64_DEVICE_generic=y
CONFIG_TARGET_KERNEL_PARTSIZE=256
CONFIG_TARGET_ROOTFS_PARTSIZE=2048
CONFIG_TARGET_ROOTFS_EXT4FS=y
CONFIG_GRUB_EFI_IMAGES=y
CONFIG_GRUB_TIMEOUT="3"

# 基础系统组件
CONFIG_PACKAGE_busybox=y
CONFIG_PACKAGE_dropbear=y
CONFIG_PACKAGE_firewall=y
CONFIG_PACKAGE_dnsmasq-full=y
CONFIG_PACKAGE_odhcp6c=y
CONFIG_PACKAGE_odhcpd-ipv6only=n
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-proto-ppp=y

# 常用网卡驱动（保证网络连通）
CONFIG_PACKAGE_kmod-e1000e=y
CONFIG_PACKAGE_kmod-igb=y
CONFIG_PACKAGE_kmod-r8169=y
CONFIG_PACKAGE_kmod-vmxnet3=y
CONFIG_PACKAGE_kmod-virtio-net=y

# 存储驱动
CONFIG_PACKAGE_kmod-ata-ahci=y
CONFIG_PACKAGE_kmod-ata-core=y
CONFIG_PACKAGE_kmod-scsi-core=y
CONFIG_PACKAGE_kmod-usb-storage=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb3=y
CONFIG_PACKAGE_kmod-nvme=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-squashfs=y
CONFIG_PACKAGE_kmod-fs-vfat=y

# 主题 Argon + 管理
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y

# UPnP
CONFIG_PACKAGE_miniupnpd=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-i18n-upnp-zh-cn=y

# OpenClash 和 PassWall（需配合 diy-part1.sh 的 feeds）
CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-passwall=y
CONFIG_PACKAGE_luci-i18n-passwall-zh-cn=y
# PassWall 常用组件
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Client=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_Libev_Server=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Trojan=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray=y
CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Xray=y

# 编译优化
CONFIG_DEVEL=y
CONFIG_CCACHE=y
EOF

# 运行 defconfig 使配置生效
make defconfig
