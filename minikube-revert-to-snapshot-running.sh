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
        virsh snapshot-revert --domain "${each}" --snapshotname "$snap_name" --running
done

virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        if minikube profile list | grep $each | grep Running
        then
                echo "minikube profile $each is already running"
        else
                minikube start --profile "$each"
        fi
done

echo "current state of the VMs"
virsh list --all | grep "$vm_name_pattern"

echo "current state of the minikube profiles"
minikube profile list | grep "$vm_name_pattern"