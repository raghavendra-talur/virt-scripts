#!/bin/bash

BASE_IMAGE="$1"

virt-customize -a ${BASE_IMAGE} --root-password password:vagrant --uninstall cloud-init
virt-customize -a ${BASE_IMAGE} --ssh-inject root:file:~/.ssh/vagrant.pub --selinux-relabel
