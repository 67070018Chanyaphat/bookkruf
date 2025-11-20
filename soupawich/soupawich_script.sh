#!/bin/bash

PROJECT_DIR="/home/ksoupawich/bookkruf/soupawich"
HTML="$PROJECT_DIR/soupawich.html"

cd "$PROJECT_DIR" || exit 1

CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
MEM=$(free | awk '/Mem/ {printf "%.2f", $3/$2 * 100.0}')
DISK=$(df -h / | awk 'NR==2 {print $5}')
UPDATED=$(TZ="Asia/Bangkok" date +"%Y-%m-%d %H:%M:%S")

sed -i "s|cpu\">.*</p>|cpu\"> $CPU %</p>|" "$HTML"
sed -i "s|mem\">.*</p>|mem\"> $MEM %</p>|" "$HTML"
sed -i "s|disk\">.*</p>|disk\"> $DISK </p>|" "$HTML"
sed -i "s|updated\">.*</p>|updated\"> $UPDATED </p>|" "$HTML"

PROCESS=$(ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 11 | tail -n 10)

TABLE_ROWS=""
while read -r line; do
    [ -z "$line" ] && continue

    PID=$(echo "$line" | awk '{print $1}')
    USER=$(echo "$line" | awk '{print $2}')
    PCPU=$(echo "$line" | awk '{print $3}')
    PMEM=$(echo "$line" | awk '{print $4}')
    CMD=$(echo "$line" | awk '{print $5}')

    TABLE_ROWS="$TABLE_ROWS
<tr><td>$PID</td><td>$USER</td><td>$PCPU</td><td>$PMEM</td><td>$CMD</td></tr>"
done <<< "$PROCESS"

sed -i "/<tbody id=\"process-table\">/,/<\/tbody>/c<tbody id=\"process-table\">$TABLE_ROWS
</tbody>" "$HTML"

git add .
git commit -m "Auto update: $(date '+%Y-%m-%d %H:%M:%S')" || exit 0
git push origin soupawich

