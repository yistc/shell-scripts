#! /bin/bash

TEST_FILES_ALL=(
    # softlayer
    http://speedtest.tok02.softlayer.com/downloads/test500.zip
    
    # Digital Ocean
    http://speedtest-sgp1.digitalocean.com/5gb.test
    http://speedtest-sfo3.digitalocean.com/5gb.test

    # Linode
    http://speedtest.ap-south-1.linodeobjects.com/1GB_test.file
    http://speedtest.ap-south-1.linodeobjects.com/10GB_test.file
    http://speedtest.tokyo2.linode.com/100MB-tokyo2.bin
    http://speedtest.singapore.linode.com/100MB-singapore.bin

    # Vultr
    https://sgp-ping.vultr.com/vultr.com.1000MB.bin
    https://hnd-jp-ping.vultr.com/vultr.com.1000MB.bin
    https://wa-us-ping.vultr.com/vultr.com.1000MB.bin

    # Racknerd
    http://lg-sea.racknerd.com/100MB.test
    http://lg-sea.racknerd.com/1000MB.test

    # Greencloud VPS
    # https://greencloudvps.com/data-centers.php
    http://216.244.83.34/download/100mb.zip
    http://103.121.211.211/500MB.test
    http://45.14.106.106/500MB.test
    http://89.187.162.133/1000mb.bin
    https://mirror.sin11.sg.leaseweb.net/speedtest/1000mb.bin
    http://43.249.36.49/speedtest/1000mb.bin

    # Discord CDN
    https://cdn.discordapp.com/attachments/1046787596535206010/1058318073431605299/DJI_MINI_3_PRO_-_Cinematic_4K_Video-YouTube.webm
    https://cdn.discordapp.com/attachments/1046787596535206010/1058318254424195073/LG_4K_DEMO_HDR_2018_60FPS_ELBA-YouTube.webm

    # https://sa.net/speedtest/
    https://lg-ty1.sa.net/100MB.test
    https://lg-ty2.sa.net/100MB.test

    # v.ps
    https://hkg.lg.v.ps/100MB.test
    https://nrt.lg.v.ps/100MB.test
    https://kix.lg.v.ps/100MB.test
    https://sea.lg.v.ps/100MB.test

    # Speedypage
    https://sg.lg.speedypage.com/100MB.test

    # Leaseweb
    http://mirror.hkg10.hk.leaseweb.net/speedtest/1000mb.bin
    http://mirror.tyo10.jp.leaseweb.net/speedtest/1000mb.bin
    http://mirror.sin1.sg.leaseweb.net/speedtest/1000mb.bin
    http://mirror.sfo12.us.leaseweb.net/speedtest/1000mb.bin
)

TEST_FILES_JP=(
    http://speedtest.tok02.softlayer.com/downloads/test500.zip
    http://mirror.tyo10.jp.leaseweb.net/speedtest/1000mb.bin
    https://nrt.lg.v.ps/100MB.test
    https://hnd-jp-ping.vultr.com/vultr.com.1000MB.bin
    https://kix.lg.v.ps/100MB.test
    http://45.14.106.106/500MB.test
    http://speedtest.tokyo2.linode.com/100MB-tokyo2.bin
    https://lg-ty1.sa.net/100MB.test
    https://lg-ty2.sa.net/100MB.test
    http://103.121.211.211/500MB.test
)

for i in {1..10}; do
    for file in ${TEST_FILES_JP[@]}; do
        echo "Testing $file"
        wget -O /dev/null $file
    done
done