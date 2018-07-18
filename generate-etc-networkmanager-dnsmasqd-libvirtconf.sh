#!/bin/bash

echo -n "" | sudo tee /etc/NetworkManager/dnsmasq.d/libvirt.conf
cat /home/rtalur/Code/virt-scripts/mynetworks.list | while read -r line
do
        ip=`echo $line | cut -d"," -f1`
        name=`echo $line | cut -d"," -f2`
        echo ip $ip
        echo name $name
        echo "server=/${name}/${ip}" | sudo tee -a /etc/NetworkManager/dnsmasq.d/libvirt.conf
done
