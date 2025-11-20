#!/bin/bash

TEMPLATE_FILE="/home/kenkungkab/miniproject/67070145/67070145.html"
OUTPUT_FILE="/home/kenkungkab/miniproject/67070145/yossaphol.html"

# เก็บข้อมูลระบบ
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
MEM=$(free | grep Mem | awk '{printf "%.0f", $3/$2*100}')
STORAGE=$(df -h / | awk 'NR==2 {print $5}')
UPDATED=$(date "+%Y-%m-%d %H:%M:%S")

# top 5 process
TOP_PROC=$(ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5)
TOP_TABLE=""
while read -r PID USER CPU_P MEM_P COMM; do
    TOP_TABLE+="<tr><td>$PID</td><td>$USER</td><td>$CPU_P%</td><td>$MEM_P%</td><td>$COMM</td></tr>"
done <<< "$TOP_PROC"

# สร้าง HTML จาก template
sed -e "s|{{CPU_USAGE}}|$CPU%|g" \
    -e "s|{{MEM_USAGE}}|$MEM%|g" \
    -e "s|{{STORAGE_USAGE}}|$STORAGE|g" \
    -e "s|{{LAST_UPDATED}}|$UPDATED|g" \
    -e "s|{{TOP_PROCESS_LIST}}|$TOP_TABLE|g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

