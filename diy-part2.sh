#!/bin/bash

# =================================================================
# diy-part2.sh: 固件功能定制脚本
# 针对 OpenWrt SNAPSHOT (Master 26.x) APK 模式优化
# =================================================================

# 1. 修改默认管理 IP (192.168.1.1 -> 10.1.1.1)
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 2. 强制中文与 Argon 主题 (解决开机英文和主题失效的终极方案)
# 使用 uci-defaults 脚本确保开机即生效，解决新版 APK 模式下源码修改易失效的问题
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-init-settings
uci set luci.main.lang=zh_cn
uci set luci.main.mediaurlbase=/luci-static/argon
uci commit luci
exit 0
EOF

# 3. 补齐 Argon 可视化配置插件
rm -rf package/luci-app-argon-config
git clone --depth 1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# 4. 显式安装 Ruby 依赖 (修复 OpenClash 编译报错 ruby no such package)
# 注意：在 DIY2 脚本中，必须先执行 update 才能保证 install 成功
./scripts/feeds update packages
./scripts/feeds install ruby ruby-yaml ruby-psych ruby-dbm ruby-pstore

# 5. 剔除导致编译冲突的 onionshare
rm -rf feeds/packages/net/onionshare-cli
echo '# CONFIG_PACKAGE_onionshare-cli is not set' >> .config

# 6. 注入 J1900 硬件驱动和必需模块
cat << 'EOF' >> .config
CONFIG_PACKAGE_kmod-coretemp=y
CONFIG_PACKAGE_kmod-it87=y
CONFIG_PACKAGE_lm-sensors=y
CONFIG_PACKAGE_ruby=y
CONFIG_PACKAGE_ruby-yaml=y
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppox=y
CONFIG_PACKAGE_kmod-pppoe=y
EOF

# 7. 自动更新 PassWall/OpenClash 核心组件 (根据 GitHub 最新 Release)
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path=$(find feeds/ -name Makefile | grep "/$pkg_name/Makefile" | head -n 1)
    [ -f "$makefile_path" ] || return 0
    
    local latest_version=$(curl --silent "https://api.github.com/repos/$github_repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    if [ -n "$latest_version" ] && [ "$latest_version" != "null" ]; then
        sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
        sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
        echo "✅ $pkg_name 已更新至版本: $latest_version"
    fi
}

update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# 8. 刷新所有依赖 (26 分支 APK 模式建议再次同步)
./scripts/feeds install -a

echo "✅ diy-part2.sh 执行完毕。"
 
