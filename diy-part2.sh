#!/bin/bash

# ==================== 1. 修改默认管理 IP ====================
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# ==================== 2. 设置 Argon 为默认主题 ====================
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-nginx/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-ssl-nginx/Makefile

# ==================== 3. 设置默认语言为简体中文 ====================
sed -i "s/option lang 'auto'/option lang 'zh-cn'/" feeds/luci/modules/luci-base/root/etc/config/luci

# ==================== 4. 强制禁用 onionshare-cli 以消除警告 ====================
echo '# CONFIG_PACKAGE_onionshare-cli is not set' >> .config

# ==================== 5. 自动更新核心组件（PassWall 依赖和 OpenClash） ====================
get_latest_tag() {
    local repo=$1
    curl --silent --connect-timeout 5 --max-time 10 "https://api.github.com/repos/$repo/releases/latest" | \
        grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//'
}

update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path="feeds/passwall_packages/$pkg_name/Makefile"
    [ -f "$makefile_path" ] || { echo "⚠️ 跳过 $pkg_name（文件不存在）"; return 1; }
    echo "🔄 正在更新 $pkg_name ..."
    local latest_version=$(get_latest_tag "$github_repo")
    [ -z "$latest_version" ] && { echo "❌ 获取 $pkg_name 版本失败"; return 1; }
    local current_version=$(grep 'PKG_VERSION:=' "$makefile_path" | cut -d'=' -f2)
    if [ "$latest_version" != "$current_version" ]; then
        echo "   版本更新: $current_version → $latest_version"
        sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$latest_version/g" "$makefile_path"
        sed -i '/PKG_HASH:=/d' "$makefile_path"   # 删除旧哈希，让系统自动计算
    else
        echo "   已是最新: $latest_version"
    fi
}

update_openclash() {
    local makefile_path="feeds/openclash/Makefile"
    [ -f "$makefile_path" ] || { echo "⚠️ 跳过 OpenClash（文件不存在）"; return 1; }
    echo "🔄 正在更新 OpenClash ..."
    local latest_version=$(get_latest_tag "vernesong/OpenClash")
    [ -z "$latest_version" ] && { echo "❌ 获取 OpenClash 版本失败"; return 1; }
    local current_version=$(grep 'PKG_VERSION:=' "$makefile_path" | cut -d'=' -f2)
    if [ "$latest_version" != "$current_version" ]; then
        echo "   版本更新: $current_version → $latest_version"
        sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$latest_version/g" "$makefile_path"
        sed -i '/PKG_HASH:=/d' "$makefile_path"
    else
        echo "   已是最新: $latest_version"
    fi
}

# 执行更新
update_go_package "xray" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"
update_openclash

# ==================== 6. 添加 CPU 温度显示（x86） ====================
# 确保安装 coretemp 内核模块
echo 'CONFIG_PACKAGE_kmod-coretemp=y' >> .config

# 复制自定义的 index.htm（你已放在仓库 files/usr/lib/lua/luci/view/admin_status/index.htm）
cp -f $GITHUB_WORKSPACE/files/usr/lib/lua/luci/view/admin_status/index.htm \
      feeds/luci/modules/luci-mod-status/luasrc/view/admin_status/index.htm

# ==================== 7. 使所有配置生效 ====================
make defconfig
