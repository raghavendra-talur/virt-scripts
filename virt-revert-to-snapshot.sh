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
        echo virsh snapshot-revert --domain "${each}" --snapshotname "$snap_name" --running --force
        virsh snapshot-revert --domain "${each}" --snapshotname "$snap_name" --running --force
done

