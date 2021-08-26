#!/bin/bash

#read this and try to get the Vagrantfile itself to do this properly
#https://github.com/hashicorp/vagrant/issues/8374
#From https://gist.github.com/adaroobi/fea2727be6ae3d9c446767f813146f93
#
#https://www.serverlab.ca/tutorials/virtualization/how-to-auto-upgrade-virtualbox-guest-additions-with-vagrant/
#might be able to get this alternate approach to work in the Vagrantfile:
#vagrant plugin install vagrant-vbguest
#vagrant vbguest --do install --no-cleanup



# Find the appropriate version here http://download.virtualbox.org/virtualbox/
sudo VBOX_VERSION_ON_HOST_OS=6.1.22

sudo rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo rpm -Uvh http://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/d/dkms-2.6.1-1.el7.noarch.rpm
sudo yum -y install wget perl gcc dkms kernel-devel kernel-headers make bzip2

wget http://download.virtualbox.org/virtualbox/${VBOX_VERSION_ON_HOST_OS}/VBoxGuestAdditions_${VBOX_VERSION_ON_HOST_OS}.iso

sudo mkdir /media/VBoxGuestAdditions
sudo mount -o loop,ro VBoxGuestAdditions_${VBOX_VERSION_ON_HOST_OS}.iso /media/VBoxGuestAdditions

sudo sh /media/VBoxGuestAdditions/VBoxLinuxAdditions.run

rm -f VBoxGuestAdditions_${VBOX_VERSION_ON_HOST_OS}.iso
sudo umount /media/VBoxGuestAdditions
sudo rmdir /media/VBoxGuestAdditions
sudo unset VBOX_VERSION