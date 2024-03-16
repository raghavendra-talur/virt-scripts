#!/bin/bash

set -e

if [[ -z $1 || -z $2 ]]
then
        echo "usage $0 vm_name_pattern snap_name"
        exit 1
fi

vm_name_pattern="$1"
snap_name=off"$2"

#echo "Shutting down VMs"
#virsh list --name --all | grep "$vm_name_pattern" | while read each;
#do
#        echo  domain "$each";
#        virsh shutdown "$each" --mode acpi
#done

echo "Shutting down VMs"
virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        echo  domain "$each";
        minikube stop --profile "$each"
done

#echo "Waiting for VMs to shut down"
#virsh list --name --all | grep "$vm_name_pattern" | while read each;
#do
#        echo  domain "$each";
#        while ! virsh list --name --state-shutoff | grep -q -w "$each"
#        do
#                echo "waiting for ${each} to be shut down"
#                sleep 5
#        done
#        echo "${each} is in shutoff state"
#done

#echo "Waiting for VMs to shut down"
#virsh list --name --all | grep "$vm_name_pattern" | while read each;
#do
#        echo  domain "$each";
#        while ! virsh list --name --state-shutoff | grep -q -w "$each"
#        do
#                echo "waiting for ${each} to be shut down"
#                sleep 5
#        done
#        echo "${each} is in shutoff state"
#done

echo "Taking snapshot of VMs"
virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        echo  domain "$each";
        if virsh snapshot-list --domain "$each" --name | grep -q -w "$snap_name"
        then
                echo "snapshot of given name already exists"
        else
                virsh snapshot-create-as --domain "$each" --atomic --name "$snap_name"
        fi
done

#echo "Starting VMs"
#virsh list --name --all | grep "$vm_name_pattern" | while read each;
#do
#        echo  domain "$each";
#        virsh start "$each"
#done
#
#sleep 10
#
#echo "Waiting for VMs to start"
#virsh list --name --all | grep "$vm_name_pattern" | while read each;
#do
#        echo  domain "$each";
#        while ! virsh list --name --state-running | grep -q -w "$each"
#        do
#                echo "waiting for ${each} to be running"
#                sleep 5
#        done
#        echo "${each} is running"
#done

echo "Waiting for minikube to start"
virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        echo  domain "$each";
        minikube start --profile "$each"
done