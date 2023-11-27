#! /bin/bash

[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

trap _exit INT QUIT TERM

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

# install python
apt install python3 python3-pip python3-venv -y


# install pdm
curl -sSL https://pdm-project.org/install-pdm.py | python3 -
