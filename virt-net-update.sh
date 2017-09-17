#!/bin/bash

VMS=`virsh list --name`
TLD="rastarnet"
NET="rtalur-default"

for each in $VMS
do
        mac_add=`virsh  dumpxml  $each | awk -F "=" '/mac address/ {print $2}' | awk -F "'" '{print $2}'`
        for mac in $mac_add
        do
                ip_add=`awk "/${mac}/ {print \\$1}" /proc/net/arp`
                echo $ip_add
                echo $mac
                echo "<host ip=\"${ip_add}\"><hostname>${each}.${TLD}</hostname></host>"  > ${each}${mac}.xml
                for network in $NET
                do
                        virsh net-update $network add dns-host --xml ${each}${mac}.xml  --live --config
                done
        done
done
