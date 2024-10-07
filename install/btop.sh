#! /bin/bash

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
V4PROXY="http://127.0.0.1:8901"

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

GOOGLE_IPV4_ADDRESS="8.8.8.8"
GOOGLE_IPV6_ADDRESS="2001:4860:4860::8888"
ping_ipv4() {
    ping -4 -c 3 -W 2 "$GOOGLE_IPV4_ADDRESS" > /dev/null 2>&1
    return $?
}

ping_ipv6() {
    ping -6 -c 3 -W 2 "$GOOGLE_IPV6_ADDRESS" > /dev/null 2>&1
    return $?
}

# Ping IPv4
ping_ipv4
IPV4_STATUS=$?

# Ping IPv6
ping_ipv6
IPV6_STATUS=$?

IP_STATUS=""
if [ $IPV4_STATUS -eq 0 ] && [ $IPV6_STATUS -eq 0 ]; then
    IP_STATUS="dual"
elif [ $IPV4_STATUS -eq 0 ] && [ $IPV6_STATUS -ne 0 ]; then
    IP_STATUS="v4-only"
elif [ $IPV4_STATUS -ne 0 ] && [ $IPV6_STATUS -eq 0 ]; then
    IP_STATUS="v6-only"
else
    IP_STATUS="none"
fi

# if v4-only or dual
if [[ $IP_STATUS == "v4-only" || $IP_STATUS == "dual" ]]; then
  # latest tag_name
  tag_name=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | grep tag_name|cut -f4 -d "\"")
# if v6-only
elif [[ $IP_STATUS == "v6-only" ]]; then
  # latest tag_name, use proxy curl -x $V4PROXY
  # tag_name=$(curl -s https://api.github.com/repos/aristocratos/btop/releases/latest | grep tag_name|cut -f4 -d "\"")
  tag_name=$(curl -x $V4PROXY -s https://api.github.com/repos/aristocratos/btop/releases/latest | grep tag_name|cut -f4 -d "\"")
fi

# download based on arch
if [[ $ARCH == "x86_64" ]]; then
  download_url="https://github.com/aristocratos/btop/releases/download/$tag_name/btop-x86_64-linux-musl.tbz"
  zip_name="btop-x86_64-linux-musl.tbz"
elif [[ $ARCH == "arm64" || $ARCH == "aarch64" ]]; then
  download_url="https://github.com/aristocratos/btop/releases/download/$tag_name/btop-aarch64-linux-musl.tbz"
  zip_name="btop-aarch64-linux-musl.tbz"
fi

# download
if [[ $IP_STATUS == "v6-only" ]]; then
  curl -x $V4PROXY -LO $download_url
else
  curl -LO $download_url
fi

tar -xjf $zip_name
cd btop
make install
cd ..
rm -rf btop
rm -rf $zip_name
