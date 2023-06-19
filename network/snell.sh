#! /bin/bash
# https://manual.nssurge.com/others/snell.html

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

ARCH=$(uname -m) # x86_64, arm64, aarch64

if [[ "$ARCH" == "x86_64" ]]; then
    curl -LO https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-amd64.zip
    unzip snell-server-v4.0.1-linux-amd64.zip
    chmod +x snell-server && mv snell-server /usr/local/bin/snell
    rm snell-server-v4.0.1-linux-amd64.zip

elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    curl -LO https://dl.nssurge.com/snell/snell-server-v4.0.1-linux-aarch64.zip
    unzip snell-server-v4.0.1-linux-aarch64.zip
    chmod +x snell-server && mv snell-server /usr/local/bin/snell
    rm snell-server-v4.0.1-linux-aarch64.zip
else
    echo "Error: This script only supports x86_64, arm64 and aarch64."
    exit 1
fi

mkdir -p /etc/snell

# psk and port
PSK=$(openssl rand -base64 32 | sed 's/[^a-z  A-Z 0-9]//g')

echo -n "${PURPLE}Enter port for snell:${NC}"
read PORT

cat > /etc/snell/snell.conf <<EOF
[snell-server]
listen = 0.0.0.0:$PORT
psk = $PSK
ipv6 = false
EOF

cat > /lib/systemd/system/snell.service << EOF
[Unit]
Description=Snell Proxy Service
After=network.target
[Service]
Type=simple
User=root
LimitNOFILE=102400
LimitNPROC=102400
LimitAS=infinity
LimitCORE=infinity
ExecStart=/usr/local/bin/snell -c /etc/snell/snell.conf
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=snell-server
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now snell
systemctl restart snell
echo "---------------------------------------------"
echo "${RED}Snell PSK: $PSK${NC}"
echo "${RED}Snell Port: $PORT${NC}"
rm -f snell.sh