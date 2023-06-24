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

# echo distro and arch
echo -e "${GREEN}Distro: ubuntu, Arch: ${ARCH}${NC}"

apt update -y
apt install wget curl vim net-tools unzip -y

# snap remove oracle-cloud-agent
snap remove oracle-cloud-agent

# firewalld
systemctl stop firewalld.service
systemctl disable firewalld.service

# open all ports
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F

apt purge netfilter-persistent -y

# rpcbind
systemctl stop rpcbind
systemctl stop rpcbind.socket
systemctl disable rpcbind
systemctl disable rpcbind.socket

if [[ "$ARCH" == "x86_64" ]]; then
    curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/init/ubuntu_amd64_init.sh
    bash ubuntu_amd64_init.sh
# if arm64
elif [[ "$ARCH" == "arm64" ]]; then
    curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/init/ubuntu_arm64_init.sh
    bash ubuntu_arm64_init.sh
else
  echo "Not supported"
  exit 1
fi