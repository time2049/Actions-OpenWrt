#!/bin/bash

# 修改默认 IP 为 10.1.1.1
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 如果工作流没有自动复制 .config，则手动复制（假设 .config 在仓库根目录）
if [ -f "$GITHUB_WORKSPACE/.config" ]; then
    cp "$GITHUB_WORKSPACE/.config" .config
fi

# 使配置生效
make defconfig
