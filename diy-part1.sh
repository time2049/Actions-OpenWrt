#!/bin/bash

# 1. 定义添加源的函数 (防止重复添加) 
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

# 4. 特殊处理：移除容易报错的旧版 argonconfig feed
sed -i '/argonconfig/d' feeds.conf.default 

echo "✅ diy-part1.sh 执行完毕。"
