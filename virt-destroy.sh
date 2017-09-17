for each in `virsh list | grep cluster2 | awk '{print $2}'`; do echo  $each; virsh destroy $each; virsh undefine --remove-all-storage $each ; done
