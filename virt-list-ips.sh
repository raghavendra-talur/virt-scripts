#!/bin/bash

if [[ -z $1 ]]
then
        echo "usage $0 vm_name_pattern"
        exit 1
fi

vm_name_pattern="$1"

virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        echo  domain "$each";

        vm_ip=$(virsh domifaddr "$each" | awk '/ipv4/ {print $4}' | cut -d'/' -f1)

        if [ -n "$vm_ip" ]; then
            echo "$each - $vm_ip"
        else
            echo "$each - IP not found"
        fi
done

