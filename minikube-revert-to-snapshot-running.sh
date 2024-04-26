#!/bin/bash

set -e

if [[ -z $1 || -z $2 ]]
then
        echo "usage $0 vm_name_pattern snap_name"
        exit 1
fi

vm_name_pattern="$1"
snap_name="$2"

clusters=$(virsh list --name --all | grep "$vm_name_pattern")

for each in $clusters
do
        echo  domain "${each}";
        virsh snapshot-revert --domain "${each}" --snapshotname "$snap_name" --running
        minikube ssh --profile "${each}" -- sudo systemctl restart systemd-timesyncd
        minikube ssh --profile "${each}" -- date
done

for each in $clusters
do
        if minikube status --profile "${each}"
        then
                echo "minikube profile "${each}" is already running"
                minikube ssh --profile "${each}" -- sudo systemctl restart systemd-timesyncd
                sleep 10
                minikube ssh --profile "${each}" -- date
        else
                #minikube start --profile "${each}"
                echo "minikube profile "${each}" is not running"
        fi
done
