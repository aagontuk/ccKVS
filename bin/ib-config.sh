#!/usr/bin/env bash
echo 8192 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
echo 8192 > /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages
echo 10000000001 > /proc/sys/kernel/shmall
echo 10000000001 > /proc/sys/kernel/shmmax
IP=$(cat /etc/hosts | grep $(hostname | cut -d . -f 1) | awk '{print $1}')
echo $IP
ifconfig ib0 $IP netmask 255.255.255.0 up
#/etc/init.d/opensmd start 
cat /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages
cat /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages
cat /proc/sys/kernel/shmall
cat /proc/sys/kernel/shmmax
#PCIe counter settings
echo 0 > /proc/sys/kernel/nmi_watchdog
modprobe msr
