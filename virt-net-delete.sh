for each in `ls *.xml`; do echo $each ;  virsh net-update rtalur-default delete dns-host --xml $each  --live --config; done
