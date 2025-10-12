# Changes Summary

## 1. Unified Init Script (init/server_init.sh)

Created a single unified initialization script that replaces 5 separate scripts:
- `debian_amd64_init.sh`
- `debian_arm_init.sh`
- `debian_arm_ipv6.sh`
- `ubuntu_amd64_init.sh`
- `ubuntu_arm64_init.sh`

### Key Features:
- **Automatic OS Detection**: Detects Debian vs Ubuntu
- **Automatic Architecture Detection**: Detects amd64 vs arm64
- **Automatic IP Stack Detection**: Detects IPv4-only, IPv6-only, or dual-stack
- **Smart Configuration**: Adjusts settings based on detected environment
  - IPv4 precedence skipped for IPv6-only servers
  - Locale configuration only for Ubuntu
  - Architecture-specific binary downloads

## 2. Improved Procs Installation

Previously, arm64 servers used a manually compiled binary (`bin/procs_aarch64_v0.14`) because official releases didn't provide aarch64 binaries.

Now, the script uses official releases for both architectures:

**AMD64:**
```bash
tag_name=$(curl -s https://api.github.com/repos/dalance/procs/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/dalance/procs/releases/download/${tag_name}/procs-${tag_name}-x86_64-linux.zip"
unzip "procs-${tag_name}-x86_64-linux.zip"
chmod +x procs
mv procs /usr/local/bin
rm -rf "procs-${tag_name}-x86_64-linux.zip"
```

**ARM64:**
```bash
tag_name=$(curl -s https://api.github.com/repos/dalance/procs/releases/latest | grep tag_name|cut -f4 -d "\"")
curl -LO "https://github.com/dalance/procs/releases/download/${tag_name}/procs-${tag_name}-aarch64-linux.zip"
unzip "procs-${tag_name}-aarch64-linux.zip"
chmod +x procs
mv procs /usr/local/bin
rm -rf "procs-${tag_name}-aarch64-linux.zip"
```

The old manual binary has been archived.

## 3. Debian Upgrade Script

Updated `debian_upgrade.sh` to handle Debian 12:
- Warns users that Debian 12 requires manual upgrade to Debian 13
- Script moved to `archive/` directory as it's now superseded

## 4. Configuration Standards

- **Sysctl**: Uses `/etc/sysctl.d/local.conf` (modern best practice)
- **No Python3**: Not installed by default as specified
- **2-space indentation**: All code follows consistent style

## Files Changed

### Created:
- `init/server_init.sh` - Unified initialization script
- `refactor.md` - Documentation of differences and decisions
- `CHANGES.md` - This summary
- Updated `README.md` - Documentation

### Moved to Archive:
- `debian_upgrade.sh` → `archive/debian_upgrade.sh`
- `bin/procs_aarch64_v0.14` → `archive/procs_aarch64_v0.14`

### To Be Deprecated:
- `init/debian_amd64_init.sh` (replaced by server_init.sh)
- `init/debian_arm_init.sh` (replaced by server_init.sh)
- `init/debian_arm_ipv6.sh` (replaced by server_init.sh)
- `init/ubuntu_amd64_init.sh` (replaced by server_init.sh)
- `init/ubuntu_arm64_init.sh` (replaced by server_init.sh)
