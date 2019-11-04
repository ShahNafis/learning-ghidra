#!/bin/sh

MODULE_PATH=/etc/wireless
MODULE_NAME=ar6000

echo 'reset wireless ...'
killall wpa_supplicant
rmmod $MODULE_NAME
wlan_insmod
#insmod $MODULE_PATH/$MODULE_NAME.ko fwpath=$MODULE_PATH

sleep 2
wpa_conn
bridge -i 1 &
