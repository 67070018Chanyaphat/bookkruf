#!/bin/bash

TEMPLATE_FILE="/home/kenkungkab/miniproject/67070145/67070145.html"
OUTPUT_FILE="/home/kenkungkab/miniproject/67070145/index.html"

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
MEM=$(free | grep Mem | awk '{printf "%.0f", $3/$2*100}')
STORAGE=$(df -h / | awk 'NR==2 {print $5}')
UPDATED=$(date "+%Y-%m-%d %H:%M:%S")

TOP_PROC=$(ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5)

TOP_TABLE=""
while read -r PID USER CPU_P MEM_P COMM; do
    TOP_TABLE+="<tr><td>$PID</td><td>$USER</td><td>$CPU_P%</td><td>$MEM_P%</td><td>$COMM</td></tr>"
done <<< "$TOP_PROC"

escape_sed() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

CPU_ESC=$(escape_sed "$CPU%")
MEM_ESC=$(escape_sed "$MEM%")
STORAGE_ESC=$(escape_sed "$STORAGE")
TOP_TABLE_ESC=$(escape_sed "$TOP_TABLE")
UPDATED_ESC=$(date "+%Y-%m-%d %H:%M:%S")

sed -e "s/{{ CPU_USAGE }}/$CPU_ESC/g" \
    -e "s/{{ MEM_USAGE }}/$MEM_ESC/g" \
    -e "s/{{ STORAGE_USAGE }}/$STORAGE_ESC/g" \
    -e "s|{{ TOP_PROCESS_LIST }}|$TOP_TABLE_ESC|g" \
    -e "s/{{ LAST_UPDATED }}/$UPDATED_ESC/g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"
