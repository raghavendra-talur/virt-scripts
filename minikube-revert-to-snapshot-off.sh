#!/bin/bash

set -e

if [[ -z $1 || -z $2 ]]
then
        echo "usage $0 vm_name_pattern snap_name"
        exit 1
fi

vm_name_pattern="$1"
snap_name="$2"

virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        echo  domain "$each";
        virsh snapshot-revert --domain "${each}" --snapshotname "$snap_name"
done


echo "current state of the VMs"
virsh list --all | grep "$vm_name_pattern"

#echo "Starting VMs"
#virsh list --name --all | grep "$vm_name_pattern" | while read each;
#do
#        echo  domain "$each";
#        virsh start "$each"
#done


#echo "Wait for VMs and start minikube"
#virsh list --name --all | grep "$vm_name_pattern" | while read each;
#do
#        echo  domain "$each";
#        while ! virsh list --name --state-running | grep -q -w "$each"
#        do
#                echo "waiting for ${each} to be running"
#                sleep 5
#        done
#        echo "${each} is running"
#        minikube start --profile "$each"
#done

echo "Wait for VMs and start minikube"
virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        minikube start --profile "$each"
done