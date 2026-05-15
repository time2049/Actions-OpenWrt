#!/bin/bash

# ==================== 1. 添加第三方插件源 ====================

# 添加 PassWall 源
sed -i '$a src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' feeds.conf.default
sed -i '$a src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' feeds.conf.default

# 添加 OpenClash 源
sed -i '$a src-git openclash https://github.com/vernesong/OpenClash.git' feeds.conf.default

# 添加 Argon 主题及其配置
sed -i '$a src-git argon https://github.com/jerrykuku/luci-theme-argon.git' feeds.conf.default
sed -i '$a src-git argonconfig https://github.com/jerrykuku/luci-app-argon-config.git' feeds.conf.default

# ==================== 2. 预处理：解决源码冲突 ====================

# 针对 shadowsocksr-libev 编译失败的问题：提前清理缓存路径
rm -rf package/feeds/passwall_packages/shadowsocksr-libev
rm -rf package/feeds/passwall_packages/v2ray-geodata
