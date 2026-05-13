#!/bin/bash

# 修改默认管理 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 强制分区大小（确保 .config 中已设置，但为防被覆盖）
sed -i 's/CONFIG_TARGET_KERNEL_PARTSIZE=.*/CONFIG_TARGET_KERNEL_PARTSIZE=256/' .config
sed -i 's/CONFIG_TARGET_ROOTFS_PARTSIZE=.*/CONFIG_TARGET_ROOTFS_PARTSIZE=2048/' .config

# 确保 OpenClash 和 PassWall 已选中（如果 .config 没有，则追加）
for pkg in luci-app-openclash luci-app-passwall; do
    if ! grep -q "CONFIG_PACKAGE_${pkg}=y" .config; then
        echo "CONFIG_PACKAGE_${pkg}=y" >> .config
    fi
done

# 运行 defconfig 使配置生效
make defconfig
