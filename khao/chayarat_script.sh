#!/bin/bash


TEMPLATE_FILE="khaotem.html"
OUTPUT_FILE="chayarat.html"

OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
HOST_NAME=$(hostname)
IP_ADDR=$(hostname -I | awk '{print $1}')
KERNEL_VER=$(uname -r)
UPTIME_INFO=$(uptime -p | sed 's/up //')

CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
MEM_TOTAL=$(free -m | awk '/Mem:/ { print $2 }')
MEM_USED=$(free -m | awk '/Mem:/ { print $3 }')
MEM_PERCENT=$(awk "BEGIN {printf \"%.0f\", $MEM_USED/$MEM_TOTAL*100}")
DISK_USAGE=$(df -h / | awk '$NF=="/" {print $5}' | sed 's/%//')
DISK_TEXT=$(df -h / | awk '$NF=="/" {print $3 " / " $2}')
LAST_UPDATED=$(date "+%d %B %Y • %H:%M")

PROCESS_LIST=$(ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5 | awk '{print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"%</td><td>"$4"%</td><td class=\"cmd\">"$5"</td></tr>"}' | tr -d '\n')

sed -e "s/{{OS_NAME}}/$OS_NAME/g" \
    -e "s/{{HOST_NAME}}/$HOST_NAME/g" \
    -e "s/{{IP_ADDR}}/$IP_ADDR/g" \
    -e "s/{{UPTIME_INFO}}/$UPTIME_INFO/g" \
    -e "s/{{CPU_USAGE}}/$CPU_USAGE/g" \
    -e "s/{{MEM_PERCENT}}/$MEM_PERCENT/g" \
    -e "s/{{MEM_USED}}/$MEM_USED/g" \
    -e "s/{{MEM_TOTAL}}/$MEM_TOTAL/g" \
    -e "s/{{DISK_USAGE}}/$DISK_USAGE/g" \
    -e "s|{{DISK_TEXT}}|$DISK_TEXT|g" \
    -e "s|{{PROCESS_LIST}}|$PROCESS_LIST|g" \
    -e "s/{{LAST_UPDATED}}/$LAST_UPDATED/g" \
    $TEMPLATE_FILE > $OUTPUT_FILE

