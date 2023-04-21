#! /usr/bin/zsh

# Features
# 1. DD install system
# 2. init debian / ubuntu system
# 3. Install programs
    # 1. Install snell
    # 2. Install docker & docker-compose
    # 3. Install nginx
    # 4. Debian upgrade
    # 5. Install pyenv & python version
    # 6. Install rust
    # 7. Install rclone
    # 8. Install Redis
# 4. Port Forward
    # 1. nginx
    # 2. realm
    # 3. gost
    # 4. iptables
# 5. System Bench
    # 1. Basic Info
    # 2. Disk IO (Optional)
    # 3. CPU Benchmark with Geekbench 5 (Optional)
    # 4. Ping Test (Optional)
    # 5. Speedtest (Optional)
    # 6. Or just run YABS & bench.sh
    # 7. Media unblock check
    # 8. 
# 6. Wireguard Installation
# 7. 

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Check if root
if [ "$EUID" -ne 0 ]1
  then echo -e "${RED}Please run as root${NC}"
  exit
fi

# Variables
export ipAddr=''
export ip6Addr=''
export linux_relese=''

# read arguments with while
while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Usage: yistc.sh [options]"
            echo "Options:"
            echo "  -h, --help            show brief help"
            echo "  -i, --ip              set ip address"
            echo "  -6, --ip6             set ip6 address"
            exit 0
            ;;
        -i|--ip)
            shift
            if test $# -gt 0; then
                export ipAddr=$1
            else
                echo "no ip specified"
                exit 1
            fi
            shift
            ;;
        -6|--ip6)
            shift
            if test $# -gt 0; then
                export ip6Addr=$1
            else
                echo "no ip6 specified"
                exit 1
            fi
            shift
            ;;
        *)

# if no arguments specified, show usage and waiting for input
if [ $# -eq 0 ]; then
    echo "Usage: yistc.sh [options]"
    echo "Options:"
    echo "  -h, --help            show brief help"
    echo "  -i, --ip              set ip address"
    echo "  -6, --ip6             set ip6 address"
    exit 0
fi

# OS
OS=$(uname -s) # Linux, FreeBSD, Darwin
ARCH=$(uname -m) # x86_64, arm64, aarch64
DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )
debug=$( [[ $OS == "Darwin" ]] && echo true || echo false )
cnd=$( tr '[:upper:]' '[:lower:]' <<<"$1" )
GITPROXY='https://ghproxy.com'