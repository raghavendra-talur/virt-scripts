#!/bin/bash

set -e

IMAGES_DIR=/var/lib/libvirt/images

if [[ ! -f "${IMAGES_DIR}/Fedora-Server-KVM-39-1.5.x86_64.qcow2" ]]; then
    wget https://download.fedoraproject.org/pub/fedora/linux/releases/39/Server/x86_64/images/Fedora-Server-KVM-39-1.5.x86_64.qcow2 -P "${IMAGES_DIR}"
fi

cp --sparse=always "${IMAGES_DIR}/Fedora-Server-KVM-39-1.5.x86_64.qcow2" "${IMAGES_DIR}/rtalur-f39-temp.qcow2"

qemu-img resize "${IMAGES_DIR}/rtalur-f39-temp.qcow2" +40G

qemu-img create -f qcow2 "${IMAGES_DIR}/rtalur-f39-customized.qcow2" 40G

virt-resize  --output-format qcow2 --lv-expand /dev/sysvg/root --expand /dev/sda3 "${IMAGES_DIR}/rtalur-f39.qcow2" "${IMAGES_DIR}/rtalur-f39-customized.qcow2"

cp --sparse=always "${IMAGES_DIR}/rtalur-f39.qcow2" "${IMAGES_DIR}/rtalur-f39-customized.qcow2"

virt-customize \
--uninstall cloud-init,ovirt-guest-agent,zram-generator-defaults \
-install qemu-guest-agent,git,vim
--root-password password:file:/home/rtalur/src/github.com/raghavendra-talur/virt-scripts/password.txt \
--ssh-inject root:file:/home/rtalur/.ssh/id_rsa.pub \
--run-command 'useradd rtalur' \
--password rtalur:random  \
--ssh-inject rtalur:file:/home/rtalur/.ssh/id_rsa.pub \
--append-line /etc/sudoers:"rtalur  ALL=(ALL)   NOPASSWD: ALL" \
--touch /.autorelabel  \
--selinux-relabel \
-a "${IMAGES_DIR}/rtalur-f39-customized.qcow2