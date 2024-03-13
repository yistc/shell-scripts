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
sed -i 's/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf

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

# some basic packages
apt update -y
apt install sudo curl wget systemd-timesyncd xz-utils lsb-release ca-certificates dnsutils dpkg mtr-tiny zsh rsync zip unzip vim ripgrep git gnupg build-essential logrotate python3 resolvconf -y

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

# Set timezone
timedatectl set-timezone Asia/Hong_Kong
echo "Asia/Hong_Kong" > /etc/timezone

sed -i 's/^#\?Storage=.*/Storage=volatile/' /etc/systemd/journald.conf
sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=8M/' /etc/systemd/journald.conf
sed -i 's/^#\?RuntimeMaxUse=.*/RuntimeMaxUse=8M/' /etc/systemd/journald.conf
systemctl restart systemd-journald

# ssh keys
mkdir -p /root/.ssh
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0kVbDmjFhOtyoli41xVYMqok5zQNWUkYbdHBvVpAb9 yistc' >> ~/.ssh/authorized_keys
# servercat key
echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICJ+sdnCybIStkqj/lNE8LLu5EPtUwRHmMquMLJgT6RP' >> ~/.ssh/authorized_keys

# permit root login and disable password login
# sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
# sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config;
curl -o /etc/ssh/sshd_config -L "https://raw.githubusercontent.com/yistc/shell-scripts/main/init/ssh.conf"
service sshd restart

# nftables & iptables & ufw
apt remove --auto-remove nftables -y && apt purge nftables -y
apt update && apt install iptables -y

apt install ufw -y
ufw allow ssh
echo "y" | ufw enable

# install dust
tag_name=$(curl -s https://api.github.com/repos/bootandy/dust/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/bootandy/dust/releases/download/$tag_name/dust-$tag_name-x86_64-unknown-linux-gnu.tar.gz"
tar zxvf "dust-$tag_name-x86_64-unknown-linux-gnu.tar.gz" "dust-$tag_name-x86_64-unknown-linux-gnu/dust"
mv "dust-$tag_name-x86_64-unknown-linux-gnu/dust" /usr/local/bin
chmod +x /usr/local/bin/dust
rm -rf "dust-$tag_name-x86_64-unknown-linux-gnu.tar.gz" "dust-$tag_name-x86_64-unknown-linux-gnu"

# install lsd
tag_name=$(curl -s https://api.github.com/repos/lsd-rs/lsd/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/lsd-rs/lsd/releases/download/$tag_name/lsd-$tag_name-x86_64-unknown-linux-gnu.tar.gz"
tar zxvf "lsd-$tag_name-x86_64-unknown-linux-gnu.tar.gz"
mv "lsd-$tag_name-x86_64-unknown-linux-gnu/lsd" /usr/local/bin
chmod +x /usr/local/bin/lsd
rm -rf "lsd-$tag_name-x86_64-unknown-linux-gnu.tar.gz" "lsd-$tag_name-x86_64-unknown-linux-gnu"

# lsd theme
curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/config/lsd_theme.sh
bash lsd_theme.sh
rm lsd_theme.sh

# install fd, an alternative to `find` written in Rust
tag_name=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/sharkdp/fd/releases/download/$tag_name/fd-$tag_name-x86_64-unknown-linux-gnu.tar.gz"
tar zxvf "fd-$tag_name-x86_64-unknown-linux-gnu.tar.gz"
mv "fd-$tag_name-x86_64-unknown-linux-gnu/fd" /usr/local/bin
chmod +x /usr/local/bin/fd
rm -rf "fd-$tag_name-x86_64-unknown-linux-gnu.tar.gz" "fd-$tag_name-x86_64-unknown-linux-gnu"

# install bottom
curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/install/bottom.sh
bash bottom.sh
rm bottom.sh

# install procs
tag_name=$(curl -s https://api.github.com/repos/dalance/procs/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/dalance/procs/releases/download/${tag_name}/procs-${tag_name}-x86_64-linux.zip"
unzip "procs-${tag_name}-x86_64-linux.zip"
chmod +x procs
mv procs /usr/local/bin
rm -rf "procs-${tag_name}-x86_64-linux.zip"

# starship
curl -LO https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz
tar zxvf starship-x86_64-unknown-linux-gnu.tar.gz
mv starship /usr/local/bin/starship
rm starship-x86_64-unknown-linux-gnu.tar.gz


mkdir -p ~/.config && touch ~/.config/starship.toml

cat >>~/.config/starship.toml<<EOF
[hostname]
ssh_symbol=''
EOF


# install zoxide
tag_name=$(curl -s https://api.github.com/repos/ajeetdsouza/zoxide/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/ajeetdsouza/zoxide/releases/download/$tag_name/zoxide_${tag_name#v}-1_amd64.deb"
dpkg -i "zoxide_${tag_name#v}-1_amd64.deb"
rm "zoxide_${tag_name#v}-1_amd64.deb"

# install bat
tag_name=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/sharkdp/bat/releases/download/${tag_name}/bat_${tag_name#v}_amd64.deb"
dpkg -i "bat_${tag_name#v}_amd64.deb"
rm -f "bat_${tag_name#v}_amd64.deb"

echo 'export BAT_THEME="Solarized (light)"' >> ~/.zshrc

# vim config
curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/config/vim.sh
bash vim.sh
rm vim.sh

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

# clean up
rm init.sh
rm -f $0