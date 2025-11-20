#!/usr/bin/env bash
set -euo pipefail

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

BRANCH_NAME="puwanas"
MEMBER_ID="67070139"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

#git checkout main
#git pull origin main

git checkout "$BRANCH_NAME"
#git merge --ff-only main || git rebase main

TIMESTAMP="$(TZ='Asia/Bangkok' date '+%Y-%m-%d %H:%M:%S')"
HOSTNAME="$(hostname)"

LOAD_AVG_STR="$(uptime | awk -F'load average:' '{print $2}' | xargs)"
CPU_LOAD_AVG="$LOAD_AVG_STR"
CPU_CORES="$(nproc)"
CPU_LOAD_1MIN="$(echo "$LOAD_AVG_STR" | cut -d',' -f1 | xargs)"
CPU_PCT="$(awk "BEGIN { if ($CPU_CORES > 0) printf \"%.1f\", ($CPU_LOAD_1MIN / $CPU_CORES) * 100; else print 0 }")"

MEM_USED_MB="$(free -m | awk '/Mem:/ {print $3}')"
MEM_TOTAL_MB="$(free -m | awk '/Mem:/ {print $2}')"
MEM_PCT="$(awk "BEGIN { if ($MEM_TOTAL_MB > 0) printf \"%.1f\", ($MEM_USED_MB / $MEM_TOTAL_MB) * 100; else print 0 }")"

DISK_ROOT_USED="$(df -h / | awk 'NR==2 {print $3}')"
DISK_ROOT_TOTAL="$(df -h / | awk 'NR==2 {print $2}')"
DISK_ROOT_PCT="$(df -P / | awk 'NR==2 { gsub(/%/, "", $5); print $5 }')"

TOP_TABLE_HTML="$(
  ps -eo pid,user,pcpu,pmem,comm --sort=-pcpu | head -n 6 | awk '
    BEGIN {
      print "<table class=\"top-table\"><thead><tr><th>PID</th><th>User</th><th>%CPU</th><th>%MEM</th><th>Command</th></tr></thead><tbody>"
    }
    NR>1 {
      printf "<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", $1, $2, $3, $4, $5
    }
    END {
      print "</tbody></table>"
    }
  '
)"

TEMP_HTML="$(mktemp)"

sed "s|{{hostname}}|$HOSTNAME|g; \
     s|{{timestamp}}|$TIMESTAMP|g; \
     s|{{cpu}}|$CPU_LOAD_AVG|g; \
     s|{{cpu_pct}}|$CPU_PCT|g; \
     s|{{mem_used}}|$MEM_USED_MB|g; \
     s|{{mem_total}}|$MEM_TOTAL_MB|g; \
     s|{{mem_pct}}|$MEM_PCT|g; \
     s|{{disk_used}}|$DISK_ROOT_USED|g; \
     s|{{disk_total}}|$DISK_ROOT_TOTAL|g; \
     s|{{disk_pct}}|$DISK_ROOT_PCT|g; \
     s|{{member}}|$MEMBER_ID|g" index_template.html > "$TEMP_HTML"

awk -v table="$TOP_TABLE_HTML" '
  BEGIN { gsub(/&/, "\\&", table) }
  { gsub(/\{\{top_table\}\}/, table); print }
' "$TEMP_HTML" > index.html

rm "$TEMP_HTML"

git add index.html

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "Update stats for $MEMBER_ID at $TIMESTAMP"
  git push -u origin "$BRANCH_NAME"
  echo "Pushed branch $BRANCH_NAME to origin."
fi

echo "Generated index.html $TIMESTAMP"

