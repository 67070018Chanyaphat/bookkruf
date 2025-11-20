#!/bin/bash

HTML_FILE="/home/kenkungkab/Documents/miniproject/67070145/67070145.html"

# เก็บข้อมูล
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
MEM=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
STORAGE=$(df -h / | awk 'NR==2 {print $5}')
UPDATED=$(date "+%Y-%m-%d %H:%M:%S")
TOP_PROC=$(ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 6 | tail -n 5)
TOP_TABLE=""
while read -r PID USER CPU MEM COMM; do
    TOP_TABLE+="<tr><td>$PID</td><td>$USER</td><td>$CPU</td><td>$MEM</td><td>$COMM</td></tr>"
done <<< "$TOP_PROC"

# เขียนข้อมูลลง HTML โดยใช้ sed แทนค่าภายใน span
sed -i "s|<span id=\"cpu\">.*</span>|<span id=\"cpu\">$CPU%</span>|" "$HTML_FILE"
sed -i "s|<span id=\"mem\">.*</span>|<span id=\"mem\">$MEM%</span>|" "$HTML_FILE"
sed -i "s|<span id=\"storage\">.*</span>|<span id=\"storage\">$STORAGE</span>|" "$HTML_FILE"
sed -i "s|<span id=\"lastupdate\">.*</span>|<span id=\"lastupdate\">$UPDATED</span>|" "$HTML_FILE"
sed -i "s|<tbody id=\"top_process\">.*</tbody>|<tbody id=\"top_process\">$TOP_TABLE</tbody>|" "$HTML_FILE"
