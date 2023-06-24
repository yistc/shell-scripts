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
read hostname
if [[ -n ${hostname} ]]; then
    hostnamectl set-hostname $hostname
    echo "127.0.0.1 localhost" > /etc/hosts
    echo "127.0.0.1 $hostname" >> /etc/hosts
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
apt install sudo net-tools rsync xz-utils lsb-release ca-certificates dnsutils dpkg mtr-tiny iperf3 pwgen zsh unzip vim ripgrep git -y

# set zsh
chsh -s `which zsh`

mkdir -p /root/.zfunc

# aliases
cat >> ~/.zshrc << 'EOFF'
# cd
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
# lsd
alias ls='lsd'
alias lsl='lsd -lF'
alias lsal='lsd -alF'
alias la='lsd -a'
alias ll='lsd -lh'
alias lr='lsd -lR'

# ps
alias psmem='ps aux --sort=-%mem'
alias pscpu='ps aux --sort=-%cpu'

# systemctl
alias sc='systemctl'
alias sce='systemctl enable --now'
alias scr='systemctl restart'
alias scs='systemctl stop'
# abbr
alias dc='docker-compose'
alias myip='curl -s http://checkip.amazonaws.com/'
alias tma='tmux attach -t'
alias tmn='tmux new -s'
alias tmk='tmux kill-session -t'
alias x='extract'
alias z='__zoxide_z'
alias sst='ss -tnlp'
alias ssu='ss -unlp'
alias sstg='ss -tnlp | grep'
alias cronlog='grep CRON /var/log/syslog'
alias pip='noglob pip'
# zoxide
eval "$(zoxide init --no-cmd zsh)"
# starship
eval "$(starship init zsh)"
# self-defined functions
fpath=( ~/.zfunc "${fpath[@]}" )
autoload -Uz extract
EOFF

# extract function
cat >> /root/.zfunc/extract << 'EOFF'
extract() {
  setopt localoptions noautopushd
  if (( $# == 0 )); then
    cat >&2 <<'EOF'
Usage: extract [-option] [file ...]
Options:
    -r, --remove    Remove archive after unpacking.
EOF
  fi
  local remove_archive=1
  if [[ "$1" == "-r" ]] || [[ "$1" == "--remove" ]]; then
    remove_archive=0
    shift
  fi
  local pwd="$PWD"
  while (( $# > 0 )); do
    if [[ ! -f "$1" ]]; then
      echo "extract: '$1' is not a valid file" >&2
      shift
      continue
    fi
    local success=0
    local extract_dir="${1:t:r}"
    local file="$1" full_path="${1:A}"
    case "${file:l}" in
      (*.tar.gz|*.tgz) (( $+commands[pigz] )) && { pigz -dc "$file" | tar xv } || tar zxvf "$file" ;;
      (*.tar.bz2|*.tbz|*.tbz2) tar xvjf "$file" ;;
      (*.tar.xz|*.txz)
        tar --xz --help &> /dev/null \
        && tar --xz -xvf "$file" \
        || xzcat "$file" | tar xvf - ;;
      (*.tar.zma|*.tlz)
        tar --lzma --help &> /dev/null \
        && tar --lzma -xvf "$file" \
        || lzcat "$file" | tar xvf - ;;
      (*.tar.zst|*.tzst)
        tar --zstd --help &> /dev/null \
        && tar --zstd -xvf "$file" \
        || zstdcat "$file" | tar xvf - ;;
      (*.tar) tar xvf "$file" ;;
      (*.tar.lz) (( $+commands[lzip] )) && tar xvf "$file" ;;
      (*.tar.lz4) lz4 -c -d "$file" | tar xvf - ;;
      (*.tar.lrz) (( $+commands[lrzuntar] )) && lrzuntar "$file" ;;
      (*.gz) (( $+commands[pigz] )) && pigz -dk "$file" || gunzip -k "$file" ;;
      (*.bz2) bunzip2 "$file" ;;
      (*.xz) unxz "$file" ;;
      (*.lrz) (( $+commands[lrunzip] )) && lrunzip "$file" ;;
      (*.lz4) lz4 -d "$file" ;;
      (*.lzma) unlzma "$file" ;;
      (*.z) uncompress "$file" ;;
      (*.zip|*.war|*.jar|*.ear|*.sublime-package|*.ipa|*.ipsw|*.xpi|*.apk|*.aar|*.whl) unzip "$file" -d "$extract_dir" ;;
      (*.rar) unrar x -ad "$file" ;;
      (*.rpm)
        command mkdir -p "$extract_dir" && builtin cd -q "$extract_dir" \
        && rpm2cpio "$full_path" | cpio --quiet -id ;;
      (*.7z) 7za x "$file" ;;
      (*.deb)
        command mkdir -p "$extract_dir/control" "$extract_dir/data"
        builtin cd -q "$extract_dir"; ar vx "$full_path" > /dev/null
        builtin cd -q control; extract ../control.tar.*
        builtin cd -q ../data; extract ../data.tar.*
        builtin cd -q ..; command rm *.tar.* debian-binary ;;
      (*.zst) unzstd "$file" ;;
      (*.cab) cabextract -d "$extract_dir" "$file" ;;
      (*.cpio) cpio -idmvF "$file" ;;
      (*)
        echo "extract: '$file' cannot be extracted" >&2
        success=1 ;;
    esac
    (( success = success > 0 ? success : $? ))
    (( success == 0 && remove_archive == 0 )) && rm "$full_path"
    shift
    # Go back to original working directory in case we ran cd previously
    builtin cd -q "$pwd"
  done
}
EOFF

# Set timezone
timedatectl set-timezone Asia/Hong_Kong

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
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config;
service sshd restart

# nftables & iptables & ufw
apt remove --auto-remove nftables -y && apt purge nftables -y
apt install iptables -y

# install dust
tag_name=$(curl -s https://api.github.com/repos/bootandy/dust/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/bootandy/dust/releases/download/$tag_name/dust-$tag_name-aarch64-unknown-linux-gnu.tar.gz"
tar zxvf "dust-$tag_name-aarch64-unknown-linux-gnu.tar.gz" "dust-$tag_name-aarch64-unknown-linux-gnu/dust"
mv "dust-$tag_name-aarch64-unknown-linux-gnu/dust" /usr/local/bin
chmod +x /usr/local/bin/dust
rm -rf "dust-$tag_name-aarch64-unknown-linux-gnu.tar.gz" "dust-$tag_name-aarch64-unknown-linux-gnu"