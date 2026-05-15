#!/bin/bash

# ==================== 1. 添加第三方插件源 ====================

# 添加 PassWall 源 (包含依赖和插件)
sed -i '$a src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' feeds.conf.default
sed -i '$a src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' feeds.conf.default

# 添加 OpenClash 源
sed -i '$a src-git openclash https://github.com/vernesong/OpenClash.git' feeds.conf.default

# 添加 Argon 主题及其配置 (小z, 这比默认的 bootstrap 好看多了)
sed -i '$a src-git argon https://github.com/jerrykuku/luci-theme-argon.git' feeds.conf.default
sed -i '$a src-git argonconfig https://github.com/jerrykuku/luci-app-argon-config.git' feeds.conf.default

# ==================== 2. 预处理：解决源码冲突 ====================

# 这一步非常重要，防止 PassWall 和官方源的包名冲突导致编译中断
rm -rf package/feeds/passwall_packages/shadowsocksr-libev
rm -rf package/feeds/passwall_packages/v2ray-geodata
rm -rf package/feeds/passwall_packages/v2ray-core

# ==================== 3. 强制注入核心功能 ====================

# 1. 强制默认中文：修改默认语言为简体中文
# 这样你刷机后不用去执行那个总是报错的 apk add 命令，进来就是中文
sed -i 's/LUCI_LANGS.zh-cn=n/LUCI_LANGS.zh-cn=y/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 2. 强制默认主题为 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 3. 预设 UPnP 服务
# 确保 luci-app-upnp 在编译菜单中可见并被索引
./scripts/feeds update -a && ./scripts/feeds install -a
