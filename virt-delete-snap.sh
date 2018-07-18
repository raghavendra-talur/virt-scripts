if [[ -z $1 || -z $2 ]]
then
        echo "need vm name pattern"
        exit 1
fi
vm_name_pattern="$1"
snap_name="$2"
virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        echo  domain "$each";
        virsh snapshot-delete $each --children --snapshotname "$snap_name" ;
done
