#!/bin/bash

set -e

if [[ -z $1 || -z $2 ]]
then
        echo "usage $0 vm_name_pattern snap_name"
        exit 1
fi

vm_name_pattern="$1"
snap_name=running"$2"

echo "Taking snapshot of VMs"
virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        echo  domain "$each";
        if virsh snapshot-list --domain "$each" --name | grep -q -w "$snap_name"
        then
                echo "snapshot of given name already exists"
        else
                virsh snapshot-create-as --domain "$each" --name "$snap_name"  --atomic
        fi
done