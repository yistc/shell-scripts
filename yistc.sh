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

# Variables
OS=$(uname -s) # Linux, FreeBSD, Darwin
ARCH=$(uname -m) # x86_64, arm64, aarch64
DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )
debug=$( [[ $OS == "Darwin" ]] && echo true || echo false )
cnd=$( tr '[:upper:]' '[:lower:]' <<<"$1" )
GITPROXY='https://ghproxy.com'

# Check if root
if [ "$EUID" -ne 0 ]
  then echo -e "${RED}Please run as root${NC}"
  exit
fi

show_menu() {
    echo -e "
    ${GREEN}yistc's Shell Script${NC} ${RED}${NZ_VERSION}${NC}
    --- https://github.com/yistc/shell-scripts ---
    ${GREEN}1.${NC}  Install Things
    ${GREEN}2.${NC}  Initialize Server
    ${GREEN}3.${NC}  Port Forward
    ${GREEN}4.${NC}  System Bench
    ————————————————-
    ${GREEN}5.${NC}  Update this script
    ————————————————-
    ${GREEN}0.${NC}  Exit
    "
    echo && read -ep "请输入选择 [0-13]: " num
    
    case "${num}" in
        0)
            exit 0
        ;;
        1)
            install_dashboard
        ;;
        2)
            modify_dashboard_config
        ;;
        3)
            start_dashboard
        ;;
        4)
            stop_dashboard
        ;;
        5)
            restart_and_update
        ;;
        6)
            show_dashboard_log
        ;;
        7)
            uninstall_dashboard
        ;;
        8)
            install_agent
        ;;
        9)
            modify_agent_config
        ;;
        10)
            show_agent_log
        ;;
        11)
            uninstall_agent
        ;;
        12)
            restart_agent
        ;;
        13)
            update_script
        ;;
        *)
            echo -e "${RED}请输入正确的数字 [0-13]${NC}"
        ;;
    esac
}