#!/bin/bash

NNODES=6
NDISKS=5
DISK_SIZE="500G"
STORAGE_POOL=${STORAGE_POOL:="/var/lib/libvirt/images"}
BASE_IMAGE_NAME=${BASE_IMAGE:="rhel-7.5.qcow2"}
VM_NAMES="cns-3.10.0-cluster1-node"
RAM=2048
NET="cns-3.10.0"
TLD="cns3100net"


for i in $(seq 0 ${NNODES})
do
   qemu-img create -f qcow2 -b "${STORAGE_POOL}/${BASE_IMAGE_NAME}"  "${STORAGE_POOL}/${VM_NAMES}${i}.img"
   disk_string=""
   for j in $(seq 1 ${NDISKS})
   do
     qemu-img  create -f qcow2 "${STORAGE_POOL}/${VM_NAMES}${i}-disk${j}.img" ${DISK_SIZE}
     disk_string=${disk_string}"--disk ${STORAGE_POOL}/${VM_NAMES}${i}-disk${j}.img,device=disk,bus=virtio "
   done

   virt-install -n ${VM_NAMES}${i}\
                -r $RAM\
                --os-type=linux\
                --os-variant=rhel7\
                --disk ${STORAGE_POOL}/${VM_NAMES}${i}.img,device=disk,bus=virtio\
                ${disk_string}\
                -w network=${NET}\
                --vnc --noautoconsole --import
  sleep 20
  mac_add=`virsh  dumpxml  ${VM_NAMES}${i} | awk -F "=" '/mac address/ {print $2}' | awk -F "'" '{print $2}'`
  ip_add=`awk "/${mac_add}/ {print \\$1}" /proc/net/arp`
  echo "<host ip=\"${ip_add}\"><hostname>${VM_NAMES}${i}.${TLD}</hostname></host>"  > ${VM_NAMES}${i}.xml
  virsh net-update ${NET} add dns-host --xml ${VM_NAMES}${i}.xml  --live --config
  scp sshconfig root@${ip_add}:/root/.ssh/config
  scp vagrant root@${ip_add}:/root/.ssh/vagrant
  scp vagrant.pub root@${ip_add}:/root/.ssh/vagrant.pub
  ssh root@${ip_add} 'chmod 600 /root/.ssh/vagrant'
  ssh root@${ip_add} sed -i s#NETWORK#${TLD}#g /root/.ssh/config
  echo ${VM_NAMES}${i}.${TLD} ${ip_add}

done
