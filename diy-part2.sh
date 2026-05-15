#!/bin/bash

# 1. 修改默认管理 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 2. 固化中文与 Argon
mkdir -p package/base-files/files/etc/config
cat << 'EOF' > package/base-files/files/etc/config/luci
config core 'main'
	option lang 'zh-cn'
	option mediaurlbase '/luci-static/argon'
EOF

# 3. 剔除真正冲突的 onionshare (这就是那个卡 ppp 的真凶)
# 只删 onionshare，绝对不要删 Ruby！
rm -rf feeds/luci/applications/luci-app-onionshare
rm -rf feeds/packages/net/onionshare-cli

# 4. 【核心修复】强行拉回 Ruby 依赖 (为了 OpenClash)
./scripts/feeds install ruby ruby-yaml ruby-psych ruby-dbm ruby-pstore

# 5. 补齐 J1900 硬件驱动和 PassWall 必需的 PPP 模块
cat << 'EOF' >> .config
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppox=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-coretemp=y
CONFIG_PACKAGE_kmod-it87=y
CONFIG_PACKAGE_lm-sensors=y
# 强制选中 Ruby，防止它被漏掉
CONFIG_PACKAGE_ruby=y
CONFIG_PACKAGE_ruby-yaml=y
EOF

# 6. 自动更新 PassWall 核心组件 (保持你原来的逻辑)
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path=$(find feeds/ -name Makefile | grep "/$pkg_name/Makefile" | head -n 1)
    [ -f "$makefile_path" ] || return 0
    local latest_version=$(curl --silent "https://api.github.com/repos/$github_repo/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    if [ -n "$latest_version" ]; then
        sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
        sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
    fi
}
update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# 7. 刷新依赖 (25分支必须执行 install -a)
./scripts/feeds install -a

echo "DIY2 脚本执行完毕，Ruby 已解封，OpenClash 依赖已就绪。"
