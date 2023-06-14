#! /bin/bash

ARCH=$(uname -m)

# 检查系统架构类型
if [[ "$ARCH" == "x86_64" ]]; then
    message="当前系统为 AMD64 架构"
elif [[ "$ARCH" == "aarch64" ]]; then
    message="当前系统为 AArch64 架构"
else
    message="unknown arch"
fi
echo $message

curl -L -o gost.tar.gz https://github.com/go-gost/gost/releases/download/v3.0.0-rc7/gost_3.0.0-rc7_linux_amd64.tar.gz

tar -zxvf gost.tar.gz gost

chmod +x gost
mv gost /usr/local/bin/gost
rm -rf gost.tar.gz