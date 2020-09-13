#!/bin/bash

SUDO=$(if [ $(id -u $whoami) -gt 0 ]; then echo "sudo "; fi)
IFACE=$(ip route show | grep default | awk '{print $5}')
INET=$(ip address show $IFACE scope global |  awk '/inet / {split($2,var,"/"); print var[1]}')
LOCAL_PORT=$2
REMOTE_IP=$3
REMOTE_PORT=$4

set_forward () {
    if [ -z "$($SUDO cat /etc/sysctl.conf | grep 'net.ipv4.ip_forward = 1')" ]; then
        echo "net.ipv4.ip_forward = 1" | $SUDO tee -a /etc/sysctl.conf
        $SUDO sysctl -p 
    fi
}

forward () {
    set_forward
    $SUDO iptables -t nat -A PREROUTING -p tcp --dport $LOCAL_PORT -j DNAT --to-destination $REMOTE_IP:$REMOTE_PORT  -m comment --comment "FORWARD $LOCAL_PORT->$REMOTE_IP:$REMOTE_PORT"
    $SUDO iptables -t nat -A POSTROUTING -d $REMOTE_IP -p tcp --dport $REMOTE_PORT -j SNAT --to-source $INET -m comment --comment "BACKWARD $LOCAL_PORT->$REMOTE_IP:$REMOTE_PORT"
    $SUDO iptables -A FORWARD -p tcp -d $REMOTE_IP --dport $REMOTE_PORT -j ACCEPT -m comment --comment "UPLOAD $LOCAL_PORT->$REMOTE_IP:$REMOTE_PORT"
    $SUDO iptables -A FORWARD -p tcp -s $REMOTE_IP -j ACCEPT -m comment --comment "DOWNLOAD $LOCAL_PORT->$REMOTE_IP:$REMOTE_PORT"
    $SUDO iptables-save
}

monitor () {
    set_forward
    $SUDO iptables -A INPUT -p tcp -d $INET --dport $LOCAL_PORT -m comment --comment "UPLOAD $LOCAL_PORT->$REMOTE_IP:$REMOTE_PORT"
    $SUDO iptables -A INPUT -p tcp -s $REMOTE_IP -d $INET -m comment --comment "DOWNLOAD $LOCAL_PORT->$REMOTE_IP:$REMOTE_PORT"
    $SUDO iptables-save
}

delete () {
    COMMENT="$LOCAL_PORT->$REMOTE_IP:$REMOTE_PORT"
    while [[ ! -z "$($SUDO iptables -L INPUT --line-numbers | grep $COMMENT)" ]]
    do
        $SUDO iptables -L INPUT --line-numbers | grep $COMMENT | awk '{print $1}' | xargs $SUDO iptables -D INPUT 
    done
    while [[ ! -z "$($SUDO iptables -L OUTPUT --line-numbers | grep $COMMENT)" ]]
    do
        $SUDO iptables -L OUTPUT --line-numbers | grep $COMMENT | awk '{print $1}' | xargs $SUDO iptables -D OUTPUT 
    done
    while [[ ! -z "$($SUDO iptables -L FORWARD --line-numbers | grep $COMMENT)" ]]
    do
        $SUDO iptables -L FORWARD --line-numbers | grep $COMMENT | awk '{print $1}' | xargs $SUDO iptables -D FORWARD 
    done
    while [[ ! -z "$($SUDO iptables -t nat -L PREROUTING --line-numbers | grep $COMMENT)" ]]
    do
        $SUDO iptables -t nat -L PREROUTING --line-numbers | grep $COMMENT | awk '{print $1}' | xargs $SUDO iptables -t nat -D PREROUTING 
    done
    while [[ ! -z "$($SUDO iptables -t nat -L POSTROUTING --line-numbers | grep $COMMENT)" ]]
    do
        $SUDO iptables -t nat -L POSTROUTING --line-numbers | grep $COMMENT | awk '{print $1}' | xargs $SUDO iptables -t nat -D POSTROUTING
    done
}

if [ "$1" == "forward" ]; then
    forward
elif [ "$1" == "monitor" ]; then
    monitor
elif [ "$1" == "delete" ]; then
    delete
else
    echo "Unrecognized command: $1"
fi