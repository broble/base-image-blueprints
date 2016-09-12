#!/bin/bash
mkdir -p /var/log/imagelogs/dmesg
mkdir -p /var/log/imagelogs/ipa
mkdir -p /var/log/imagelogs/ifconfig
mkdir -p /var/log/imagelogs/lspci
mkdir -p /var/log/imagelogs/classnet 
mkdir -p /var/log/imagelogs/dpkg
dmesg > /var/log/imagelogs/dmesg/dmesg_`date +%Y_%m_%d__%H:%M:%S`.log
ip a > /var/log/imagelogs/ipa/ipa_`date +%Y_%m_%d__%H:%M:%S`.log
ifconfig > /var/log/imagelogs/ifconfig/ifconfig_`date +%Y_%m_%d__%H:%M:%S`.log
lspci > /var/log/imagelogs/lspci/lspci_`date +%Y_%m_%d__%H:%M:%S`.log
ls -l /sys/class/net  > /var/log/imagelogs/classnet/classnet_`date +%Y_%m_%d__%H:%M:%S`.log
dpkg -l udev > /var/log/imagelogs/dpkg/dpkg_info.log
dpkg -l biosdevname >> /var/log/imagelogs/dpkg/dpkg_info.log
