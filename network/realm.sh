#! /bin/bash

curl -LO https://github.com/zhboner/realm/releases/latest/download/realm-x86_64-unknown-linux-gnu.tar.gz
tar zxvf realm-x86_64-unknown-linux-gnu.tar.gz
chmod +x realm
mv realm /usr/local/bin/realm
mkdir -p /etc/realm

cat >/etc/systemd/system/realm.service<<EOF
[Unit]
Description=realm
After=network-online.target
Wants=network-online.target systemd-networkd-wait-online.service
[Service]
Type=simple
User=root
Restart=on-failure
RestartSec=3s
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/realm -n 65535 -c /etc/realm/1.toml
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

rm realm-x86_64-unknown-linux-gnu.tar.gz
# delete this file
rm -f $0
echo "First edit config at /etc/realm/1.toml"
echo "systemctl enable realm --now"
echo "systemctl status realm"