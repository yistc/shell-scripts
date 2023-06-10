#! /bin/bash

RELEASE=$(cat /etc/issue)

# This script is used to upgrade the Debian system, minimal version is Debian 9
do_apt_update(){
    apt update
    if [ $? -ne 0 ]; then
        exit 1
    fi;
}

do_apt_upgrade(){
    do_apt_update
    apt upgrade -y
    apt dist-upgrade -y
    apt full-upgrade -y
}

do_debian10_upgrade(){
    echo "[INFO] Doing debian 10 upgrade..."
    do_apt_update
    sed -i 's/stretch/buster/g' /etc/apt/sources.list
    sed -i 's/stretch/buster/g' /etc/apt/sources.list.d/*.list
    do_apt_upgrade
    echo "[INFO] Please reboot"
}

do_debian11_upgrade(){
    echo "[INFO] Doing debian 11 upgrade..."
    do_apt_upgrade
    sed -i 's/buster/bullseye/g' /etc/apt/sources.list
    sed -i 's/buster/bullseye/g' /etc/apt/sources.list.d/*.list
    sed -i 's/bullseye\/updates/bullseye-security/g' /etc/apt/sources.list
    do_apt_upgrade
    echo "[INFO] Please reboot"
}

do_debian12_upgrade(){
    echo "[INFO] Doing debian 12 upgrade..."
    do_apt_upgrade

    sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list
    sed -i 's/bullseye/bookworm/g' /etc/apt/sources.list.d/*.list

    sed -i 's/non-free/non-free non-free-firmware/g' /etc/apt/sources.list

    do_apt_upgrade

    apt autoclean
    apt autoremove -y
    echo "[INFO] Please reboot"
}

echo $RELEASE | grep ' 9 '
if [ $? -eq 0 ]; then
    do_debian10_upgrade
    exit 0
fi;

echo $RELEASE | grep ' 10 '
if [ $? -eq 0 ]; then
    do_debian11_upgrade
    exit 0
fi;

echo $RELEASE | grep ' 11 '
if [ $? -eq 0 ]; then
    do_debian12_upgrade
    exit 0
fi;
