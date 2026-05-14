#!/bin/bash

# ==================== 1. 修改默认管理 IP ====================
# 将默认 IP 修改为 10.1.1.1
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# ==================== 2. 设置 Argon 为默认主题 ====================
# 修改系统初始化配置，确保首屏就是 Argon
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/modules/luci-base/root/etc/config/luci

# ==================== 3. 设置默认语言为简体中文 ====================
sed -i "s/option lang 'auto'/option lang 'zh-cn'/" feeds/luci/modules/luci-base/root/etc/config/luci

# ==================== 4. 消除编译警告 ====================
echo '# CONFIG_PACKAGE_onionshare-cli is not set' >> .config

# ==================== 5. 自动更新 PassWall 核心组件 ====================
# 已经根据图片 image_93ea33.png 确认路径为 xray-core 和 sing-box
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path="feeds/passwall_packages/$pkg_name/Makefile"
    
    [ -f "$makefile_path" ] || { echo "⚠️ 跳过 $pkg_name（路径不存在）"; return 0; }
    
    echo "🔄 正在检查 $pkg_name 的最新版本..."
    local latest_version=$(curl --silent --connect-timeout 5 --max-time 10 "https://api.github.com/repos/$github_repo/releases/latest" | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    if [ -n "$latest_version" ]; then
        local current_version=$(grep 'PKG_VERSION:=' "$makefile_path" | cut -d'=' -f2)
        if [ "$latest_version" != "$current_version" ]; then
            echo "   ✅ 更新 $pkg_name: $current_version -> $latest_version"
            sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
            # 设为 skip 防止旧哈希导致下载失败
            sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
        fi
    fi
}

# 根据图片确定的目录名执行更新
update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# ==================== 6. 强制补全 CPU 温度显示配置 (针对 J1900) ====================
# 即使初始配置没有，脚本也会强行注入
echo 'CONFIG_PACKAGE_kmod-coretemp=y' >> .config
echo 'CONFIG_PACKAGE_kmod-it87=y' >> .config
echo 'CONFIG_PACKAGE_lm-sensors=y' >> .config

# 复制自定义 index.htm (支持温度显示)
TARGET_INDEX="feeds/luci/modules/luci-mod-status/luasrc/view/admin_status/index.htm"
CUSTOM_SOURCE="$GITHUB_WORKSPACE/files/usr/lib/lua/luci/view/admin_status/index.htm"

if [ -f "$CUSTOM_SOURCE" ]; then
    cp -f "$CUSTOM_SOURCE" "$TARGET_INDEX"
    echo "✅ CPU温度显示模板已覆盖"
else
    echo "⚠️ 警告：未找到自定义 index.htm"
fi

# ==================== 7. 刷新配置 ====================
make defconfig
