#!/bin/bash

VMS=`virsh list --name`
TLD="rastarnet"
NET="rtalur-default"

for each in $VMS
do
        mac_add=`virsh  dumpxml  $each | awk -F "=" '/mac address/ {print $2}' | awk -F "'" '{print $2}'`
        ip_add=`awk "/${mac_add}/ {print \\$1}" /proc/net/arp`
        echo "<host ip=\"${ip_add}\"><hostname>${each}.${TLD}</hostname></host>"  > ${each}.xml
        virsh net-update ${NET} add dns-host --xml ${each}.xml  --live --config
done
