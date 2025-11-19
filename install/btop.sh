#!/bin/bash

[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

trap _exit INT QUIT TERM

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

OS=$(uname -s) # Linux, FreeBSD, Darwin
ARCH=$(uname -m) # x86_64, arm64, aarch64
DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

tag_name=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | grep tag_name|cut -f4 -d "\"")
# download based on arch
if [[ $ARCH == "x86_64" ]]; then
  download_url="https://github.com/aristocratos/btop/releases/download/$tag_name/btop-x86_64-linux-musl.tbz"
  zip_name="btop-x86_64-linux-musl.tbz"
elif [[ $ARCH == "arm64" || $ARCH == "aarch64" ]]; then
  download_url="https://github.com/aristocratos/btop/releases/download/$tag_name/btop-aarch64-linux-musl.tbz"
  zip_name="btop-aarch64-linux-musl.tbz"
fi

curl -LO $download_url

tar -xjf $zip_name
cd btop
make install
cd ..
rm -rf btop
rm -rf $zip_name
