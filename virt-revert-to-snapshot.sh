if [[ -z $1 ]]
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

