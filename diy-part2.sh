#!/bin/bash

# 1. 修改默认管理 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 2. 固化默认语言和 Argon 主题（重置不丢失）
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

# 3. 核心依赖补全与错误剔除（针对 0_build.txt 中的错误）
cat << 'EOF' >> .config
# 补全 PassWall 必需的 PPP 内核模块
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppox=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-pppol2tp=y

# 彻底禁用导致路径报错的 Ruby 组件
# CONFIG_PACKAGE_ruby is not set
# CONFIG_PACKAGE_ruby-bigdecimal is not set

# 禁用有冲突的边缘插件
# CONFIG_PACKAGE_onionshare-cli is not set

# 确保 Argon 相关包选中
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y
EOF

# 4. 自动更新 PassWall 核心组件
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path="feeds/passwall_packages/$pkg_name/Makefile"
    [ -f "$makefile_path" ] || { echo "⚠️ 跳齐 $pkg_name"; return 0; }
    local latest_version=$(curl --silent --connect-timeout 5 "https://api.github.com/repos/$github_repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    if [ -n "$latest_version" ]; then
        sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
        sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
    fi
}
update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# 5. CPU 温度显示 (x86)
echo 'CONFIG_PACKAGE_kmod-coretemp=y' >> .config
echo 'CONFIG_PACKAGE_kmod-it87=y' >> .config
mkdir -p package/base-files/files/etc/modules.d
echo "coretemp" > package/base-files/files/etc/modules.d/coretemp

# 6. 刷新配置以应用依赖修改
make defconfig
