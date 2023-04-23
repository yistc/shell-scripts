#!/bin/bash

# run as root
if [ $EUID -ne 0 ]; then
    echo "此脚本需要以 root 身份运行"
    exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE="\033[34m"
PURPLE="\033[35m"
BOLD="\033[1m"
NC='\033[0m'

Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
Tips="${Green_font}[Tips]${Font_suffix}"

GITPROXY='https://ghproxy.com'

# check linux release
# 通过 /etc/os-release 文件判断发行版
if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [[ $ID = "debian" || $ID_LIKE = "debian" ]]; then
        distro_name="debian"
    elif [[ $ID = "ubuntu" || $ID_LIKE = "ubuntu" ]]; then
        distro_name="ubuntu"
    elif [[ $ID = "centos" || $ID_LIKE =~ "centos fedora" ]]; then
        distro_name="centos"
    else
        distro_name="unknown"
    fi
# 通过 /etc/*-release 文件判断发行版
elif [ -f /etc/centos-release ]; then
    distro_name="centos"
elif [ -f /etc/redhat-release ]; then
    distro_name="redhat"
elif [ -f /etc/fedora-release ]; then
    distro_name="fedora"
elif [ -f /etc/debian_version ]; then
    distro_name="debian"
elif [ -f /etc/lsb-release ]; then
    distro_name="ubuntu"
else
    distro_name="unknown"
fi

echo "当前发行版为 $distro_name"

# 获取系统架构信息
ARCH=$(uname -m)

# 检查系统架构类型
if [[ "$ARCH" == "x86_64" ]]; then
    message="当前系统为 AMD64 架构"
elif [[ "$ARCH" == "aarch64" ]]; then
    message="当前系统为 AArch64 架构"
else
    message="unknown arch"
fi

echo $message

function debian_amd64 {
    debian_version=$(grep -oP 'VERSION_ID=\K\w+' /etc/os-release)
    if [ "$debian_version" -lt 10 ]; then
        echo "该脚本不适用于 Debian 10 版本以下的系统"
        exit 1

    # ipv4 precedence over ipv6
    sed -i 's/#precedence ::ffff:0:0\/96  100/precedence ::ffff:0:0\/96  100/' /etc/gai.conf

    # bbr
    cat >>/etc/sysctl.conf<<EOF
    net.core.default_qdisc = fq_pie
    net.ipv4.tcp_congestion_control = bbr
    net.ipv4.tcp_rmem = 8192 262144 536870912
    net.ipv4.tcp_wmem = 4096 16384 536870912
    net.ipv4.tcp_adv_win_scale = -2
    # net.ipv4.tcp_collapse_max_bytes = 6291456
    net.ipv4.tcp_notsent_lowat = 131072
    EOF
    sysctl -p

    # ntp
    apt purge ntp -y
    apt install systemd-timesyncd -y
    systemctl enable systemd-timesyncd --now
    timedatectl

    # # change hostname
    # echo -n "Enter hostname:"
    # read hostname
    # hostnamectl set-hostname $hostname
    # echo "127.0.0.1 localhost" > /etc/hosts
    # echo "127.0.0.1 $hostname" >> /etc/hosts

    apt update -y
    apt install sudo net-tools xz-utils lsb-release ca-certificates dnsutils dpkg mtr-tiny iperf3 pwgen zsh unzip vim ripgrep git -y

    # timezone
    timedatectl set-timezone Asia/Hong_Kong

    # systemd journal
    sed -i 's/^#\?Storage=.*/Storage=volatile/' /etc/systemd/journald.conf
    sed -i 's/^#\?SystemMaxUse=.*/SystemMaxUse=8M/' /etc/systemd/journald.conf
    sed -i 's/^#\?RuntimeMaxUse=.*/RuntimeMaxUse=8M/' /etc/systemd/journald.conf
    systemctl restart systemd-journald

    # ssh & key
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config;

    cd ~ && mkdir -p .ssh && echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP0kVbDmjFhOtyoli41xVYMqok5zQNWUkYbdHBvVpAb9 yistc' >> ~/.ssh/authorized_keys
    # servercat_key
    echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICJ+sdnCybIStkqj/lNE8LLu5EPtUwRHmMquMLJgT6RP' >> ~/.ssh/authorized_keys
    service sshd restart

    # nftables & iptables & ufw
    apt remove --auto-remove nftables -y && apt purge nftables -y
    apt update && apt install iptables -y

    chsh -s `which zsh`

    mkdir -p /root/.zfunc

    cat >> ~/.zshrc << 'EOFF'
    # cd
    alias ..='cd ..'
    alias ...='cd ../..'
    alias ....='cd ../../..'
    alias .....='cd ../../../..'
    # git
    alias git-all='gaa && gcam "1" && gp'
    # lsd
    alias ls='lsd'
    alias lsl='lsd -lF'
    alias lsal='lsd -alF'
    alias la='lsd -a'
    alias ll='lsd -lh'
    alias lr='lsd -lR'
    # procs
    alias ps='procs'
    alias psmem='procs --sortd mem'
    alias pscpu='procs --sortd cpu'
    # systemctl
    alias sc='systemctl'
    alias sce='systemctl enable --now'
    alias scr='systemctl restart'
    alias scs='systemctl stop'
    # abbr
    alias dc='docker-compose'
    alias myipa='curl -s http://checkip.amazonaws.com/'
    alias tma='tmux attach -t'
    alias tmn='tmux new -s'
    alias tmk='tmux kill-session -t'
    alias x='extract'
    alias z='__zoxide_z'
    alias sst='ss -tnlp'
    alias ssu='ss -unlp'
    alias sstg='ss -tnlp | grep'
    alias cronlog='grep CRON /var/log/syslog'
    alias curlo='curl -LO'
    alias pip='noglob pip'
    # zoxide
    eval "$(zoxide init --no-cmd zsh)"
    # starship
    eval "$(starship init zsh)"
    # self-defined functions
    fpath=( ~/.zfunc "${fpath[@]}" )
    autoload -Uz extract
    EOFF

    # apt install ufw -y
    # ufw default allow incoming
    # ufw default allow routed
    # yes | ufw enable

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

    # install dust
    wget https://github.com/bootandy/dust/releases/download/v0.8.1/dust-v0.8.1-x86_64-unknown-linux-gnu.tar.gz
    tar zxvf dust-v0.8.1-x86_64-unknown-linux-gnu.tar.gz
    mv dust-v0.8.1-x86_64-unknown-linux-gnu/dust /usr/local/bin
    rm -rf dust-v0.8.1-x86_64-unknown-linux-gnu dust-v0.8.1-x86_64-unknown-linux-gnu.tar.gz

    # install lsd
    wget https://github.com/Peltoche/lsd/releases/download/0.23.1/lsd-0.23.1-x86_64-unknown-linux-gnu.tar.gz
    tar zxvf lsd-0.23.1-x86_64-unknown-linux-gnu.tar.gz
    mv lsd-0.23.1-x86_64-unknown-linux-gnu/lsd /usr/local/bin
    rm -rf lsd-0.23.1-x86_64-unknown-linux-gnu lsd-0.23.1-x86_64-unknown-linux-gnu.tar.gz

    # lsd theme
    wget https://gist.githubusercontent.com/yistc/de5b8c0f9fc5536d528ccfa75c9b9328/raw/lsd_theme.sh
    bash lsd_theme.sh
    rm lsd_theme.sh

    # install procs, an alternative to `ps` written in Rust
    wget https://github.com/dalance/procs/releases/download/v0.13.3/procs-v0.13.3-x86_64-linux.zip
    unzip procs-v0.13.3-x86_64-linux.zip
    mv procs /usr/local/bin/procs
    rm procs-v0.13.3-x86_64-linux.zip

    # install sd
    wget -O /usr/local/bin/sd https://github.com/chmln/sd/releases/download/v0.7.6/sd-v0.7.6-x86_64-unknown-linux-gnu
    chmod +x /usr/local/bin/sd

    # install bottom
    wget https://gist.githubusercontent.com/yistc/de5b8c0f9fc5536d528ccfa75c9b9328/raw/bottom.sh
    bash bottom.sh
    rm bottom.sh

    # install xh, alternative to httpie
    # wget https://github.com/ducaale/xh/releases/download/v0.16.1/xh-v0.16.1-x86_64-unknown-linux-musl.tar.gz
    # tar zxvf xh-v0.16.1-x86_64-unknown-linux-musl.tar.gz
    # mv xh-v0.16.1-x86_64-unknown-linux-musl/xh /usr/local/bin/xh
    # rm -rf xh-v0.16.1-x86_64-unknown-linux-musl.tar.gz xh-v0.16.1-x86_64-unknown-linux-musl

    # starship
    wget https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz
    tar zxvf starship-x86_64-unknown-linux-gnu.tar.gz
    mv starship /usr/local/bin/starship
    rm starship-x86_64-unknown-linux-gnu.tar.gz

    # install zoxide
    wget https://github.com/ajeetdsouza/zoxide/releases/download/v0.8.3/zoxide-0.8.3-x86_64-unknown-linux-musl.tar.gz
    tar zxvf zoxide-0.8.3-x86_64-unknown-linux-musl.tar.gz zoxide
    mv zoxide /usr/local/bin/zoxide
    rm zoxide-0.8.3-x86_64-unknown-linux-musl.tar.gz

    # install croc
    wget https://github.com/schollz/croc/releases/download/v9.6.1/croc_9.6.1_Linux-64bit.tar.gz
    tar zxvf croc_9.6.1_Linux-64bit.tar.gz croc
    mv croc /usr/local/bin/croc
    rm croc_9.6.1_Linux-64bit.tar.gz

    # vim config
    wget https://gist.githubusercontent.com/yistc/de5b8c0f9fc5536d528ccfa75c9b9328/raw/vim.sh
    bash vim.sh
    rm vim.sh

    # change locale to en_US.utf8
    sd "# en_US.UTF-8 UTF-8" "en_US.UTF-8 UTF-8" /etc/locale.gen
    locale-gen
    sd 'LANG="en_US"' 'LANG="en_US.utf8"' /etc/default/locale
}
