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

tag_name=$(curl -s https://api.github.com/repos/ihciah/shadow-tls/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO https://github.com/ihciah/shadow-tls/releases/download/v0.2.23/shadow-tls-x86_64-unknown-linux-musl
mv shadow-tls-x86_64-unknown-linux-musl /usr/local/bin/stls
chmod +x /usr/local/bin/stls

PASS=$(openssl rand -base64 32 | sed 's/[^a-z  A-Z 0-9]//g')
echo -ne "${PURPLE}Enter port for snell:${NC}"
read SNELL_PORT

echo -ne "${PURPLE}Enter proxy port:${NC}"
read PROXY_PORT

cat > /etc/systemd/system/stls.service << EOF
[Unit]
Description=Shadow-TLS Server Service
Documentation=man:sstls-server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/stls --fastopen --v3 server --listen 0.0.0.0:$PROXY_PORT --server 127.0.0.1:$SNELL_PORT --tls gateway.icloud.com --password $PASS
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=stls

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable stls --now

echo -e "${GREEN}Password: $PASS${NC}"
rm -f stls.sh