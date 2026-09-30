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

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

while getopts s: opt; do
    case $opt in
        s)
            server_id=$OPTARG
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            ;;
    esac
done

BIN=/usr/local/bin/node_exporter
UNIT=/etc/systemd/system/node_exporter.service
TEXTFILE_DIR=/var/lib/node_exporter/textfile
CHANGED=0

# ---------- 目标版本（GitHub latest） ----------
tag_name=$(curl -fsSL https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -f4 -d "\"")
[[ -z "$tag_name" ]] && { echo -e "${RED}Failed to fetch latest tag${NC}"; exit 1; }
VER=${tag_name#v}
echo -e "${BLUE}target version: $VER${NC}"

# ---------- 二进制 ----------
OLD=""
[[ -x "$BIN" ]] && OLD=$($BIN --version | head -1 | awk '{print $3}')

if [[ "$OLD" == "$VER" ]]; then
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

    TMP=$(mktemp -d) && cd "$TMP"
    PKG="node_exporter-${VER}.linux-${ARCH_NAME}"
    curl -fsSLO "https://github.com/prometheus/node_exporter/releases/download/$tag_name/$PKG.tar.gz"
    curl -fsSLO "https://github.com/prometheus/node_exporter/releases/download/$tag_name/sha256sums.txt"
    grep " ${PKG}.tar.gz$" sha256sums.txt | sha256sum -c - >/dev/null || { echo -e "${RED}checksum failed${NC}"; exit 1; }
    tar xzf "$PKG.tar.gz"

    [[ -n "$OLD" ]] && systemctl stop node_exporter 2>/dev/null || true
    install -o root -g root -m 0755 "$PKG/node_exporter" "$BIN"
    cd - >/dev/null && rm -rf "$TMP"

    CHANGED=1
    [[ -z "$OLD" ]] && echo -e "${GREEN}binary: installed v$VER${NC}" || echo -e "${GREEN}binary: upgraded $OLD -> $VER${NC}"
fi

# ---------- 用户 & textfile 目录 ----------
if ! id node_exporter &>/dev/null; then
    useradd --system --no-create-home --shell /usr/sbin/nologin node_exporter
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
    echo -e "${GREEN}unit: updated${NC}"
else
    echo -e "${GREEN}unit: unchanged${NC}"
fi
rm -f "$UNIT_NEW"

# ---------- 服务状态 ----------
systemctl enable node_exporter >/dev/null 2>&1 || true   # enable 本身幂等
if [[ "$CHANGED" == 1 ]]; then
    systemctl restart node_exporter
    echo -e "${GREEN}service: restarted${NC}"
elif systemctl is-active --quiet node_exporter; then
    echo -e "${GREEN}service: already running${NC}"
else
    systemctl start node_exporter
    echo -e "${GREEN}service: started${NC}"
fi

# ---------- UFW（-s 传监控机 IP 时配） ----------
if [[ -n "${server_id:-}" ]]; then
    if ufw status | grep -q "$server_id"; then
        echo -e "${GREEN}ufw: rule exists${NC}"
    else
        ufw allow from "$server_id" to any port 9100 proto tcp comment "node_exporter"
        echo -e "${GREEN}ufw: allowed $server_id -> :9100${NC}"
    fi
else
    echo -e "${YELLOW}tip: -s <监控机IP> 会自动加 ufw 白名单${NC}"
fi

# ---------- 验证 ----------
sleep 1
if systemctl is-active --quiet node_exporter && curl -sf --max-time 5 localhost:9100/metrics >/dev/null; then
    echo -e "${GREEN}OK: node_exporter v$($BIN --version | head -1 | awk '{print $3}') on :9100${NC}"
else
    echo -e "${RED}node_exporter is not healthy, check: journalctl -u node_exporter${NC}"
    exit 1
fi
