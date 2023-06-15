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
GITPROXY='https://ghproxy.com'

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

mkdir -p /usr/local/bin

curl -L -o /usr/local/bin/qbittorrent-nox https://github.com/userdocs/qbittorrent-nox-static/releases/latest/download/x86_64-qbittorrent-nox

chmod 700 /usr/local/bin/qbittorrent-nox

# ask user which port to use
read -p "Enter port number for qBittorrent-nox: " port

# ask user the save path
read -p "Enter save path for qBittorrent-nox: " savepath

cat > /etc/systemd/system/qbt.service << EOF
[Unit]
Description=qBittorrent-nox service
Wants=network-online.target
After=network-online.target nss-lookup.target

[Service]
Type=exec
User=root
ExecStart=/usr/local/bin/qbittorrent-nox --webui-port=$port --save-path=$savepath
Restart=on-failure
SyslogIdentifier=qbittorrent-nox

[Install]
WantedBy=multi-user.target
EOF

# tell user the systemd file path
echo -e "${GREEN}Systemd file path: /etc/systemd/system/qbt.service${NC}"

systemctl daemon-reload
systemctl enable qbt --now