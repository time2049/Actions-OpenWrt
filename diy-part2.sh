#!/bin/bash

# 1. 精准修改默认管理 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 2. 强制中文、锁死 24位掩码与 Argon 主题 (UCI defaults 终极开机防线)
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-init-settings
#!/bin/sh
uci set network.lan.ipaddr='10.1.1.1'
uci set network.lan.netmask='255.255.255.0'
uci commit network

uci set luci.main.lang=zh_cn
uci set luci.main.mediaurlbase=/luci-static/argon
uci commit luci

rm -f /var/run/fw4.lock /var/run/luci-reload.lock
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-init-settings

# 3. 完美补齐 Argon 主题本体 与 可视化配置插件
rm -rf package/luci-theme-argon
rm -rf package/luci-app-argon-config
git clone --depth 1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# 4. 显式安装 Ruby 依赖 (修复 OpenClash 编译报错)
./scripts/feeds update packages
./scripts/feeds install ruby ruby-yaml ruby-psych ruby-dbm ruby-pstore

# 5. 剔除导致编译冲突的 onionshare
rm -rf feeds/packages/net/onionshare-cli
echo '# CONFIG_PACKAGE_onionshare-cli is not set' >> .config

# 6. 🌟 核心修正：注入 26.x APK 模式强制中文宏、J1900驱动以及核心插件支持
cat << 'EOF' >> .config
# ======== 26.x APK 全局语言强制固化宏 ========
CONFIG_BUILD_NLS=y
CONFIG_LUCI_LANG_zh_Hans=y
CONFIG_LUCI_LANG_zh-cn=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-i18n-firewall-zh-cn=y
CONFIG_PACKAGE_luci-app-package-manager=y
CONFIG_PACKAGE_luci-i18n-package-manager-zh-cn=y

# ======== 主题与插件本地配置 ========
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
CONFIG_PACKAGE_luci-i18n-argon-config-zh-cn=y
CONFIG_PACKAGE_luci-app-openclash=y

# ======== J1900 硬件驱动与必需模块 ========
CONFIG_PACKAGE_kmod-coretemp=y
CONFIG_PACKAGE_kmod-it87=y
CONFIG_PACKAGE_lm-sensors=y
CONFIG_PACKAGE_ruby=y
CONFIG_PACKAGE_ruby-yaml=y
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppox=y
CONFIG_PACKAGE_kmod-pppoe=y
EOF

# 7. 自动更新核心网络组件内核 (增加容错)
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path=$(find feeds/ -name Makefile | grep "/$pkg_name/Makefile" | head -n 1)
    [ -f "$makefile_path" ] || return 0
    
    local latest_version=$(curl --silent --connect-timeout 5 --max-time 10 "https://api.github.com/repos/$github_repo/releases/latest" 2>/dev/null | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    if [ -n "$latest_version" ] && [ "$latest_version" != "null" ] && [ "$latest_version" != "" ]; then
        sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
        sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
        echo "✅ $pkg_name 已自动更新至最新版本: $latest_version"
    else
        echo "⚠️ $pkg_name 获取最新版本超时或受限，保持源码默认版本编译"
    fi
}

update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# 8. 刷新所有依赖
./scripts/feeds install -a

echo "✅ diy-part2.sh 执行完毕。"
