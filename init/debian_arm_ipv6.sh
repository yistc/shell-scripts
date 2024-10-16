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

# check if file /etc/ssrust/sslocal.json exists, if not exit and print error
if [ ! -f /etc/ssrust/sslocal ]; then
    echo -e "${RED}Error: /etc/ssrust/sslocal.json not found!${NC}"
    exit 1
fi
# check if file /usr/local/bin/sslocal exists, if not exit and print error
if [ ! -f /usr/local/bin/sslocal ]; then
    echo -e "${RED}Error: /usr/local/bin/sslocal not found!${NC}"
    exit 1
fi

# check if http_proxy env is set
if [ -z "$http_proxy" ]; then
  echo "http_proxy is not set."
  exit 1
else
  echo "http_proxy is set to: $http_proxy"
fi


# ask for server hostname
# if leave blank, do not change
echo -e "${GREEN}Please enter new hostname: (Leave blank to skip)${NC}"
read user_hostname
if [[ -n ${user_hostname} ]]; then
  hostnamectl set-hostname $user_hostname
  echo "127.0.0.1 localhost" > /etc/hosts
  echo "127.0.0.1 $user_hostname" >> /etc/hosts
  echo "$user_hostname" > /etc/hostname
fi

# ipv4 precedence over ipv6
# sed -i 's/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf

# bbr
cat >>/etc/sysctl.conf<<EOF
net.core.default_qdisc = fq_pie
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_rmem = 8192 262144 536870912
net.ipv4.tcp_wmem = 4096 16384 536870912
net.ipv4.tcp_adv_win_scale = -2
net.ipv4.tcp_notsent_lowat = 131072
EOF
sysctl -p

# timedatectl
apt purge ntp -y
apt install systemd-timesyncd -y
systemctl enable systemd-timesyncd --now
timedatectl

# Set timezone
timedatectl set-timezone Asia/Hong_Kong
echo "Asia/Hong_Kong" > /etc/timezone

# some basic packages
apt update -y
apt install curl sudo systemd-timesyncd xz-utils lsb-release ca-certificates dnsutils dpkg mtr-tiny zsh rsync unzip vim ripgrep git gnupg build-essential logrotate python3 resolvconf -y

# Set up ss local proxy

# dns
# sed -i 's/dns-nameservers 8.8.8.8.*/#dns-nameservers 8.8.8.8 1.1.1.1/g' /etc/network/interfaces
# sed -i 's/dns-nameservers 2001:4860:4860::8888.*/#dns-nameservers 2001:4860:4860::8888 2606:4700:4700::1111/g' /etc/network/interfaces

resolvconf -u
# nameserver 8.8.8.8
# nameserver 1.1.1.1
# nameserver 8.8.4.4
# nameserver 2001:4860:4860::8888
# nameserver 2606:4700:4700::1111

# check if /etc/resolv.conf contains each nameserver
# if it does, continue
# if not, add it to /etc/resolvconf/resolv.conf.d/tail

DNS_SERVERS=(
    "8.8.8.8"
    "1.1.1.1"
    "8.8.4.4"
    "2001:4860:4860::8888"
    "2606:4700:4700::1111"
)

for server in "${DNS_SERVERS[@]}"; do
    if grep -q "^nameserver $server" /etc/resolv.conf; then
        echo "Nameserver $server exists in /etc/resolv.conf."
    else
        echo "Nameserver $server missing in /etc/resolv.conf. Adding to /etc/resolvconf/resolv.conf.d/tail."
        echo "nameserver $server" >> /etc/resolvconf/resolv.conf.d/tail
    fi
done

resolvconf -u

# set zsh
chsh -s `which zsh`

mkdir -p /root/.zfunc

# zshrc
curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/init/init_zshrc.sh
bash init_zshrc.sh
rm init_zshrc.sh

# systemd journald
sed -i 's/^#\?Storage=.*/Storage=volatile/' /etc/systemd/journald.conf
sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=8M/' /etc/systemd/journald.conf
sed -i 's/^#\?RuntimeMaxUse=.*/RuntimeMaxUse=8M/' /etc/systemd/journald.conf
systemctl restart systemd-journald

# ssh keys
mkdir -p /root/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0kVbDmjFhOtyoli41xVYMqok5zQNWUkYbdHBvVpAb9 yistc' >> ~/.ssh/authorized_keys

# permit root login and disable password login
curl -o /etc/ssh/sshd_config -L "https://raw.githubusercontent.com/yistc/shell-scripts/main/init/ssh.conf"

service sshd restart

# nftables & iptables & ufw
apt remove --auto-remove nftables -y && apt purge nftables -y
apt update && apt install iptables -y

apt install ufw -y
ufw allow ssh
echo "y" | ufw enable

# install dust
curl -L "https://github.com/bootandy/dust/releases/download/v1.1.1/dust-v1.1.1-aarch64-unknown-linux-gnu.tar.gz" -o dust.tar.gz
tar zxvf dust.tar.gz "dust-v1.1.1-aarch64-unknown-linux-gnu/dust"
mv "dust-v1.1.1-aarch64-unknown-linux-gnu/dust" /usr/local/bin
chmod +x /usr/local/bin/dust
rm -rf dust.tar.gz "dust-v1.1.1-aarch64-unknown-linux-gnu"

# install lsd
curl -L "https://github.com/lsd-rs/lsd/releases/download/v1.1.5/lsd-v1.1.5-aarch64-unknown-linux-gnu.tar.gz" -o lsd.tar.gz
tar zxvf lsd.tar.gz lsd-v1.1.5-aarch64-unknown-linux-gnu/lsd
mv "lsd-v1.1.5-aarch64-unknown-linux-gnu/lsd" /usr/local/bin
chmod +x /usr/local/bin/lsd
rm -rf lsd.tar.gz "lsd-v1.1.5-aarch64-unknown-linux-gnu"

# lsd theme
curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/config/lsd_theme.sh && bash lsd_theme.sh && rm lsd_theme.sh

# install fd, an alternative to `find` written in Rust
curl -L https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-aarch64-unknown-linux-gnu.tar.gz -o fd.tar.gz
tar zxvf fd.tar.gz
mv "fd-v10.2.0-aarch64-unknown-linux-gnu/fd" /usr/local/bin
chmod +x /usr/local/bin/fd
rm -rf fd.tar.gz "fd-v10.2.0-aarch64-unknown-linux-gnu"

# install btop
curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/install/btop.sh && bash btop.sh && rm btop.sh

# install procs
curl -L https://github.com/yistc/shell-scripts/raw/main/bin/procs_aarch64_v0.14 -o /usr/local/bin/procs
chmod +x /usr/local/bin/procs

# starship
curl -L https://github.com/starship/starship/releases/latest/download/starship-aarch64-unknown-linux-musl.tar.gz -o starship.tar.gz
tar zxvf starship.tar.gz
mv starship /usr/local/bin/starship
rm starship.tar.gz

mkdir -p ~/.config && touch ~/.config/starship.toml

cat >>~/.config/starship.toml<<EOF
[hostname]
ssh_symbol=''
EOF

# install zoxide
curl -L https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.6/zoxide-0.9.6-aarch64-unknown-linux-musl.tar.gz -o zoxide.tar.gz
tar zxvf zoxide.tar.gz zoxide
mv zoxide /usr/local/bin
chmod +x /usr/local/bin/zoxide
rm zoxide.tar.gz

# install bat
curl -L https://github.com/sharkdp/bat/releases/download/v0.24.0/bat-v0.24.0-aarch64-unknown-linux-gnu.tar.gz -o bat.tar.gz
tar zxvf bat.tar.gz bat-v0.24.0-aarch64-unknown-linux-gnu/bat
mv bat-v0.24.0-aarch64-unknown-linux-gnu/bat /usr/local/bin
chmod +x /usr/local/bin/bat
rm -rf bat.tar.gz bat-v0.24.0-aarch64-unknown-linux-gnu

echo 'export BAT_THEME="Solarized (light)"' >> ~/.zshrc

# vim config
curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/config/vim.sh && bash vim.sh && rm vim.sh

# locale

# Swap
SWAP=$(free | grep Swap | awk '{print $2}')

if [ "$SWAP" -gt 0 ]; then
    echo "Swap is enabled."
else
    echo -e "${GREEN}Swap is not enabled. Setting up swap ..${NC}"
    fallocate -l 1G /var/swapfile
    chmod 600 /var/swapfile
    mkswap /var/swapfile
    swapon /var/swapfile
    echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab
fi

# rm self
rm -f $0