#!/bin/bash

# 修改默认 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# --- 将 Argon 设为默认主题 ---
# 1. 修改 luci-light Makefile (针对新版 OpenWrt)
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile

# 2. (可选) 同时修改其他几个 Makefile 以确保兼容性
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-nginx/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-ssl-nginx/Makefile
# --- 设置完毕 ---

# 运行 defconfig 使配置生效
make defconfig
