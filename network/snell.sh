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
    curl -L https://dl.nssurge.com/snell/snell-server-v5.0.0-linux-amd64.zip -o snell.zip
    unzip snell.zip
    chmod +x snell-server && mv snell-server /usr/local/bin/snell
    rm snell.zip
elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
    curl -L https://dl.nssurge.com/snell/snell-server-v5.0.0-linux-aarch64.zip -o snell.zip
    unzip snell.zip
    chmod +x snell-server && mv snell-server /usr/local/bin/snell
    rm snell.zip
else
    echo "Error: This script only supports x86_64, arm64 and aarch64."
    exit 1
fi

mkdir -p /etc/snell

# psk and port
PSK=$(openssl rand -base64 24 | sed 's/[^a-z  A-Z 0-9]//g')

echo -n "${PURPLE}Enter port for snell:${NC}"
read PORT

cat > /etc/snell/snell.conf <<EOF
[snell-server]
listen = ::0:$PORT
dns = 8.8.8.8, 1.1.1.1, 2001:4860:4860::8888
psk = $PSK
ipv6 = true
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
ExecStart=/usr/local/bin/snell -c /etc/snell/snell.conf
StandardOutput=journal
StandardError=journal
SyslogIdentifier=snell-server
[Install]
WantedBy=multi-user.target
EOF

# cron to restart snell everyday
# crontab -l > mycron
# echo "0 5 * * * systemctl restart snell" >> mycron
# crontab mycron
# rm mycron

systemctl daemon-reload
systemctl enable --now snell
systemctl restart snell
echo "---------------------------------------------"
echo "${RED}Snell PSK: $PSK${NC}"
echo "${RED}Snell Port: $PORT${NC}"
rm -f snell.sh
