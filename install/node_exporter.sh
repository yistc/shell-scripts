#!/bin/bash
set -Eeuo pipefail

TMP=""
trap '[[ -n "$TMP" ]] && rm -rf -- "$TMP"' EXIT
trap _exit INT QUIT TERM
[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

OS=$(uname -s)
ARCH=$(uname -m)

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

is_valid_ipv4() {
    local ip=$1
    local octet
    local -a octets

    IFS=. read -r -a octets <<< "$ip"
    [[ ${#octets[@]} -eq 4 ]] || return 1
    for octet in "${octets[@]}"; do
        [[ "$octet" =~ ^[0-9]{1,3}$ ]] || return 1
        (( 10#$octet <= 255 )) || return 1
    done
}

while getopts s: opt; do
    case $opt in
        s)
            monitor_ip=$OPTARG
            ;;
        :)
            echo "Option -$OPTARG requires an argument" >&2
            exit 1
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done
shift $((OPTIND - 1))

monitor_ip=${monitor_ip:-}
if [[ -n "$monitor_ip" ]] && ! is_valid_ipv4 "$monitor_ip"; then
    echo "Invalid monitor IPv4 address: $monitor_ip" >&2
    exit 1
fi

if [[ "$OS" != "Linux" ]] || [[ ! -r /etc/os-release ]]; then
    echo "Error: this script supports Debian/Ubuntu Linux only" >&2
    exit 1
fi
. /etc/os-release
if [[ "${ID:-}" != "debian" && "${ID:-}" != "ubuntu" ]]; then
    echo "Error: unsupported distribution: ${ID:-unknown}" >&2
    exit 1
fi
command -v systemctl >/dev/null || {
    echo "Error: systemd is required" >&2
    exit 1
}

IS_VM_SERVER=0
if command -v docker >/dev/null && docker ps --format '{{.Image}} {{.Names}}' 2>/dev/null | grep -Eiq 'victoria[-_]metrics|victoriametrics'; then
    IS_VM_SERVER=1
    echo -e "${BLUE}VictoriaMetrics Docker detected: skip ufw configuration${NC}"
fi

if [[ "$IS_VM_SERVER" == 1 || -n "$monitor_ip" ]] && ! command -v ufw >/dev/null; then
    echo "Error: ufw is required to configure node_exporter access" >&2
    exit 1
fi

BIN=/usr/local/bin/node_exporter
UNIT=/etc/systemd/system/node_exporter.service
TEXTFILE_DIR=/var/lib/node_exporter/textfile
CHANGED=0
BINARY_ACTION="not changed"
USER_ACTION="already existed"
UNIT_ACTION="unchanged"
SERVICE_ACTION="not started"
FIREWALL_ACTION="not configured"

# ---------- 目标版本（GitHub latest） ----------
tag_name=$(curl -fsSL https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -f4 -d "\"")
[[ -z "$tag_name" ]] && { echo -e "${RED}Failed to fetch latest tag${NC}"; exit 1; }
VER=${tag_name#v}
echo -e "${BLUE}target version: $VER${NC}"

# ---------- 二进制 ----------
OLD=""
[[ -x "$BIN" ]] && OLD=$($BIN --version | head -1 | awk '{print $3}')

if [[ "$OLD" == "$VER" ]]; then
    BINARY_ACTION="already v$VER"
    echo -e "${GREEN}binary: already v$VER, skip${NC}"
else
    if [[ "$ARCH" == "x86_64" ]]; then
        ARCH_NAME="amd64"
    elif [[ "$ARCH" == "arm64" || "$ARCH" == "aarch64" ]]; then
        ARCH_NAME="arm64"
    else
        echo -e "${RED}Unknown arch: $ARCH${NC}"
        exit 1
    fi

    TMP=$(mktemp -d)
    cd "$TMP"
    PKG="node_exporter-${VER}.linux-${ARCH_NAME}"
    curl -fsSLO "https://github.com/prometheus/node_exporter/releases/download/$tag_name/$PKG.tar.gz"
    curl -fsSLO "https://github.com/prometheus/node_exporter/releases/download/$tag_name/sha256sums.txt"
    grep " ${PKG}.tar.gz$" sha256sums.txt | sha256sum -c - >/dev/null || { echo -e "${RED}checksum failed${NC}"; exit 1; }
    tar xzf "$PKG.tar.gz"

    [[ -n "$OLD" ]] && systemctl stop node_exporter 2>/dev/null || true
    install -o root -g root -m 0755 "$TMP/$PKG/node_exporter" "$BIN"

    CHANGED=1
    if [[ -z "$OLD" ]]; then
        BINARY_ACTION="installed v$VER"
        echo -e "${GREEN}binary: installed v$VER${NC}"
    else
        BINARY_ACTION="upgraded $OLD -> $VER"
        echo -e "${GREEN}binary: upgraded $OLD -> $VER${NC}"
    fi
fi

# ---------- 用户 & textfile 目录 ----------
if ! id node_exporter &>/dev/null; then
    useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter
    USER_ACTION="created"
    echo -e "${GREEN}user: created${NC}"
fi
install -d -o root -g root -m 0755 "$TEXTFILE_DIR"

# ---------- unit 文件（内容比对，不变不动） ----------
UNIT_NEW=$(mktemp)
cat > "$UNIT_NEW" <<'EOF'
[Unit]
Description=Prometheus Node Exporter
Documentation=https://github.com/prometheus/node_exporter
After=network-online.target
Wants=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --web.listen-address=0.0.0.0:9100 \
  --collector.disable-defaults \
  --collector.filesystem \
  --collector.meminfo \
  --collector.loadavg \
  --collector.uname \
  --collector.textfile \
  --collector.textfile.directory=/var/lib/node_exporter/textfile \
  --web.disable-exporter-metrics
Restart=always
RestartSec=5
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true

[Install]
WantedBy=multi-user.target
EOF

if ! cmp -s "$UNIT_NEW" "$UNIT" 2>/dev/null; then
    install -m 0644 "$UNIT_NEW" "$UNIT"
    systemctl daemon-reload
    CHANGED=1
    UNIT_ACTION="updated"
    echo -e "${GREEN}unit: updated${NC}"
else
    echo -e "${GREEN}unit: unchanged${NC}"
fi
rm -f "$UNIT_NEW"

# ---------- 服务状态 ----------
systemctl enable node_exporter >/dev/null 2>&1 || true   # enable 本身幂等
if [[ "$CHANGED" == 1 ]]; then
    systemctl restart node_exporter
    SERVICE_ACTION="restarted"
    echo -e "${GREEN}service: restarted${NC}"
elif systemctl is-active --quiet node_exporter; then
    SERVICE_ACTION="already running"
    echo -e "${GREEN}service: already running${NC}"
else
    systemctl start node_exporter
    SERVICE_ACTION="started"
    echo -e "${GREEN}service: started${NC}"
fi

# ---------- UFW（Docker 监控机放行 Docker bridge；其他主机按监控机 IPv4 放行） ----------
if [[ "$IS_VM_SERVER" == 1 ]]; then
    if ufw status | grep -Fq -- "172.16.0.0/12"; then
        FIREWALL_ACTION="Docker bridge rule already existed"
        echo -e "${GREEN}ufw: Docker bridge rule exists${NC}"
    else
        ufw allow from 172.16.0.0/12 to any port 9100 proto tcp comment "node_exporter from docker" || {
            echo -e "${RED}ufw: failed to allow Docker bridge -> :9100${NC}" >&2
            exit 1
        }
        FIREWALL_ACTION="allowed Docker bridge 172.16.0.0/12"
        echo -e "${GREEN}ufw: allowed Docker bridge -> :9100${NC}"
    fi
elif [[ -n "$monitor_ip" ]]; then
    if ufw status | grep -Fq -- "$monitor_ip"; then
        FIREWALL_ACTION="monitor IPv4 rule already existed"
        echo -e "${GREEN}ufw: rule exists${NC}"
    else
        ufw allow from "$monitor_ip" to any port 9100 proto tcp comment "node_exporter" || {
            echo -e "${RED}ufw: failed to allow $monitor_ip -> :9100${NC}" >&2
            exit 1
        }
        FIREWALL_ACTION="allowed monitor IPv4 $monitor_ip"
        echo -e "${GREEN}ufw: allowed $monitor_ip -> :9100${NC}"
    fi
else
    FIREWALL_ACTION="not configured (no -s provided)"
    echo -e "${YELLOW}tip: -s <监控机IPv4> 会自动加 ufw 白名单${NC}"
fi

# ---------- 验证 ----------
sleep 1
if systemctl is-active --quiet node_exporter && curl -sf --max-time 5 localhost:9100/metrics >/dev/null; then
    echo -e "${GREEN}OK: node_exporter v$($BIN --version | head -1 | awk '{print $3}') on :9100${NC}"
else
    echo -e "${RED}node_exporter is not healthy, check: journalctl -u node_exporter${NC}"
    exit 1
fi

echo
echo "========== node_exporter report =========="
echo "platform: $ID Linux / $ARCH"
echo "target version: $VER"
echo "binary: $BINARY_ACTION"
echo "user node_exporter: $USER_ACTION"
echo "systemd unit: $UNIT_ACTION"
echo "service: $SERVICE_ACTION"
if [[ "$IS_VM_SERVER" == 1 ]]; then
    echo "branch: VictoriaMetrics Docker server"
else
    echo "branch: regular server"
fi
echo "ufw: $FIREWALL_ACTION"
echo "metrics: http://127.0.0.1:9100/metrics healthy"
echo "==========================================="
