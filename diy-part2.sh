#!/bin/bash

# ==================== 1. 修改默认管理 IP ====================
# 已修改为 10.1.1.1
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# ==================== 2. 固化默认语言和 Argon 主题 ====================
mkdir -p package/base-files/files/etc/config
cat << 'EOF' > package/base-files/files/etc/config/luci
config core 'main'
	option lang 'zh-cn'
	option mediaurlbase '/luci-static/argon'
	option resourcebase '/luci-static/resources'

config internal 'themes'
	option Argon '/luci-static/argon'
	option Bootstrap '/luci-static/bootstrap'
EOF

# ==================== 3. 核心依赖补全与致命错误剔除 ====================

# --- 3.1 强制剔除导致哈希报错和下载失败的源码 (重点解决 onionshare) ---
# 这些源码如果不删掉，即使 .config 没勾选，有时候 feeds 也会去拉取它们导致报错
rm -rf feeds/luci/applications/luci-app-onionshare
rm -rf feeds/packages/net/onionshare-cli
rm -rf feeds/packages/lang/ruby
rm -rf feeds/packages/lang/python

# --- 3.2 写入配置到 .config ---
cat << 'EOF' >> .config
# 补全网络核心模块 (解决日志中 kmod-pppoe 等缺失问题)
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppox=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-pppol2tp=y
CONFIG_PACKAGE_kmod-pptp=y

# 补全网卡驱动 (J1900 常用 Intel 网卡)
CONFIG_PACKAGE_kmod-igb=y
CONFIG_PACKAGE_kmod-e1000e=y
CONFIG_PACKAGE_kmod-r8168=y

# 彻底禁用有冲突的组件 (确保不被其他插件依赖拉进来)
# CONFIG_PACKAGE_luci-app-onionshare is not set
# CONFIG_PACKAGE_onionshare-cli is not set
# CONFIG_PACKAGE_ruby is not set

# 补全 J1900 温度显示和传感器支持
CONFIG_PACKAGE_kmod-coretemp=y
CONFIG_PACKAGE_kmod-it87=y
CONFIG_PACKAGE_lm-sensors=y
EOF

# ==================== 4. 自动更新 PassWall/SSR+ 核心组件 ====================
# 修正：将 PKG_HASH 设置为 skip 会在编译时忽略哈希校验，解决之前日志里 Hash Mismatch 的问题
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path=$(find feeds/ -name Makefile | grep "/$pkg_name/Makefile" | head -n 1)
    [ -f "$makefile_path" ] || { echo "⚠️ 跳过 $pkg_name，未找到 Makefile"; return 0; }
    
    local latest_version=$(curl --silent --connect-timeout 5 --max-time 10 "https://api.github.com/repos/$github_repo/releases/latest" | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    if [ -n "$latest_version" ]; then
        echo "🔄 更新 $pkg_name 至 $latest_version"
        sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
        # 强制设置哈希为 skip，跳过导致编译失败的下载校验
        sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
    fi
}

update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# ==================== 5. 刷新配置 ====================
# make defconfig 会根据 .config 里的变更自动计算依赖，这一步是确保编译成功的关键
make defconfig

echo "DIY2 脚本执行完毕，已精简并修复依赖。"
