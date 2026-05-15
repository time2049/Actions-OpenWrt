#!/bin/bash

# ==================== 1. 修改默认管理 IP ====================
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

# ==================== 3. 核心依赖修复与报错剔除 ====================
# 通过追加配置的方式，修复日志中出现的 kmod-ppp 缺失和 Ruby 路径错误
cat << 'EOF' >> .config
# 补全 PassWall 必需的 PPP 内核模块（解决 kmod-ppp 报错）
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppox=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-pppol2tp=y

# 彻底禁用导致路径报错的 Ruby 组件（精简版不需要）
# CONFIG_PACKAGE_ruby is not set
# CONFIG_PACKAGE_ruby-bigdecimal is not set

# 禁用有冲突且会导致 Python 依赖缺失的插件
# CONFIG_PACKAGE_onionshare-cli is not set

# 确保界面中文和主题选中
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y
EOF

# ==================== 4. 自动更新 PassWall 核心组件 ====================
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path="feeds/passwall_packages/$pkg_name/Makefile"
    [ -f "$makefile_path" ] || { echo "⚠️ 跳过 $pkg_name"; return 0; }
    echo "🔄 检查 $pkg_name 最新版本..."
    local latest_version=$(curl --silent --connect-timeout 5 --max-time 10 "https://api.github.com/repos/$github_repo/releases/latest" | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    if [ -n "$latest_version" ]; then
        echo "   ✅ 更新 $pkg_name 至 $latest_version"
        sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
        sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
    fi
}

update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# ==================== 5. CPU 温度显示（针对 J1900 x86） ====================
echo 'CONFIG_PACKAGE_kmod-coretemp=y' >> .config
echo 'CONFIG_PACKAGE_kmod-it87=y' >> .config
echo 'CONFIG_PACKAGE_lm-sensors=y' >> .config
mkdir -p package/base-files/files/etc/modules.d
echo "coretemp" > package/base-files/files/etc/modules.d/coretemp

# 覆盖温度显示模板（需确保项目根目录 files 下有对应文件）
TARGET_INDEX="feeds/luci/modules/luci-mod-status/luasrc/view/admin_status/index.htm"
CUSTOM_SOURCE="$GITHUB_WORKSPACE/files/usr/lib/lua/luci/view/admin_status/index.htm"
if [ -f "$CUSTOM_SOURCE" ]; then
    cp -f "$CUSTOM_SOURCE" "$TARGET_INDEX"
    echo "✅ CPU 温度模板已应用"
fi

# ==================== 6. 刷新配置以应用所有修改 ====================
make defconfig
