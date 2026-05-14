#!/bin/bash

# 1. 添加 PassWall 源 (使用 openwrt-25.12 分支)
echo 'src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;openwrt-25.12' >> feeds.conf.default
echo 'src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;openwrt-25.12' >> feeds.conf.default

# 2. 添加 OpenClash 源 (主分支通常兼容性最好)
echo 'src-git openclash https://github.com/vernesong/OpenClash.git' >> feeds.conf.default

# 3. 添加 Argon 主题相关源 (官方建议使用 master 分支以支持最新版 LuCI[reference:2])
echo 'src-git argon https://github.com/jerrykuku/luci-theme-argon.git' >> feeds.conf.default
echo 'src-git argonconfig https://github.com/jerrykuku/luci-app-argon-config.git' >> feeds.conf.default
