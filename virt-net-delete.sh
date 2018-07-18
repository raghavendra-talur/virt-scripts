#NET="rtalur_vagrant_single_dev obnox_vagrant_dev default vagrant-libvirt rtalur-default"
NET="cns39"

for net in $NET
do
        for each in `ls *.xml`
        do
                echo $each
                virsh net-update $net delete dns-host --xml $each  --live --config
        done
done
