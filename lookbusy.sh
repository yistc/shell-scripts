#! /bin/bash

# check for gcc or clang, if no, exit 
if ! [ -x "$(command -v gcc)" ] && ! [ -x "$(command -v clang)" ]; then
  echo 'Error: gcc or clang is not installed.' >&2
  exit 1
fi

git clone https://github.com/yistc/lookbusy /opt/lookbusy
cd /opt/lookbusy
chmod a+x configure
./configure
make
make install

cd ~

rm -rf /opt/lookbusy

# ask user how much cpu to use
# default to 20
# echo "How much cpu do you want to use? (default 20)"
# read cpu
# if [ -z "$cpu" ]
# then
#     cpu=20
# fi

# ask user how much memory to use
# default 400MB
echo "How much memory do you want to use? (e.g. 512MB, 1GB, 2GB, default 400MB)"
read memory

if [ -z "$memory" ]
then
    memory='400MB'
fi

cat > /etc/systemd/system/lookbusy.service << EOF
[Unit]
Description=lookbusy service
 
[Service]
Type=simple
ExecStart=/usr/local/bin/lookbusy -c 1 -m $memory
Restart=always
RestartSec=10
KillSignal=SIGINT
 
[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now lookbusy.service