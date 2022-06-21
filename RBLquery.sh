#!/bin/sh

PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

echo "Input You Want to search RBL IP."
echo "IP: "
read ip

RBLIP=`echo -e $ip|awk -F. '{print $4"."$3"."$2"."$1}'`

#echo $RBLIP
for RBL in bl.spamcop.net cbl.abuseat.org cbl.anti-spam.org.cn dnsbl.sorbs.net pbl.spamhaus.org psbl.surriel.com rbl.softsqr.com;do
        dig A $RBLIP.$RBL 8.8.8.8|grep 127
done
