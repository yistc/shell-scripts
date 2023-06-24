#! /bin/bash

apt -y update
apt -y install curl build-essential
curl -L http://www.devin.com/lookbusy/download/lookbusy-1.4.tar.gz -o lookbusy-1.4.tar.gz
tar -xzvf lookbusy-1.4.tar.gz
cd lookbusy-1.4/
./configure
make
make install

rm -rf /root/lookbusy-1.4
rm -rf /root/lookbusy-1.4.tar.gz

cat > /etc/systemd/system/lookbusy.service << EOF
[Unit]
Description=lookbusy service
 
[Service]
Type=simple
ExecStart=/usr/local/bin/lookbusy -c 15 -m 512MB
Restart=always
RestartSec=10
KillSignal=SIGINT
 
[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now lookbusy.service