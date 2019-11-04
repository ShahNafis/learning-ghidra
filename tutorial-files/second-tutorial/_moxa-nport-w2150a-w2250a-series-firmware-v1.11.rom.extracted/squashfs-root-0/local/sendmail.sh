#/bin/bash
if [ "$6" == "1" ]; then
/bin/busybox sendmail -S "$2" -f "$3" -au"$7" -ap"$8" -w 10 "$4" < /var/sendmail_"$1" > /var/sendmail_temp 2>&1
else
/bin/busybox sendmail -S "$2" -f "$3" -w 10 "$4" < /var/sendmail_"$1" > /var/sendmail_temp 2>&1
fi
mv /var/sendmail_temp $5
rm /var/sendmail_"$1" 

