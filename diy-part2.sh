#!/bin/bash

# ==================== 1. 网络管理配置 ====================
# 修改默认管理 IP 为 10.1.1.1
# 这能避免与上级光猫常用的 192.168.1.1 冲突
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# ==================== 2. 界面与语言本地化 ====================
# 设置 Argon 为默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/modules/luci-base/root/etc/config/luci

# 设置默认语言为简体中文，确保刷机后直接显示中文
sed -i "s/option lang 'auto'/option lang 'zh-cn'/" feeds/luci/modules/luci-base/root/etc/config/luci

# ==================== 3. 核心插件自动更新 (PassWall) ====================
# 此函数会根据 GitHub 最新 Release 自动更新源码版本
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path="feeds/passwall_packages/$pkg_name/Makefile"
    
    [ -f "$makefile_path" ] || { echo "⚠️ 跳过 $pkg_name（路径不存在）"; return 0; }
    
    echo "🔄 检查 $pkg_name 最新版本..."
    local latest_version=$(curl --silent --connect-timeout 5 --max-time 10 "https://api.github.com/repos/$github_repo/releases/latest" | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    if [ -n "$latest_version" ]; then
        local current_version=$(grep 'PKG_VERSION:=' "$makefile_path" | cut -d'=' -f2)
        if [ "$latest_version" != "$current_version" ]; then
            echo "   ✅ 更新 $pkg_name: $current_version -> $latest_version"
            sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
            sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
        fi
    fi
}

# 根据图片 image_93ea33.png 确认的核心包名进行更新
update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# ==================== 4. J1900 硬件驱动补全与温度显示 ====================
# 强制注入 CPU 温度监控驱动，弥补 .config 中的缺失
echo 'CONFIG_PACKAGE_kmod-coretemp=y' >> .config
echo 'CONFIG_PACKAGE_kmod-it87=y' >> .config
echo 'CONFIG_PACKAGE_lm-sensors=y' >> .config

# 复制自定义 index.htm 以支持在首页显示 CPU 温度
TARGET_INDEX="feeds/luci/modules/luci-mod-status/luasrc/view/admin_status/index.htm"
CUSTOM_SOURCE="$GITHUB_WORKSPACE/files/usr/lib/lua/luci/view/admin_status/index.htm"

if [ -f "$CUSTOM_SOURCE" ]; then
    cp -f "$CUSTOM_SOURCE" "$TARGET_INDEX"
    echo "✅ CPU 温度显示模板已成功覆盖"
else
    echo "⚠️ 警告：未找到自定义 index.htm，请检查 files 目录结构"
fi

# ==================== 5. 配置生效 ====================
# 消除特定包导致的编译警告
echo '# CONFIG_PACKAGE_onionshare-cli is not set' >> .config

# 刷新配置，自动根据刚才追加的 CONFIG 处理依赖关系
make defconfig
