#! /bin/bash

[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root!" && exit 1

trap _exit INT QUIT TERM

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

OS=$(uname -s) # Linux, FreeBSD, Darwin
ARCH=$(uname -m) # x86_64, arm64, aarch64
DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )
GITPROXY='https://ghproxy.com'

_exit() {
    echo -e "${RED}Exiting...${NC}"
    exit 1
}

# latest tag_name
tag_name=$(curl -s https://api.github.com/repos/ClementTsang/bottom/releases/latest | grep tag_name|cut -f4 -d "\"")

# download based on arch
if [[ $ARCH == "x86_64" ]]; then
    download_url="https://github.com/ClementTsang/bottom/releases/download/$tag_name/bottom_x86_64-unknown-linux-gnu.tar.gz"
    zip_name="bottom_x86_64-unknown-linux-gnu.tar.gz"
elif [[ $ARCH == "arm64" ]]; then
    download_url="https://github.com/ClementTsang/bottom/releases/download/$tag_name/bottom_aarch64-unknown-linux-gnu.tar.gz"
    zip_name="bottom_aarch64-unknown-linux-gnu.tar.gz"
fi

# download
curl -LO $download_url

# unzip, take bottom only
tar zxvf $zip_name btm
rm $zip_name
chmod +x btm

# move to /usr/local/bin
mv btm /usr/local/bin

# config
mkdir -p /root/.config/bottom

cat > /root/.config/bottom/bottom.toml <<EOF
# This is a default config file for bottom.  All of the settings are commented
# out by default; if you wish to change them uncomment and modify as you see
# fit.
# This group of options represents a command-line flag/option.  Flags explicitly
# added when running (ie: btm -a) will override this config file if an option
# is also set here.
[flags]
# Whether to hide the average cpu entry.
#hide_avg_cpu = false
# Whether to use dot markers rather than braille.
#dot_marker = false
# The update rate of the application.
#rate = 1000
# Whether to put the CPU legend to the left.
#left_legend = false
# Whether to set CPU% on a process to be based on the total CPU or just current usage.
#current_usage = false
# Whether to group processes with the same name together by default.
#group_processes = false
# Whether to make process searching case sensitive by default.
#case_sensitive = false
# Whether to make process searching look for matching the entire word by default.
#whole_word = false
# Whether to make process searching use regex by default.
#regex = false
# Defaults to Celsius.  Temperature is one of:
#temperature_type = "k"
#temperature_type = "f"
#temperature_type = "c"
#temperature_type = "kelvin"
#temperature_type = "fahrenheit"
#temperature_type = "celsius"
# The default time interval (in milliseconds).
#default_time_value = 60000
# The time delta on each zoom in/out action (in milliseconds).
#time_delta = 15000
# Hides the time scale.
#hide_time = false
# Override layout default widget
#default_widget_type = "proc"
#default_widget_count = 1
# Use basic mode
#basic = false
# Use the old network legend style
#use_old_network_legend = false
# Remove space in tables
#hide_table_gap = false
# Show the battery widgets
#battery = false
# Disable mouse clicks
#disable_click = false
# Built-in themes.  Valid values are "default", "default-light", "gruvbox", "gruvbox-light", "nord", "nord-light"
#color = "default"
# Show memory values in the processes widget as values by default
#mem_as_value = false
# Show tree mode by default in the processes widget.
#tree = false
# Shows an indicator in table widgets tracking where in the list you are.
#show_table_scroll_position = false
# Show processes as their commands by default in the process widget.
#process_command = false
# Displays the network widget with binary prefixes.
#network_use_binary_prefix = false
# Displays the network widget using bytes.
#network_use_bytes = false
# Displays the network widget with a log scale.
#network_use_log = false
# Hides advanced options to stop a process on Unix-like systems.
#disable_advanced_kill = false
# Shows GPU(s) memory
#enable_gpu_memory = false
# These are all the components that support custom theming.  Note that colour support
# will depend on terminal support.
[colors] # Uncomment if you want to use custom colors
# Represents the colour of table headers (processes, CPU, disks, temperature).
table_header_color="#8758FF"
# Represents the colour of the label each widget has.
widget_title_color="#FA7070"
# Represents the average CPU color.
avg_cpu_color="Red"
# Represents the colour the core will use in the CPU legend and graph.
cpu_core_colors=["LightMagenta", "LightYellow", "LightCyan", "LightGreen", "LightBlue", "LightRed", "Cyan", "Green", "Blue", "Red"]
# Represents the colour RAM will use in the memory legend and graph.
ram_color="#d3869b"
# Represents the colour SWAP will use in the memory legend and graph.
swap_color="#d65d0e"
# Represents the colour ARC will use in the memory legend and graph.
arc_color="#fe8019"
# Represents the colour the GPU will use in the memory legend and graph.
gpu_core_colors=["LightGreen", "LightBlue", "LightRed", "Cyan", "Green", "Blue", "Red"]
# Represents the colour rx will use in the network legend and graph.
rx_color="LightCyan"
# Represents the colour tx will use in the network legend and graph.
tx_color="LightGreen"
# Represents the colour of the border of unselected widgets.
border_color="LightRed"
# Represents the colour of the border of selected widgets.
highlighted_border_color="LightBlue"
# Represents the colour of most text.
text_color="#b16286"
# Represents the colour of text that is selected.
selected_text_color="Black"
# Represents the background colour of text that is selected.
selected_bg_color="LightBlue"
# Represents the colour of the lines and text of the graph.
graph_color="#D58BDD"
# Represents the colours of the battery based on charge
high_battery_color="green"
#medium_battery_color="yellow"
low_battery_color="red"
# Layout - layouts follow a pattern like this:
# [[row]] represents a row in the application.
# [[row.child]] represents either a widget or a column.
# [[row.child.child]] represents a widget.
#
# All widgets must have the type value set to one of ["cpu", "mem", "proc", "net", "temp", "disk", "empty"].
# All layout components have a ratio value - if this is not set, then it defaults to 1.
# The default widget layout:
#[[row]]
#  ratio=30
#  [[row.child]]
#  type="cpu"
#[[row]]
#    ratio=40
#    [[row.child]]
#      ratio=4
#      type="mem"
#    [[row.child]]
#      ratio=3
#      [[row.child.child]]
#        type="temp"
#      [[row.child.child]]
#        type="disk"
#[[row]]
#  ratio=30
#  [[row.child]]
#    type="net"
#  [[row.child]]
#    type="proc"
#    default=true
# Filters - you can hide specific temperature sensors, network interfaces, and disks using filters.  This is admittedly
# a bit hard to use as of now, and there is a planned in-app interface for managing this in the future:
#[disk_filter]
#is_list_ignored = true
#list = ["/dev/sda\\d+", "/dev/nvme0n1p2"]
#regex = true
#case_sensitive = false
#whole_word = false
#[mount_filter]
#is_list_ignored = true
#list = ["/mnt/.*", "/boot"]
#regex = true
#case_sensitive = false
#whole_word = false
#[temp_filter]
#is_list_ignored = true
#list = ["cpu", "wifi"]
#regex = false
#case_sensitive = false
#whole_word = false
#[net_filter]
#is_list_ignored = true
#list = ["virbr0.*"]
#regex = true
#case_sensitive = false
#whole_word = false
EOF