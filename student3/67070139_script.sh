#!/usr/bin/env bash
set -euo pipefail

MEMBER_ID="67070139"

TIMESTAMP="$(TZ='Asia/Bangkok' date '+%Y-%m-%d %H:%M:%S')"
HOSTNAME="$(hostname)"

LOAD_AVG_STR="$(uptime | awk -F'load average:' '{print $2}' | xargs)"
CPU_LOAD_AVG="$LOAD_AVG_STR"
CPU_CORES="$(nproc --all)"
CPU_LOAD_1MIN="$(echo "$LOAD_AVG_STR" | cut -d',' -f1 | xargs)"
CPU_PCT="$(awk "BEGIN { if ($CPU_CORES > 0) printf \"%.1f\", ($CPU_LOAD_1MIN / $CPU_CORES) * 100; else print 0 }")"

MEM_USED_MB="$(free -m | awk '/Mem:/ {print $3}')"
MEM_TOTAL_MB="$(free -m | awk '/Mem:/ {print $2}')"
MEM_PCT="$(awk "BEGIN { if ($MEM_TOTAL_MB > 0) printf \"%.1f\", ($MEM_USED_MB / $MEM_TOTAL_MB) * 100; else print 0 }")"

DISK_ROOT_USED="$(df -h / | awk 'NR==2 {print $3}')"
DISK_ROOT_TOTAL="$(df -h / | awk 'NR==2 {print $2}')"
DISK_ROOT_PCT="$(df -P / | awk 'NR==2 { gsub(/%/, "", $5); print $5 }')"

sed "s|{{hostname}}|$HOSTNAME|g" index_template.html \
| sed "s|{{timestamp}}|$TIMESTAMP|g" \
| sed "s|{{cpu}}|$CPU_LOAD_AVG|g" \
| sed "s|{{cpu_pct}}|$CPU_PCT|g" \
| sed "s|{{mem_used}}|$MEM_USED_MB|g" \
| sed "s|{{mem_total}}|$MEM_TOTAL_MB|g" \
| sed "s|{{mem_pct}}|$MEM_PCT|g" \
| sed "s|{{disk_used}}|$DISK_ROOT_USED|g" \
| sed "s|{{disk_total}}|$DISK_ROOT_TOTAL|g" \
| sed "s|{{disk_pct}}|$DISK_ROOT_PCT|g" \
| sed "s|{{member}}|$MEMBER_ID|g" \
> index.html

echo "Generated index.html"

