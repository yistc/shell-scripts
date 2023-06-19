#! /bin/bash

# https://github.com/EAimTY/tuic
# config https://github.com/EAimTY/tuic/blob/dev/tuic-server/README.md

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

# like tuic-server-1.0.0
tag_name=$(curl -s https://api.github.com/repos/EAimTY/tuic/releases/latest | grep tag_name|cut -f4 -d "\"")

if [[ "${ARCH}" == "x86_64" ]]; then
    curl -LO "https://github.com/EAimTY/tuic/releases/download/${tag_name}/${tag_name}-x86_64-unknown-linux-gnu"
    mv "${tag_name}-x86_64-unknown-linux-gnu" /usr/local/bin/tuics
    chmod +x /usr/local/bin/tuics
elif [[ "${ARCH}" == "arm64" || "${ARCH}" == "aarch64" ]]; then
    curl -LO "https://github.com/EAimTY/tuic/releases/download/${tag_name}/${tag_name}-aarch64-unknown-linux-gnu"
    mv "${tag_name}-aarch64-unknown-linux-gnu" /usr/local/bin/tuics
    chmod +x /usr/local/bin/tuics
else
    echo -e "${RED}Error: Unsupported architecture!${NC}"
    exit 1
fi

cat > /lib/systemd/system/tuics.service <<EOF
[Unit]
Description=TUIC PROXY
Documentation=https://github.com/EAimTY/tuic
After=network.target

[Service]
LimitNOFILE=32768
ExecStart=/usr/local/bin/tuics -c /etc/tuic/tuic.json
Restart=on-failure
RestartPreventExitStatus=1
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

# tell user to edit /etc/tuic/tuic.json
mkdir -p /etc/tuic
echo -e "${GREEN}Please provide a valid config file: \n/etc/tuic/tuic.json${NC}"
echo -e "${GREEN}systemctl enable tuics --now${NC}"