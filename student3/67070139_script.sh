#!/usr/bin/env bash
set -euo pipefail

MEMBER_ID="67070139"

TIMESTAMP="$(TZ='Asia/Bangkok' date '+%Y-%m-%d %H:%M:%S')"
HOSTNAME="$(hostname)"
CPU_LOAD_AVG="$(uptime | awk -F'load average:' '{print $2}' | xargs)"
MEM_USED_MB="$(free -m | awk '/Mem:/ {print $3}')"
MEM_TOTAL_MB="$(free -m | awk '/Mem:/ {print $2}')"
DISK_ROOT_USED="$(df -h / | awk 'NR==2 {print $3}')"
DISK_ROOT_TOTAL="$(df -h / | awk 'NR==2 {print $2}')"

sed "s|{{hostname}}|$HOSTNAME|g" index_template.html \
| sed "s|{{timestamp}}|$TIMESTAMP|g" \
| sed "s|{{cpu}}|$CPU_LOAD_AVG|g" \
| sed "s|{{mem_used}}|$MEM_USED_MB|g" \
| sed "s|{{mem_total}}|$MEM_TOTAL_MB|g" \
| sed "s|{{disk_used}}|$DISK_ROOT_USED|g" \
| sed "s|{{disk_total}}|$DISK_ROOT_TOTAL|g" \
| sed "s|{{member}}|$MEMBER_ID|g" \
> index.html

echo "Generated index.html"

