#! /usr/bin/zsh
trap _exit INT QUIT TERM

apt install trojan sudo -y
systemctl restart nginx
echo -n "Enter domain for this server:"
read DOMAIN
echo -n "Enter base cert domain, e.g. example.com:"
read CERT
PASS=$(openssl rand -base64 32 | sed 's/[^a-z  A-Z 0-9]//g')
cat > /etc/trojan/config.json <<EOF
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 10001,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$PASS"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/etc/nginx/certs/$CERT.cer",
        "key": "/etc/nginx/certs/$CERT.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
    "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": true,
        "no_delay": true,
        "keep_alive": true,
        "fast_open": false,
        "reuse_port": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF

touch /etc/systemd/system/trojan.service
cat > /etc/systemd/system/trojan.service <<EOF
[Unit]
Description=trojan
After=network.target

[Service]
Type=simple
StandardError=journal
User=root
AmbientCapabilities=CAP_NET_BIND_SERVICE
ExecStart=/usr/bin/trojan -c /etc/trojan/config.json
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=2s

[Install]
WantedBy=multi-user.target
EOF

# download site files
wget https://github.com/yistc/across/raw/main/www.zip
unzip www.zip
mv public /home/

# clear default config
cat > /etc/nginx/conf.d/default.conf <<EOF
server {
    listen 80 default;
    server_name _;
    return 500;
}
EOF

# create nginx config for trojan
touch /etc/nginx/conf.d/trojan.conf
cat > /etc/nginx/conf.d/trojan.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    root /home/public;
    index index.php index.html index.htm;
    }
EOF

nginx -t
nginx -s reload

systemctl daemon-reload
systemctl enable trojan
systemctl start trojan
cat /etc/trojan/config.json