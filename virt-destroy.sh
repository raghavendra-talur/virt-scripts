#!/bin/bash

if [[ -z $1 ]]
then
        echo "need vm name pattern"
        exit 1
fi
vm_name_pattern=$1
virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        echo  domain "$each";
        virsh snapshot-list --roots --name ${each} | while read snaps;
        do
                echo $snaps ;
                virsh snapshot-delete $each --children --snapshotname $snaps ;
	done
        virsh destroy $each;
        virsh undefine --remove-all-storage $each;
done
