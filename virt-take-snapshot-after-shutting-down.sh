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
        if virsh snapshot-list --domain "$each" --name | grep -q -w "$snap_name"
        then
                echo "snapshot of given name already exists"
        else
                virsh shutdown "$each" --mode acpi
                while ! virsh list --name --state-shutoff | grep -q -w "$each"
                do
                        echo "waiting for ${each} to be shut down"
                        sleep 5
                done
                echo "${each} is in shutoff state"
                virsh snapshot-create-as --domain "$each" --atomic --name "$snap_name"
                virsh start "$each"
                while ! virsh list --name --state-running | grep -q -w "$each"
                do
                        echo "waiting for ${each} to be running"
                        sleep 5
                done
                echo "${each} is running"
        fi
done
