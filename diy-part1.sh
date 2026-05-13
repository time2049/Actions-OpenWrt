#!/bin/bash

# 添加 PassWall 源（xiaorouji 维护，通常适配最新版）
echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall.git' >> feeds.conf.default

# 添加 OpenClash 源
echo 'src-git openclash https://github.com/vernesong/OpenClash.git' >> feeds.conf.default

# 添加 Argon 主题源（确保最新，但官方 feeds 中可能已有）
echo 'src-git argon https://github.com/jerrykuku/luci-theme-argon.git' >> feeds.conf.default
echo 'src-git argonconfig https://github.com/jerrykuku/luci-app-argon-config.git' >> feeds.conf.default
