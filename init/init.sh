#! /bin/bash

[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

trap _exit INT QUIT TERM

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

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
# DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )

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

# check linux release
# 通过 /etc/os-release 文件判断发行版
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ $ID = "debian" ]]; then
        DISTRO="debian"
    elif [[ $ID = "ubuntu" ]]; then
        DISTRO="ubuntu"
    elif [[ $ID = "centos" ]]; then
        DISTRO="centos"
    else
        DISTRO="unknown"
    fi
# 通过 /etc/*-release 文件判断发行版
elif [ -f /etc/centos-release ]; then
    DISTRO="centos"
elif [ -f /etc/redhat-release ]; then
    DISTRO="redhat"
elif [ -f /etc/fedora-release ]; then
    DISTRO="fedora"
elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
elif [ -f /etc/lsb-release ]; then
    DISTRO="ubuntu"
else
    DISTRO="unknown"
fi

# echo distro and arch
echo -e "${GREEN}Distro: ${DISTRO}, Arch: ${ARCH}${NC}"

# init based on distro and arch
# if x86_64
if [[ "$ARCH" == "x86_64" ]]; then
  # if debian
  if [[ "$DISTRO" == "debian" ]]; then
    curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/init/debian_amd64_init.sh
    bash debian_amd64_init.sh
  # if ubuntu
  elif [[ "$DISTRO" == "ubuntu" ]]; then
    curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/init/ubuntu_amd64_init.sh
    bash ubuntu_amd64_init.sh
  else
    echo "Not supported"
    exit 1
  fi
# if arm64
elif [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
  # if debian
  if [[ "$DISTRO" == "debian" ]]; then
    # if ipv6-only
    if [[ "$IP_STATUS" == "v6-only" ]]; then
      curl -L https://raw.githubusercontent.com/yistc/shell-scripts/refs/heads/main/init/debian_arm_ipv6.sh -o debian_arm_init.sh && bash debian_arm_init.sh
    else
      curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/init/debian_arm_init.sh && bash debian_arm_init.sh
    fi
  elif [[ "$DISTRO" == "ubuntu" ]]; then
    curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/init/ubuntu_arm64_init.sh
    bash ubuntu_arm64_init.sh
  else
    echo "Not supported"
    exit 1
  fi
else
  echo "Not supported"
  exit 1
fi

rm init.sh