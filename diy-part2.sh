#!/bin/bash

# ==================== 1. 初始化 feeds（可选，工作流已执行，但保留无妨） ====================
./scripts/feeds update -a
./scripts/feeds install -a

# ==================== 2. 自动更新核心组件到最新版 ====================
get_latest_tag() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//'
}

update_go_package() {
    local pkg_name=$1
    local github_repo=$2
    local makefile_path="feeds/passwall_packages/$pkg_name/Makefile"
    if [ ! -f "$makefile_path" ]; then
        echo "警告: $makefile_path 不存在，跳过更新 $pkg_name"
        return 1
    fi
    echo "正在更新 $pkg_name..."
    local latest_version=$(get_latest_tag "$github_repo")
    if [ -z "$latest_version" ]; then
        echo "  获取最新版本号失败，跳过更新。"
        return 1
    fi
    local current_version=$(grep 'PKG_VERSION:=' $makefile_path | cut -d'=' -f2)
    if [ "$latest_version" != "$current_version" ]; then
        echo "  版本更新: $current_version -> $latest_version"
        sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$latest_version/g" $makefile_path
        sed -i 's/PKG_HASH:=.*/PKG_HASH:=skip/g' $makefile_path
    else
        echo "  已是最新版本: $latest_version"
    fi
}

update_openclash() {
    local makefile_path="feeds/openclash/Makefile"
    if [ ! -f "$makefile_path" ]; then
        echo "警告: $makefile_path 不存在，请检查 OpenClash feed 是否已成功添加。"
        return 1
    fi
    echo "正在更新 OpenClash..."
    local latest_version=$(get_latest_tag "vernesong/OpenClash")
    if [ -z "$latest_version" ]; then
        echo "  获取最新版本号失败，跳过更新。"
        return 1
    fi
    local current_version=$(grep 'PKG_VERSION:=' $makefile_path | cut -d'=' -f2)
    if [ "$latest_version" != "$current_version" ]; then
        echo "  版本更新: $current_version -> $latest_version"
        sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$latest_version/g" $makefile_path
        sed -i 's/PKG_HASH:=.*/PKG_HASH:=skip/g' $makefile_path
    else
        echo "  已是最新版本: $latest_version"
    fi
}

update_go_package "xray" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"
update_openclash

# ==================== 3. 修改默认管理 IP ====================
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# ==================== 4. 设置 Argon 为默认主题 ====================
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-nginx/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-ssl-nginx/Makefile

# ==================== 5. 设置默认语言为简体中文 ====================
sed -i "s/option lang 'auto'/option lang 'zh-cn'/" feeds/luci/modules/luci-base/root/etc/config/luci

# ==================== 6. 使配置生效 ====================
make defconfig
