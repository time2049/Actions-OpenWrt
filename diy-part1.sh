#!/bin/bash

# ==================== 1. 添加第三方插件源 ====================

# 添加 PassWall 源（使用 main 分支）
# 建议先删除旧的 feeds 配置中可能存在的重复项，确保来源唯一
sed -i '$a src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' feeds.conf.default
sed -i '$a src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' feeds.conf.default

# 添加 OpenClash 源
sed -i '$a src-git openclash https://github.com/vernesong/OpenClash.git' feeds.conf.default

# 添加 Argon 主题及其配置插件
sed -i '$a src-git argon https://github.com/jerrykuku/luci-theme-argon.git' feeds.conf.default
sed -i '$a src-git argonconfig https://github.com/jerrykuku/luci-app-argon-config.git' feeds.conf.default

# ==================== 2. 针对报错的预处理 ====================

# 针对 shadowsocksr-libev 编译失败的问题：
# 在更新 feeds 前，如果存在旧的 passwall 文件夹则删除，防止 git pull 冲突
rm -rf package/feeds/passwall_packages/shadowsocksr-libev
rm -rf package/feeds/passwall_packages/v2ray-geodata

# 针对 Ruby 导致的编译中断：
# 如果你确定不需要 Ruby 环境，可以在源头屏蔽掉 packages 库中的 ruby，防止它被错误索引
# sed -i '/src-git packages/s/$/;main/' feeds.conf.default # 确保基础包也是最新
