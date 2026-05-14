#!/bin/bash

# 修改默认 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# --- 将 Argon 设为默认主题 ---
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-nginx/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-ssl-nginx/Makefile

# --- 设置 LuCI 默认语言为简体中文 ---
sed -i "s/option lang 'auto'/option lang 'zh-cn'/" feeds/luci/modules/luci-base/root/etc/config/luci

# 运行 defconfig 使配置生效
make defconfig
