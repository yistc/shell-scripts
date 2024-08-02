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

tag_name=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name|cut -f4 -d "\"")

if [[ "$ARCH" == "x86_64" ]]; then
    ARCH_NAME="amd64"
elif [[ "$ARCH" == "arm64" ]]; then
    ARCH_NAME="arm64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH_NAME="arm64"
else
    echo -e "${RED}Unknown arch${NC}"
    exit 1
fi


TAR_NAME="node_exporter-${tag_name#v}.linux-${ARCH_NAME}.tar.gz"
curl -LO "https://github.com/prometheus/node_exporter/releases/download/$tag_name/$TAR_NAME"
tar xvfz $TAR_NAME

rm -f $TAR_NAME

# mv node_exporter-1.7.0.linux-amd64/node_exporter to /usr/local/bin
mv node_exporter-${tag_name#v}.linux-${ARCH_NAME}/node_exporter /usr/local/bin
chmod +x /usr/local/bin/node_exporter

chown node_exporter:node_exporter /usr/local/bin/node_exporter
systemctl restart node_exporter