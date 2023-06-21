#! /bin/bash

ARCH=$(uname -m) # x86_64, arm64, aarch64

apt install xz-utils -y
tag_name=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep tag_name|cut -f4 -d "\"")

if [[ "$ARCH" == "x86_64" ]]; then
    curl -LO "https://github.com/shadowsocks/shadowsocks-rust/releases/download/${tag_name}/shadowsocks-${tag_name}.x86_64-unknown-linux-gnu.tar.xz"
    zip_name="shadowsocks-${tag_name}.x86_64-unknown-linux-gnu.tar.xz"
elif [[ "$ARCH" == "arm64" ]]; then
    curl -LO "https://github.com/shadowsocks/shadowsocks-rust/releases/download/${tag_name}/shadowsocks-${tag_name}.aarch64-unknown-linux-gnu.tar.xz"
    zip_name="shadowsocks-${tag_name}.aarch64-unknown-linux-gnu.tar.xz"
else
    echo "Not supported"
    exit 1
fi

tar xf $zip_name ssserver
mv ssserver /usr/local/bin
chmod +x /usr/local/bin/ssserver

mkdir -p /etc/ssrust
PASS=$(openssl rand -base64 32 | sed 's/[^a-z  A-Z 0-9]//g')
echo -n "Enter port:"
read port
cat > /etc/ssrust/config.json <<EOF
{
    "server":"0.0.0.0",
    "server_port":$port,
    "password":"$PASS",
    "timeout":300,
    "method":"aes-256-gcm",
    "fast_open":false,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp"
}
EOF

cat > /etc/systemd/system/ssrust.service <<EOF
[Unit]
Description=Shadowsocks-Rust Service
After=network.target

[Service]
Type=simple
User=nobody
Group=nogroup
ExecStart=/usr/local/bin/ssserver -n 10240 -c /etc/ssrust/config.json

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start ssrust
systemctl enable ssrust --now
cat /etc/ssrust/config.json
echo -e "Server IP: \n$(curl -s http://checkip.amazonaws.com/)"
rm -f $zip_name