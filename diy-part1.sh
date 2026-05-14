#!/bin/bash

# 1. 添加 PassWall 源 (使用 openwrt-25.12 分支，与稳定版兼容)
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;openwrt-25.12' >> feeds.conf.default
echo 'src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;openwrt-25.12' >> feeds.conf.default

# 2. 添加 OpenClash 源 (主分支)
echo 'src-git openclash https://github.com/vernesong/OpenClash.git' >> feeds.conf.default

# 3. 添加 Argon 主题源 (主分支)
echo 'src-git argon https://github.com/jerrykuku/luci-theme-argon.git' >> feeds.conf.default

# 4. Argon 配置插件 (与 OpenWrt 25.12 不兼容，暂时禁用)
# echo 'src-git argonconfig https://github.com/jerrykuku/luci-app-argon-config.git' >> feeds.conf.default
