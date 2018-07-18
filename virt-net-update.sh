#!/bin/bash

VMS=`virsh list --name`
TLD="rastarnet"

declare -A NET
NET[obnox_vagrant_dev]=192.168.55
NET[rtalur_vagrant_single_dev]=192.168.21
NET[vagrant-libvirt]=192.168.121
NET[default]=192.168.122
NET[cns39]=192.168.39
NET[gd2server1]=192.168.11
NET[gd2server2]=192.168.12
NET[gd2server3]=192.168.13

for each in $VMS
do
        mac_add=`virsh  dumpxml  $each | awk -F "=" '/mac address/ {print $2}' | awk -F "'" '{print $2}'`
        for mac in $mac_add
        do
                ip_add=`awk "/${mac}/ {print \\$1}" /proc/net/arp`
                echo "ip is" $ip_add
                echo "mac is" $mac
                for K in "${!NET[@]}"
                do
                        echo "key is $K and value is ${NET[$K]}"
                        if [[ $ip_add =~ ${NET[$K]} ]]
                        then
                                echo "inside $K"
                                echo "<host ip=\"${ip_add}\"><hostname>${each}.${K}.${TLD}</hostname></host>"  > ${each}${mac}.xml
                                virsh net-update $K add dns-host --xml ${each}${mac}.xml  --live --config
                        fi
                done
        done
done
