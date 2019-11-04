#!/bin/sh
SRCPATH="/etc/default/"
DESTPATH="/configData/wireless/"
DESTFILE="wpa_supplicant"
mkdir -p $DESTPATH

if [ ! -f ${DESTPATH}${DESTFILE}0.conf ]; then
    cp ${SRCPATH}${DESTFILE}_adhoc.conf ${DESTPATH}${DESTFILE}0.conf
fi

#for i in 1 2 3
for i in 1
do
    if [ ! -f ${DESTPATH}${DESTFILE}$i.conf ]; then
        cp ${SRCPATH}${DESTFILE}_infra.conf ${DESTPATH}${DESTFILE}$i.conf
        sed -i 's/""/"profile'$i'"/g' ${DESTPATH}${DESTFILE}$i.conf
    fi
done
