# shell-scripts

## Server Initialization

### Unified Init Script

Use `init/server_init.sh` for initializing new servers. This script automatically detects:

- **OS Type**: Debian or Ubuntu
- **Architecture**: amd64 (x86_64) or arm64 (aarch64)
- **IP Stack**: IPv4-only, IPv6-only, or dual-stack

#### Features

- BBR congestion control (sysctl configuration in `/etc/sysctl.d/local.conf`)
- DNS configuration with multiple nameservers
- ZSH setup with custom configuration
- Modern CLI tools installation (dust, lsd, fd, btop, procs, starship, zoxide, bat)
- SSH hardening
- UFW firewall setup
- Swap file creation (if not present)
- Timezone configuration (Asia/Hong_Kong)
- Locale configuration (Ubuntu only)

#### Usage

```bash
curl -LO https://raw.githubusercontent.com/yistc/shell-scripts/main/init/server_init.sh
bash server_init.sh
```

### Legacy Scripts

The following scripts have been superseded by `server_init.sh`:
- `debian_amd64_init.sh`
- `debian_arm_init.sh`
- `debian_arm_ipv6.sh`
- `ubuntu_amd64_init.sh`
- `ubuntu_arm64_init.sh`

## Archived Scripts

- `debian_upgrade.sh` - Moved to archive. For Debian 12, manual upgrade to Debian 13 is required.
- `bin/procs_aarch64_v0.14` - Replaced with official release downloads for both architectures.