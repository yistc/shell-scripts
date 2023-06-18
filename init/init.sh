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
GITPROXY='https://ghproxy.com'

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
elif [[ "$ARCH" == "arm64" ]]; then
  # if debian
  if [[ "$DISTRO" == "debian" ]]; then
    curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/init/debian_arm64_init.sh
    bash debian_arm64_init.sh
  # if ubuntu
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
