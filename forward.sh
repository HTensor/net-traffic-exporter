#!/bin/bash

SUDO=$(if [ $(id -u $whoami) -gt 0 ]; then echo "sudo "; fi)
IFACE=$(ip route show | grep default | awk '{print $5}')
INET=$(ip address show $IFACE scope global |  awk '/inet / {split($2,var,"/"); print var[1]}')

if [ -z $($SUDO cat /etc/sysctl.conf | grep "net.ipv4.ip_forward = 1") ]; then
    echo "net.ipv4.ip_forward = 1" | $SUDO tee -a /etc/sysctl.conf
    $SUDO sysctl -p 
fi

$SUDO iptables -t nat -A PREROUTING -p tcp --dport $1 -j DNAT --to-destination $2:$3
$SUDO iptables -A FORWARD -p tcp -d $2 --dport $3 -j ACCEPT -m comment --comment "UPLOAD $1->$2:$3"
$SUDO iptables -A FORWARD -p tcp -s $2 -j ACCEPT -m comment --comment "DOWNLOAD $1->$2:$3"
$SUDO iptables -t nat -A POSTROUTING -d $2 -p tcp --dport $3 -j SNAT --to-source $INET
$SUDO iptables-save