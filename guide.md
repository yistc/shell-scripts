Do

# Language styles
- Use two space for indentation

# Features to do
1. Merge Scripts
Currently we have debian_amd64_init.sh, debian_arm_init.sh, debian_arm_ipv6.sh, ubuntu_amd64_init.sh, and ubuntu_arm64_init.sh  Merge them into one sh instead of multiple
Note the following guidelines
- Take debian_amd64_init.sh as template
- sysctl use /etc/sysctl.d/local.conf
- do not install python3 on init
- You should check if server is debian or ubuntu, if server is ipv6 only or ipv4 only or dual stack. if server is amd64 or arm64

If you found diffs across different scripts and you're not sure which way to go, node them down in refactor.md

2. procs

Previously https://github.com/dalance/procs/releases does not provide aarch64 binaries for arm servers, so I manually compiled and put the binary in bin/procs_aarch64_v0.14. However, now they provide the binary, so improve this for both amd and arm servers

# install procs
tag_name=$(curl -s https://api.github.com/repos/dalance/procs/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/dalance/procs/releases/download/${tag_name}/procs-${tag_name}-x86_64-linux.zip"
unzip "procs-${tag_name}-x86_64-linux.zip"
chmod +x procs
mv procs /usr/local/bin
rm -rf "procs-${tag_name}-x86_64-linux.zip"


3. Debian upgrade

In debian_upgrade.sh, if debian server is 12, warns that should manually upgrade to 13, and then move it to archive dir
