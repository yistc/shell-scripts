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

ask_menu() {
    echo -e "
    ${PURPLE}yistc's Shell Script${NC}
    ${PURPLE}This script only works on Ubuntu 20.04 and Debian 10 or above.${NC}
    ${PURPLE}This script assumes you use zsh.${NC}
    ---
    ${GREEN}1.${NC} Install All
    ${GREEN}2.${NC} Install Zinit and some plugins
    ${GREEN}3.${NC} Install Rust
    ${GREEN}4.${NC} Install pyenv and latest CPython
    ${GREEN}5.${NC} Install Docker
    ${GREEN}6.${NC} Sysctl tuning
    "
    echo && echo "Please enter your choice: (Default: 1) "
    
    read num

    case "${num}" in
        1)
            install_all
            ;;
        2)
            install_zinit
            ;;
        3)
            install_rust
            ;;
        4)
            install_pyenv
            ;;
        5)
            install_docker
            ;;
        6)
            sysctl_tuning
            ;;
        *)
            echo -e "${RED}Please enter a correct number${NC}"
            ;;
    esac
}

install_pyenv() {
echo -e "${PURPLE}Installing pyenv and CPython${NC}"

# Install dependencies
apt install -y make build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

git clone https://github.com/pyenv/pyenv.git /usr/local/bin/pyenv

echo 'export PYENV_ROOT="/usr/local/bin/pyenv"' >> ~/.zshrc
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(pyenv init -)"' >> ~/.zshrc

echo 'export PYENV_ROOT="/usr/local/bin/pyenv"' >> ~/.zprofile
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zprofile
echo 'eval "$(pyenv init -)"' >> ~/.zprofile

echo 'export PYENV_ROOT="/usr/local/bin/pyenv"' >> ~/.zlogin
echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zlogin
echo 'eval "$(pyenv init -)"' >> ~/.zlogin

# pyenv virtualenv plugin
git clone https://github.com/pyenv/pyenv-virtualenv.git /usr/local/bin/pyenv/plugins/pyenv-virtualenv
echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc

# pyenv update plugin
git clone https://github.com/pyenv/pyenv-update.git /usr/local/bin/pyenv/plugins/pyenv-update

export PYENV_ROOT="/usr/local/bin/pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
}

install_rust() {
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

install_zinit() {
echo -e '${PURPLE}Installing Zinit...${NC}'

git clone https://github.com/zdharma-continuum/zinit.git /root/.local/share/zinit/zinit.git
echo 'source "/root/.local/share/zinit/zinit.git/zinit.zsh"' >> ~/.zshrc
echo 'zinit light zsh-users/zsh-autosuggestions' >> ~/.zshrc
echo 'zinit light zdharma/fast-syntax-highlighting' >> ~/.zshrc
echo 'zinit load zdharma/history-search-multi-word' >> ~/.zshrc
echo 'zinit snippet OMZ::plugins/git/git.plugin.zsh' >> ~/.zshrc

echo -e '${PURPLE}Plugins installed:${NC}'
echo '  zsh-autosuggestions'
echo '  fast-syntax-highlighting'
echo '  history-search-multi-word'
echo '  git'
}

install_docker() {
curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/install/docker.sh && bash docker.sh
rm -f docker.sh
}

sysctl_tuning() {
    # for vscode
    echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
    sysctl -p
}

install_all() {
    install_zinit
    install_rust
    install_pyenv
    install_docker
    sysctl_tuning
}

ask_menu