#!/bin/bash
# 初始化 feeds（确保后续能找到正确的路径）
./scripts/feeds update -a
./scripts/feeds install -a

# --- 1. 函数：从 GitHub 获取最新版本号 ---
get_latest_tag() {
    curl --silent "https://api.github.com/repos/$1/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//'
}

# --- 2. 函数：更新通用 Go 语言包的 Makefile (适用于 xray, sing-box, hysteria)---
update_go_package() {
    local pkg_name=$1           # 软件包名 (例如: xray, sing-box, hysteria)
    local github_repo=$2        # GitHub 仓库路径 (例如: XTLS/Xray-core)
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
        # 更新版本号，并使用 skip 让 OpenWrt 自动处理哈希值
        sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$latest_version/g" $makefile_path
        sed -i 's/PKG_HASH:=.*/PKG_HASH:=skip/g' $makefile_path
    else
        echo "  已是最新版本: $latest_version"
    fi
}

# --- 3. 函数：更新 OpenClash ---
update_openclash() {
    local makefile_path="feeds/openclash/Makefile"
    if [ ! -f "$makefile_path" ]; then
        echo "警告: $makefile_path 不存在，请检查 OpenClash feed 是否已成功添加。"
        return 1
    fi
    echo "正在更新 OpenClash..."
    # 获取最新版本号，OpenClash 的 tag 通常以 'v' 开头
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

# --- 4. 执行更新 (请放在 `make defconfig` 之前) ---
update_go_package "xray" "XTLS/Xray-core"
update_go_package "sing-box" "SagerNet/sing-box"
update_go_package "hysteria" "apernet/hysteria"
update_openclash

# --- 5. 你原有的设置继续保留 ---
# 修改默认 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 将 Argon 设为默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-nginx/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-ssl-nginx/Makefile

# 设置默认语言为简体中文
sed -i "s/option lang 'auto'/option lang 'zh-cn'/" feeds/luci/modules/luci-base/root/etc/config/luci

# 运行 defconfig 使配置生效
make defconfig
