#!/bin/bash


# =================================================
# diy-part1.sh: 插件源配置脚本
# 针对 OpenWrt SNAPSHOT (Master 26.x) APK 模式优化
# =================================================


# 1. 定义添加源的函数 (防止重复添加导致 Duplicate feed 报错) 
add_feed() {
    local feed_line="$1"
    if ! grep -Fxq "$feed_line" feeds.conf.default; then
        echo "$feed_line" >> feeds.conf.default
        echo "✅ 已添加源: $feed_line"
    fi
}


# 2. 添加 OpenClash 源 
add_feed 'src-git openclash https://github.com/vernesong/OpenClash.git'


# 3. 添加 Argon 主题源 
add_feed 'src-git argon https://github.com/jerrykuku/luci-theme-argon.git'


# 4. 特殊处理：移除 argonconfig 的 feed
# 理由：argonconfig 源经常导致 "index missing" 报错。
# 建议在 diy-part2.sh 中通过 git clone 直接下载到 package 目录。
sed -i '/argonconfig/d' feeds.conf.default 



echo "✅ diy-part1.sh 执行完毕。"
