#!/bin/bash

# 修改默认 IP
sed -i 's/192.168.1.1/10.1.1.1/g' package/base-files/files/bin/config_generate

# 可选：运行 defconfig（工作流后续也会执行，这里可省略，但保留也无妨）
make defconfig
