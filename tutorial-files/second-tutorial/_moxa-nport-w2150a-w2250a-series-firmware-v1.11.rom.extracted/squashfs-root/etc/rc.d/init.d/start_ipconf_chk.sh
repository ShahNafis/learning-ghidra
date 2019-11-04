#!/bin/sh

# echo "Check start_ipconf_chk process" > /dev/console
pid_info=`pidof start_ipconf_chk.sh`
pid_cnt=`echo $pid_info|wc -w`
#echo "pid_cnt is [$pid_cnt]" > /dev/console
if [ $pid_cnt -gt 1 ]; then
#echo "Process already exist!" > /dev/console
exit 1
fi

while [ 1 ]
do
#	echo "Start ipconf_chk" > /dev/console
	/usr/bin/ipconf_chk 1
	sleep 1
	if [ "$(cat /var/tmp/conflict_ip_check)" == "0" ]; then
		echo "no IP confilict...exit" > /dev/console
		exit 1
	fi
	echo "wait for ipconf_chk"
	sleep 9
done

