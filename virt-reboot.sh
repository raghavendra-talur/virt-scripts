if [[ -z $1 ]]
then
        echo "usage $0 vm_name_pattern"
        exit 1
fi
vm_name_pattern="$1"
virsh list --name --all | grep "$vm_name_pattern" | while read each;
do
        echo  domain "$each";
	virsh reboot "$each"
done

