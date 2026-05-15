#!/bin/bash

# 1. 修改默认管理 IP (已改为 10.1.1.1)
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 2. 固化默认语言和 Argon 主题
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

# 3. 精准剔除冲突组件 (解决 onionshare 报错)
# 只删掉这几个真正卡住编译的包，保留 feeds/packages/lang/python 以消除警告
rm -rf feeds/luci/applications/luci-app-onionshare
rm -rf feeds/packages/net/onionshare-cli
# Ruby 路由器用不到，可以直接删掉省空间
rm -rf feeds/packages/lang/ruby

# 4. 核心依赖补全与错误拦截
cat << 'EOF' >> .config
# 补全 PassWall 必需的 PPP 内核模块 (解决 0_build.txt 报错)
CONFIG_PACKAGE_kmod-ppp=y
CONFIG_PACKAGE_kmod-pppox=y
CONFIG_PACKAGE_kmod-pppoe=y
CONFIG_PACKAGE_kmod-pppol2tp=y
CONFIG_PACKAGE_kmod-pptp=y

# 补全 J1900 温度显示相关模块
CONFIG_PACKAGE_kmod-coretemp=y
CONFIG_PACKAGE_kmod-it87=y
CONFIG_PACKAGE_lm-sensors=y

# 强制不选有问题的组件，防止被依赖项自动拉回
# CONFIG_PACKAGE_luci-app-onionshare is not set
# CONFIG_PACKAGE_onionshare-cli is not set
# CONFIG_PACKAGE_ruby is not set
EOF

# 5. 自动更新 PassWall 核心组件并跳过哈希校验
update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path=$(find feeds/ -name Makefile | grep "/$pkg_name/Makefile" | head -n 1)
    [ -f "$makefile_path" ] || { echo "⚠️ 跳过 $pkg_name"; return 0; }
    
    local latest_version=$(curl --silent --connect-timeout 5 --max-time 10 "https://api.github.com/repos/$github_repo/releases/latest" | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')
    
    if [ -n "$latest_version" ]; then
        echo "🔄 更新 $pkg_name 至 $latest_version"
        sed -i "s|PKG_VERSION:=.*|PKG_VERSION:=$latest_version|g" "$makefile_path"
        # 核心：将哈希设为 skip，防止因为版本更新导致的校验失败
        sed -i "s|PKG_HASH:=.*|PKG_HASH:=skip|g" "$makefile_path"
    fi
}

update_go_package "xray-core" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"

# 6. 刷新配置 (非常重要)
# 这步会让编译器重新计算依赖链，剔除已删除源码的关联
make defconfig

echo "DIY2 脚本执行完毕。"
