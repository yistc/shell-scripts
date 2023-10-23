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

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

example_conf() {
cat >> /etc/nginx/conf.d/example <<EOF
server {
    listen 80;
    server_name your.domain.com;
    return 301 https://your.domain.com\$request_uri;
}

server {
    listen 127.0.0.1:10001 ssl http2;

    ssl_certificate /etc/nginx/certs/your.domain.cer;
    ssl_certificate_key /etc/nginx/certs/your.domain.key;
    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
    ssl_session_tickets off;
    
    client_max_body_size 2G;

    ssl_dhparam /etc/nginx/dhparam.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    ssl_stapling on;
    ssl_stapling_verify on;

    resolver 8.8.8.8 1.1.1.1 8.8.4.4 valid=600s;
    resolver_timeout 10s;
    
    location / {
        proxy_pass http://127.0.0.1:8000;

        # websocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";

        proxy_set_header Host \$http_host;

        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_set_header X-Real-IP \$remote_addr;

        # timeout
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
    	proxy_read_timeout 300;
    	send_timeout 300;

        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    }

}
EOF
}

default_conf() {
cat >/etc/nginx/conf.d/default.conf<<EOF
server {
    listen 80 default;
    server_name _;
    return 444; # or 500
}
EOF
}

ubuntu_install() {
    release=$(lsb_release -cs)
    curl -fSsL https://nginx.org/keys/nginx_signing.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    # verify
    gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
    # stable version
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list

    # prefer nginx from nginx.org
    echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" | sudo tee /etc/apt/preferences.d/99nginx

    apt update -y
    apt install nginx -y

    cat >> /etc/nginx/nginx.conf <<EOF
stream {
    map \$ssl_preread_server_name \$name {
        1.your.domain service1;
    }
    upstream service1 {
        server 127.0.0.1:10001;
    }

    server {
        listen 443 reuseport;
        proxy_pass      \$name;
        ssl_preread on;               # enalbe ssl_preread
    }
}
EOF

# example
example_conf
default_conf
}