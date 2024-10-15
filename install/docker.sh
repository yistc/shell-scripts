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
V4PROXY="http://127.0.0.1:8901"

OS=$(uname -s) # Linux, FreeBSD, Darwin
ARCH=$(uname -m) # x86_64, arm64, aarch64

# Check if ipv6-only

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

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

apt update -y
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install docker-ce docker-ce-cli containerd.io -y
docker -v

# download
if [[ $IP_STATUS == "v6-only" ]]; then
  curl -x $V4PROXY -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
else
  curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
fi

chmod +x /usr/local/bin/docker-compose
docker-compose -v

# limiting log size
cat >/etc/docker/daemon.json<<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "5m"
  }
}
EOF

systemctl restart docker

rm -f $0