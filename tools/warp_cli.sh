#! /bin/bash

apt install gpg -y

curl https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bullseye main' | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

apt update -y && apt install cloudflare-warp -y