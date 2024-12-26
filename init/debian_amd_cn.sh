#! /bin/bash

# install dust
curl -LO "https://ghgo.xyz/https://github.com/bootandy/dust/releases/download/v1.1.1/dust-v1.1.1-x86_64-unknown-linux-gnu.tar.gz"
tar zxvf "dust-v1.1.1-x86_64-unknown-linux-gnu.tar.gz" "dust-v1.1.1-x86_64-unknown-linux-gnu/dust"
mv "dust-v1.1.1-x86_64-unknown-linux-gnu/dust" /usr/local/bin
chmod +x /usr/local/bin/dust
rm -rf "dust-v1.1.1-x86_64-unknown-linux-gnu.tar.gz" "dust-v1.1.1-x86_64-unknown-linux-gnu"

# install lsd
curl -LO "https://ghgo.xyz/https://github.com/lsd-rs/lsd/releases/download/v1.1.5/lsd-v1.1.5-x86_64-unknown-linux-gnu.tar.gz"
tar zxvf "lsd-v1.1.5-x86_64-unknown-linux-gnu.tar.gz"
mv "lsd-v1.1.5-x86_64-unknown-linux-gnu/lsd" /usr/local/bin
chmod +x /usr/local/bin/lsd
rm -rf "lsd-v1.1.5-x86_64-unknown-linux-gnu.tar.gz" "lsd-v1.1.5-x86_64-unknown-linux-gnu"

# lsd theme
curl -LO https://ghgo.xyz/https://raw.githubusercontent.com/yistc/shell-scripts/main/config/lsd_theme.sh
bash lsd_theme.sh
rm lsd_theme.sh

# install fd, an alternative to `find` written in Rust
curl -LO "https://ghgo.xyz/https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz"
tar zxvf "fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz" && mv "fd-v10.2.0-x86_64-unknown-linux-gnu/fd" /usr/local/bin && chmod +x /usr/local/bin/fd && rm -rf "fd-v10.2.0-x86_64-unknown-linux-gnu.tar.gz" "fd-v10.2.0-x86_64-unknown-linux-gnu"

# install btop
# download based on arch
if [[ $ARCH == "x86_64" ]]; then
  download_url="https://ghgo.xyz/https://github.com/aristocratos/btop/releases/latest/download/btop-x86_64-linux-musl.tbz"
  zip_name="btop-x86_64-linux-musl.tbz"
elif [[ $ARCH == "arm64" || $ARCH == "aarch64" ]]; then
  download_url="https://ghgo.xyz/https://github.com/aristocratos/btop/releases/latest/download/btop-aarch64-linux-musl.tbz"
  zip_name="btop-aarch64-linux-musl.tbz"
fi

curl -LO $download_url && tar -xjf $zip_name && cd btop && make install && cd .. && rm -rf btop && rm -rf $zip_name

# install procs
curl -LO "https://ghgo.xyz/https://github.com/dalance/procs/releases/download/v0.14.8/procs-v0.14.8-x86_64-linux.zip"
unzip "procs-v0.14.8-x86_64-linux.zip" && chmod +x procs && mv procs /usr/local/bin && rm -rf "procs-v0.14.8-x86_64-linux.zip"

# starship
curl -LO https://ghgo.xyz/https://github.com/starship/starship/releases/latest/download/starship-x86_64-unknown-linux-gnu.tar.gz
tar zxvf starship-x86_64-unknown-linux-gnu.tar.gz && mv starship /usr/local/bin/starship && rm starship-x86_64-unknown-linux-gnu.tar.gz

mkdir -p ~/.config && touch ~/.config/starship.toml

cat >>~/.config/starship.toml<<EOF
[hostname]
ssh_symbol=''
EOF

# install zoxide
curl -LO "https://ghgo.xyz/https://github.com/ajeetdsouza/zoxide/releases/download/v0.9.6/zoxide-0.9.6-x86_64-unknown-linux-musl.tar.gz"

tar zxvf "zoxide-0.9.6-x86_64-unknown-linux-musl.tar.gz" && mv zoxide /usr/local/bin && rm -rf "zoxide-0.9.6-x86_64-unknown-linux-musl.tar.gz" CHANGELOG.md completions LICENSE man README.md

# install bat
tag_name=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/sharkdp/bat/releases/download/${tag_name}/bat_${tag_name#v}_amd64.deb"
dpkg -i "bat_${tag_name#v}_amd64.deb"
rm -f "bat_${tag_name#v}_amd64.deb"

echo 'export BAT_THEME="Solarized (light)"' >> ~/.zshrc

# vim config
curl -LO https://ghgo.xyz/https://raw.githubusercontent.com/yistc/shell-scripts/main/config/vim.sh && bash vim.sh && rm vim.sh

# locale

# Swap
SWAP=$(free | grep Swap | awk '{print $2}')

if [ "$SWAP" -gt 0 ]; then
    echo "Swap is enabled."
else
    echo -e "${GREEN}Swap is not enabled. Setting up swap ..${NC}"
    fallocate -l 1G /var/swapfile
    chmod 600 /var/swapfile
    mkswap /var/swapfile
    swapon /var/swapfile
    echo "/var/swapfile swap swap defaults 0 0" >> /etc/fstab
fi