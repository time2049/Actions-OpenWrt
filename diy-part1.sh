#!/bin/bash

# 添加 PassWall 源（使用 main 分支以保持最新）
sed -i '$a src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' feeds.conf.default
sed -i '$a src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' feeds.conf.default

# 添加 OpenClash 源
sed -i '$a src-git openclash https://github.com/vernesong/OpenClash.git' feeds.conf.default

# 添加 Argon 主题及其配置插件
sed -i '$a src-git argon https://github.com/jerrykuku/luci-theme-argon.git' feeds.conf.default
sed -i '$a src-git argonconfig https://github.com/jerrykuku/luci-app-argon-config.git' feeds.conf.default

# 【修复】预先清理冲突包，强制 feeds 刷新时重新拉取最新源码
rm -rf package/feeds/passwall_packages/shadowsocksr-libev
rm -rf package/feeds/passwall_packages/v2ray-geodata
