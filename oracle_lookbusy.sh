#! /bin/bash

apt -y update
apt -y install curl build-essential
git clone https://github.com/yistc/lookbusy /opt/lookbusy
cd /opt/lookbusy
chmod a+x configure
./configure
make
make install

rm -rf /opt/lookbusy

# ask user how much memory to use
echo "How much memory do you want to use? (e.g. 512MB, 1GB, 2GB)"
read memory

cat > /etc/systemd/system/lookbusy.service << EOF
[Unit]
Description=lookbusy service
 
[Service]
Type=simple
ExecStart=/usr/local/bin/lookbusy -c 25 -m $memory
Restart=always
RestartSec=10
KillSignal=SIGINT
 
[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now lookbusy.service