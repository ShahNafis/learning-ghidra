#!/bin/sh

echo "Disable bridge"
killall bridge

#brctl delif br0 eth0
brctl delif br0 wlan0
#brctl delbr br0


