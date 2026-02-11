#! /bin/bash

[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

# Reference: https://github.com/Paul-Reed/cloudflare-ufw
for cfip in `curl -sw '\n' https://www.cloudflare.com/ips-v{4,6}`; do ufw allow from $cfip comment 'Cloudflare IP'; done

ufw reload
