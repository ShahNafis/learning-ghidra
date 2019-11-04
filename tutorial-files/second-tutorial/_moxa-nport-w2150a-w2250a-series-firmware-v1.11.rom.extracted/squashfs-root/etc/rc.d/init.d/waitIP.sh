#!/bin/sh

ACTIVE=$(cat /var/run/ifactive | awk '{printf $1}')

if [ "$ACTIVE" == "0" ]; then
	IFACE="eth0"
else
	IFACE="wlan0"
fi

chk_static() {
	CHK=$(ifconfig $IFACE | grep inet | awk '{printf $0}')
	if [ "$CHK" != "" ]; then
		exit 1
	fi
}

chk_dynamic() {
	FILE=/var/run/getIP
	if [ -e $FILE ]; then
		CHK=$(cat $FILE | awk '{printf $1}')
		if [ "$CHK" == "1" ]; then
			exit 1
		fi
	fi
}

chk_func=""
chk_type() {
	TYPE=$(cat /configData/etc/network/interfaces | grep "iface $IFACE" | awk '{printf $4}')
	if [ "$TYPE" == "static" ]; then
		chk_func=chk_static
	else
		chk_func=chk_dynamic
	fi
}

chk_type;

T0=0
while [ 1 ]
do
	$chk_func;
	read -p "Enter 'q' to quit this script!!" -t 1 -n 1 char
	if [ "$char" == "q" ]; then
		exit 1
	fi

        # Add this for automatically quit script.
        # For DHCP not getting IP addres, this prevents from blocking forever.
        T0=`expr $T0 + 1`
        if [ $T0 -ge 5 ]; then
                break;
        fi
        echo -e "\r\n"
done

