#!/bin/bash
# Description: Daily nmap port scan to detect changes on the perimeter.
# Author: Jon Furmanski
# Date: 8/21/2018
# Version: 1.0.0
# Version Notes: 
# 1.0.0 - 8/21/2018 - initial release

#Direcory where the scan result files and diffs will be taking place. Make sure this folder is already created!
DIRPATH="/root/results"

#Add target IP addresses in the targets variable. You can add mutiple blocks using cider and a space between them. 
TARGETS="127.0.0.1/32 192.168.0.1/24"

#Add any excluded IP addresses in this field if required.
EXCLUSIONS="--exclude 192.168.0.10 192.168.0.244"

#Add any standard nmap options to this scan. Here is the refence for nmap scan options: https://nmap.org/book/man-briefoptions.html
#The default setup is to scan the top 1000 most popular ports. 
OPTIONS="-T3"

#Add email(s) below. Note you can add multiple emails just by adding a space between them. 
EMAIL="alert@alertdomain.local alert2@alertdomain.local"

#Store the current date in the "date" variable. 
date=`date +%F`

#Change directory into results directory
cd $DIRPATH

#Run nmap scan with no shell output
nmap $OPTIONS $TARGETS $EXCLUSIONS -oA scan-$date > /dev/null

#Logic to check if a previous scan exists to compare against and do a diff
#Note: To have mail work correctly in the below statements, we configured postfix as our mail relay on the localhost. You may need to modify this to sent to an SMTP server of your choosing. 
if [ -e scan-prev.xml ]; then
        ndiff scan-prev.xml scan-$date.xml > diff-$date
        if [ $(wc -l < diff-$date) -ge "3" ]
        then
                tail -n +3 diff-$date | mail -s "ALERT: Daily perimeter scan found asset changes on $date" -a "X-Priority:1" -aFrom:SERVER\<no-reply@domain.local\> $EMAIL
        else
                echo "Daily perimeter scan found no asset changes on $date."  | mail -s "Daily perimeter scan found no asset changes on $date" -aFrom:SERVER\<no-reply@domain.local\> $EMAIL > /dev/null
        fi
fi
ln -sf scan-$date.xml scan-prev.xml
