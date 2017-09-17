#!/bin/bash

NNODES=3
NDISKS=5
DISK_SIZE="500G"
BASE_IMAGE="/home/rtalur/Appdata/VMs/rhel-7.3-server-rtalur_vagrant_box_image_0.img"
VM_NAMES="cns36cluster2node"
RAM=1024
NET="rtalur-default"
#NET="ens3f0"
TLD="rastarnet"


for i in $(seq 0 ${NNODES})
do
   qemu-img create -f qcow2 -b ${BASE_IMAGE}  "/home/rtalur/Appdata/VMs/${VM_NAMES}${i}.img"
   disk_string=""
   for j in $(seq 1 ${NDISKS})
   do
     qemu-img  create -f qcow2 "/home/rtalur/Appdata/VMs/${VM_NAMES}${i}-disk${j}.img" ${DISK_SIZE}
     disk_string=${disk_string}"--disk /home/rtalur/Appdata/VMs/${VM_NAMES}${i}-disk${j}.img,device=disk,bus=virtio "
   done
   #virt-install -n ${VM_NAMES}${i}\
   #             -r $RAM\
   #             --os-type=linux\
   #             --os-variant=rhel7\
   #             --disk /var/lib/libvirt/images/${VM_NAMES}${i}.img,device=disk,bus=virtio\
   #             ${disk_string}\
   #     	-w type=direct,source=${NET},source_mode=bridge\
   #             --vnc --noautoconsole --import

   virt-install -n ${VM_NAMES}${i}\
                -r $RAM\
                --os-type=linux\
                --os-variant=rhel7\
                --disk /home/rtalur/Appdata/VMs/${VM_NAMES}${i}.img,device=disk,bus=virtio\
                ${disk_string}\
                -w network=${NET}\
                --vnc --noautoconsole --import
  sleep 20
  mac_add=`virsh  dumpxml  ${VM_NAMES}${i} | awk -F "=" '/mac address/ {print $2}' | awk -F "'" '{print $2}'`
  ip_add=`awk "/${mac_add}/ {print \\$1}" /proc/net/arp`
  echo "<host ip=\"${ip_add}\"><hostname>${VM_NAMES}${i}.${TLD}</hostname></host>"  > ${VM_NAMES}${i}.xml
  virsh net-update ${NET} add dns-host --xml ${VM_NAMES}${i}.xml  --live --config
  #virsh net-update ${NET} add dns-host "<host ip=\"${ip_add}\"><hostname>${VM_NAMES}${i}.${TLD}</hostname></host>"  --live --config

  echo ${VM_NAMES}${i}.${TLD} ${ip_add}

done
