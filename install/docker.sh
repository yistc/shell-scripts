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

# uninstall previous versions
apt remove docker docker-doc podman-docker docker-engine docker.io containerd runc

apt update -y
apt install -y apt-transport-https ca-certificates gnupg lsb-release

debian_install() {
apt remove docker docker-engine docker.io containerd runc

apt update -y
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y
apt install docker-ce docker-ce-cli containerd.io -y
docker -v

curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
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
}

ubuntu_install() {
    apt remove docker docker-doc podman-docker docker-engine docker.io containerd runc
    apt install ca-certificates curl gnupg -y

    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  apt update -y

  apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin -y

  curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose
  docker-compose -v

  # limiting log size
  cat >/etc/docker/daemon.json << EOF
  {
    "log-driver": "json-file",
    "log-opts": {
      "max-size": "5m"
    }
  }
EOF

  systemctl restart docker
}

# install docker
# if centos, warn user and exit 1

if [[ $DISTRO == 'CentOS' ]]; then
    echo -e "${RED}CentOS is not supported!${NC}"
    exit 1
elif [[ $DISTRO == 'Debian' ]]; then
    debian_install
elif [[ $DISTRO == 'Ubuntu' ]]; then
    ubuntu_install
else
    echo -e "${RED}Unknown distro!${NC}"
    exit 1
fi

rm docker.sh