# Refactor Notes

## Differences Found Across Scripts

### 1. Package Differences
- **debian_amd64_init.sh** includes: `curl wget zip` in apt install
- **debian_arm_init.sh** missing: `curl wget` (assumes already installed)
- **debian_arm_ipv6.sh** includes: `curl python3` and has proxy checks (ipv6-only specific)
- **ubuntu_amd64_init.sh** includes: `net-tools iperf3 pwgen python3 locales`
- **ubuntu_arm64_init.sh** includes: `net-tools iperf3 pwgen python3 locales`
- **Decision**: Use debian_amd64_init.sh as base, include `curl wget zip` as essential

### 2. DNS Configuration
- **debian scripts** use `resolvconf` package and `/etc/resolvconf/resolv.conf.d/tail`
- **ubuntu scripts** use `systemd-resolved` (stop and disable it), then `chattr +i /etc/resolv.conf`
- **Decision**: Debian approach is more flexible; Ubuntu's `chattr +i` prevents changes but may cause issues

### 3. Sysctl Configuration
- **debian_amd64_init.sh, debian_arm_init.sh** use `/etc/sysctl.d/local.conf`
- **debian_arm_ipv6.sh, ubuntu scripts** use `/etc/sysctl.conf`
- **Decision**: Use `/etc/sysctl.d/local.conf` as specified (modern best practice)

### 4. SSH Configuration
- **debian_amd64_init.sh** downloads ssh.conf from GitHub
- **debian_arm_init.sh** downloads ssh.conf from GitHub
- **ubuntu scripts** use sed to modify existing sshd_config
- **Decision**: Prefer downloading ssh.conf for consistency

### 5. SSH Restart Command
- **debian_amd64_init.sh** uses `systemctl restart sshd`
- **debian_arm_init.sh, ubuntu scripts** use `service sshd restart`
- **Decision**: Use `systemctl restart sshd` (more modern)

### 6. btop vs bottom
- **debian scripts** install `btop`
- **ubuntu scripts** install `bottom`
- **Decision**: Use `btop` as in debian template

### 7. Zshrc initialization
- **debian scripts** download and run `init_zshrc.sh`
- **ubuntu scripts** write aliases directly inline
- **Decision**: Use `init_zshrc.sh` method for maintainability

### 8. Starship configuration
- **All scripts** create starship.toml with hostname ssh_symbol configuration
- **Decision**: Keep this consistent

### 9. IPv6 Support
- **debian_arm_ipv6.sh** has special proxy checks and commented out ipv4 precedence
- **Decision**: Handle IPv6-only detection and skip ipv4 precedence setting accordingly

### 10. Python3
- **ubuntu scripts** install python3
- **debian_amd64_init.sh, debian_arm_init.sh** do NOT install python3
- **debian_arm_ipv6.sh** installs python3
- **Decision**: Do NOT install python3 on init as specified in requirements

### 11. Locale Configuration
- **ubuntu scripts** configure locale (en_US.UTF-8)
- **debian scripts** do NOT configure locale
- **Decision**: Include locale configuration for Ubuntu, skip for Debian

### 12. Additional SSH Key
- **ubuntu scripts** add servercat ssh key
- **debian scripts** only add yistc key
- **Decision**: Include both keys

### 13. Self-removal
- **debian_arm_init.sh, ubuntu scripts** remove themselves at the end
- **debian_amd64_init.sh** does NOT
- **Decision**: Do not auto-remove (let user decide)

### 14. Procs Installation
- **debian_amd64_init.sh, ubuntu_amd64_init.sh** download from releases (x86_64-linux.zip)
- **debian_arm_init.sh, debian_arm_ipv6.sh, ubuntu_arm64_init.sh** use hardcoded binary from repo
- **Decision**: Now use releases API for both amd64 and arm64 (aarch64-linux.zip)

### 15. IPv4 Precedence
- **Most scripts** enable ipv4 precedence over ipv6
- **debian_arm_ipv6.sh** has it commented out (ipv6-only server)
- **Decision**: Detect if server is IPv6-only and skip this setting

### 16. UFW
- **debian_amd64_init.sh, debian_arm_init.sh** install and enable UFW
- **ubuntu, debian_arm_ipv6.sh** do NOT install UFW
- **Decision**: Include UFW installation as in template

## Final Decisions

### Unified Script (server_init.sh)
1. **OS Detection**: Automatically detects Debian vs Ubuntu
2. **Architecture Detection**: Automatically detects amd64 vs arm64
3. **IP Stack Detection**: Detects IPv4-only, IPv6-only, or dual-stack
4. **Sysctl**: Uses `/etc/sysctl.d/local.conf` as specified
5. **Python3**: NOT installed by default as specified
6. **Procs**: Now downloads from official releases for both amd64 (x86_64-linux.zip) and arm64 (aarch64-linux.zip)
7. **DNS**: Uses resolvconf approach (more flexible than chattr +i)
8. **SSH**: Downloads ssh.conf from GitHub, uses systemctl restart
9. **Locale**: Only configured for Ubuntu
10. **SSH Keys**: Includes both yistc and servercat keys
11. **UFW**: Installed and enabled
12. **No auto-removal**: Script does not remove itself

### Debian Upgrade Script
- Updated to warn about Debian 12 requiring manual upgrade to Debian 13
- Moved to archive directory as requested

### Procs Binary
- Removed `bin/procs_aarch64_v0.14` (moved to archive)
- Now using official releases for both architectures
