#!/bin/bash

# Configuration
VMNAMES="play"
NVMS="${NVMS:-4}"
CPUS="${CPUS:-2}"
RAM="${RAM:-4096}"
DISKSZ="${DISKSZ:-20G}"
NDISKS="${NDISKS:-1}"

# Directories
STOREDIR="/var/lib/libvirt/images/"

# Libvirt Images
fedoraUrl="https://download.fedoraproject.org/pub/fedora/linux/releases/27/CloudImages/x86_64/images/Fedora-Cloud-Base-Vagrant-27-1.6.x86_64.vagrant-libvirt.box"
centosUrl="http://cloud.centos.org/centos/7/vagrant/x86_64/images/CentOS-7.LibVirt.box"

# Vagrant Key
privSshKey="https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant"


# For now only fedora and centos systems are supported
function installDep() {

  if test $(id -u) != 0 ; then
    SUDO=sudo
  fi

  if [ y$(uname)y = yLinuxy ]; then
    source /etc/os-release
    case ${ID} in
      fedora|centos)
        echo "Checking dependencies on localhost, this might take a while..."
        ${SUDO} yum install -y wget openssh &> /dev/null
        ${SUDO} yum install -y qemu-common qemu-img qemu-kvm qemu-system-x86 libvirt virsh virt-install &> /dev/null
        ;;
      *)
        echo "TODO: only fedora/centos are supported for now!"
        ;;
    esac
  else
    echo "TODO: only Linux is supported for now!"
    exit 1
  fi
}


function usage() {

cat <<USAGE
Usage:
  ./vm-play.sh [create <distro>] [destroy <distro>] [list] [help|usage]
USAGE
}


function create() {

  for i in $(seq 1 ${NVMS}); do
    local diskString=""
    echo "# Preparing to create VM$i::"

    echo -e "\nCreating OS disk..."
    qemu-img create -f qcow2 -b ${STOREDIR}/box-${OSDISTRO}.qcow2 "/var/lib/libvirt/images/${VMNAMES}-${OSDISTRO}-${i}.qcow2"

    echo -e "\nCreating extra ${NDISKS} disk[s]..."
    for j in $(seq 1 ${NDISKS})
    do
      qemu-img create -f qcow2 "/var/lib/libvirt/images/${VMNAMES}-${OSDISTRO}-${i}-disk${j}.qcow2" ${DISKSZ}
      diskString=${diskString}"--disk /var/lib/libvirt/images/${VMNAMES}-${OSDISTRO}-${i}-disk${j}.qcow2,format=qcow2,device=disk,bus=virtio "
    done

    echo -e "\nProvisioning VM..."
    virt-install --import                                                                       \
      --name  ${VMNAMES}-${OSDISTRO}-${i}                                                       \
      --ram   ${RAM}                                                                            \
      --vcpus ${CPUS}                                                                           \
      --os-type=linux                                                                           \
      --os-variant=${OSVARIANT}                                                                 \
      --disk ${STOREDIR}/${VMNAMES}-${OSDISTRO}-${i}.qcow2,format=qcow2,device=disk,bus=virtio  \
      ${diskString}                                                                             \
      --network bridge=virbr0,model=virtio                                                      \
      --vnc --noautoconsole
    local macAddr=$(virsh  dumpxml ${VMNAMES}-${OSDISTRO}-${i} | awk -F "=" '/mac address/ {print $2}' | awk -F "'" '{print $2}')

    # Get out as soon as you see an IP
    for j in {1..300}; do
      local ipAddr=`awk "/${macAddr}/ {print \\$1}" /proc/net/arp`
      if [[ "x${ipAddr}" != "x" ]]; then
        break;
      fi
      sleep 1;
    done

    # Making VM's ready for password-less ssh login
    if [ "${ipAddr}x" != "x" ] && [ -f  ~/.ssh/id_rsa.pub ]; then
      if [[ ! -f  ~/.ssh/id_rsa.pub ]]; then
        echo "No public key found, let us create one for you"
        ssh-keygen -f ~/.ssh/id_rsa -t rsa -N '' &> /dev/null
      fi

      echo "Copying localhost ssh public key to ${ipAddr}..."
      for j in {1..300}; do
        cat ~/.ssh/id_rsa.pub | ssh -oStrictHostKeyChecking=no -i ~/.ssh/vagrant.priv vagrant@${ipAddr} "cat >> ~/.ssh/authorized_keys" &> /dev/null
        ret=$?
        if [[ ${ret} -eq 0 ]]; then
          break;
        fi
        sleep 1
      done

      # Create a root user and make it password-less ssh
      if [[ ${ret} -eq 0 ]]; then
        ssh -oStrictHostKeyChecking=no vagrant@${ipAddr} 'echo -e "vagrant\nvagrant" | sudo passwd root && sudo cp /home/vagrant/.ssh /root/ -a && sudo chown -R root:root /root/.ssh' &> /dev/null
        ret=$?
        if [[ ${ret} -ne 0 ]]; then
          echo "creating a root user failed..."
        fi
      else
        echo "copying ssh pub key to VM failed..."
      fi
    fi


    echo -e "\nDetails:\nVMname=${VMNAMES}-${OSDISTRO}-${i} IPaddr=${ipAddr}"
    echo -e "Just in case password-less ssh doesn't help, look for below options"
    echo -e "You can ssh as '# ssh -i ~/.ssh/vagrant.priv vagrant@${ipAddr}'"
    echo -e "Or use Credentials 'login:vagrant password:vagrant'"
    echo -e "Or 'login:root password:vagrant' should work if every thing went well :)\n"

    echo -e "**\n"
  done
}


function destroy() {

    for i in $(seq 1 ${NVMS}); do
      virsh destroy ${VMNAMES}-${OSDISTRO}-${i}
      virsh undefine ${VMNAMES}-${OSDISTRO}-${i}
    done
}


function list() {
  local list=$(virsh list --all | grep "${VMNAMES}-" | awk '{printf "%s %s\n", $2, $3}')

  IFS=$'\n'
  echo "   VMname        Status         IPaddr"
  echo "-------------------------------------------"
  for item in ${list}; do
    local macAddr=""
    local ipAddr="-"
    if [[ $(echo $item | grep -c "running") -eq 1 ]]; then
      macAddr=$(virsh  dumpxml $(echo $item | awk '{print $1}')  | awk -F "=" '/mac address/ {print $2}' | awk -F "'" '{print $2}')
      ipAddr=`awk "/${macAddr}/ {print \\$1}" /proc/net/arp`
      if [[ "${ipAddr}x" == "x" ]]; then
        ipAddr='N/A'
      fi
    fi
    echo "$(echo $item | awk '{print $1}')    $(echo $item | awk '{print $2}')    ${ipAddr}"
  done
}


function downloadImage() {
  local filename=$(basename ${URL})

  echo -e "Downloading ${OSDISTRO} libvirt image, this might take a while...\n"
  cd ${STOREDIR}
  wget -N ${URL} &> /dev/null
  if [[ ! -f ${filename} ]]; then
        echo "libvirt image downloading failed..."
        exit 1;
  fi
  tar -xzf ${filename} &> /dev/null
  if [[ $? -ne 0 ]]; then
    echo "extracting ${filename} failed..."
    exit 1;
  fi
  mv box.img box-${OSDISTRO}.qcow2
  cd - &> /dev/null

  wget ${privSshKey} -O ~/.ssh/vagrant.priv &> /dev/null
  if [[ ! -f ~/.ssh/vagrant.priv ]]; then
        echo "vagrant private key downloading failed..."
        exit 1;
  fi
  chmod 600 ~/.ssh/vagrant.priv
}


function setOsEnvVar() {

  if [[ "${1}" -eq 1 ]]; then
    echo "distro is missing!"
    usage;
    exit 1;
  fi

  if [[ "${2}" == "fedora" ]]; then
    OSDISTRO="fedora"
    OSVARIANT="fedora24"
    URL=${fedoraUrl}
  elif [[ "${2}" == "centos" ]]; then
    OSDISTRO="centos"
    OSVARIANT="rhel7"
    URL=${centosUrl}
  else
    echo "distro can be 'fedora' or centos' only"
    usage;
    exit 1;
  fi
}


# main
case ${1} in
  create)
    setOsEnvVar "${#}" "${2}"

    installDep
    downloadImage
    create
    ;;
  destroy)
    setOsEnvVar "${#}" "${2}"

    destroy
    ;;
  list)

    list
    ;;
  *)
    usage
    ;;
esac
