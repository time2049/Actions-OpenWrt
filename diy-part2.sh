#!/bin/bash

# ==================== 1. 修改默认管理 IP ====================
# 将默认 IP 从 192.168.1.1 修改为 10.1.1.1
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# ==================== 2. 设置 Argon 为默认主题 ====================
# 修正：通过修改系统初始化配置来启用主题，避免直接修改 Makefile 导致找不到包的报错
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/modules/luci-base/root/etc/config/luci

# ==================== 3. 设置默认语言为简体中文 ====================
# 强制指定管理界面语言为中文
sed -i "s/option lang 'auto'/option lang 'zh-cn'/" feeds/luci/modules/luci-base/root/etc/config/luci

# ==================== 4. 强制禁用 onionshare-cli 以消除警告 ====================
# 预先向 .config 注入禁用配置，减少编译干扰
echo '# CONFIG_PACKAGE_onionshare-cli is not set' >> .config

# ==================== 5. 自动更新 PassWall 核心组件 ====================
# 这里的路径匹配你在 diy-part1.sh 中定义的 passwall_packages
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path="feeds/passwall_packages/$pkg_name/Makefile"
    
    [ -f "$makefile_path" ] || { echo "⚠️ 跳过 $pkg_name（文件不存在）"; return 0; }
    
    echo "🔄 正在检查 $pkg_name 的最新版本..."
    local latest_version=$(curl --silent --connect-timeout 5 --max-time 10 "https://api.github.com/repos/$github_repo/releases/latest" | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    if [ -n "$latest_version" ]; then
        local current_version=$(grep 'PKG_VERSION:=' "$makefile_path" | cut -d'=' -f2)
        if [ "$latest_version" != "$current_version" ]; then
            echo "   ✅ 更新 $pkg_name: $current_version -> $latest_version"
            sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
            # 将哈希设为 skip，防止因哈希不匹配导致下载失败
            sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
        fi
    fi
}

# 这里的包名需要对应仓库中的实际目录名
update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# ==================== 6. 添加 CPU 温度显示与驱动 (x86) ====================
# 即使你的 .config 初始没有这些，脚本也会强行帮你补齐
echo 'CONFIG_PACKAGE_kmod-coretemp=y' >> .config
echo 'CONFIG_PACKAGE_kmod-it87=y' >> .config
echo 'CONFIG_PACKAGE_lm-sensors=y' >> .config

# 6.1 复制自定义 index.htm
# 目标路径是源码中的 luci-mod-status 模板位置
TARGET_INDEX="feeds/luci/modules/luci-mod-status/luasrc/view/admin_status/index.htm"
# 来源路径是你明确的 files 目录结构
CUSTOM_SOURCE="$GITHUB_WORKSPACE/files/usr/lib/lua/luci/view/admin_status/index.htm"

if [ -f "$CUSTOM_SOURCE" ]; then
    cp -f "$CUSTOM_SOURCE" "$TARGET_INDEX"
    echo "✅ 已成功覆盖 index.htm，支持 CPU 温度显示"
else
    echo "⚠️ 错误：未能在 $CUSTOM_SOURCE 找到文件"
fi

# ==================== 7. 使所有配置生效 ====================
# 最后运行一遍 defconfig 刷新配置，补全依赖
make defconfig
