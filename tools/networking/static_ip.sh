#! /bin/bash

VAR1=""


#-----MAIN-----
if [ $# -gt 0 ]
then
    VAR1=$1
else
	echo "Usage : $0 <argument1>"
    exit 1;
fi

if [ "$VAR1" == "" ]
then
        echo "Enter a value :"
        read VAR1
fi

NETNAME="enp0s8"
IFNAME="enp0s8"
nmcli con modify $NETNAME ifname $IFNAME ipv4.method manual ipv4.addresses $VAR1
nmcli con down $NETNAME && nmcli con up $NETNAME