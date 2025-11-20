#!/bin/bash

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')

MEM=$(free | grep Mem | awk '{print $3/$2 * 100.0}')

DISK=$(df -h / | awk 'NR==2 {print $5}')

UPDATED=$(TZ="Asia/Bangkok" date +"%Y-%m-%d %H:%M:%S")

HTML="./soupawich.html"

sed -i "s|CPU Usage:</span>.*</p>|CPU Usage:</span> $CPU </p>|" "$HTML"
sed -i "s|Memory Usage:</span>.*</p>|Memory Usage:</span> $MEM </p>|" "$HTML"
sed -i "s|Disk Usage:</span>.*</p>|Disk Usage:</span> $DISK </p>|" "$HTML"
sed -i "s|Last Updated:</span>.*</p>|Last Updated:</span> $UPDATED </p>|" "$HTML"

