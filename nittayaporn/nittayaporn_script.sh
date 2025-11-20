#!/bin/bash

# หาโฟลเดอร์ที่เก็บสคริปต์ (กันปัญหาเวลา cron รันจากที่อื่น)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TEMPLATE="$SCRIPT_DIR/nittayaporn.html"
OUTPUT="$SCRIPT_DIR/index.html"
TMP_HTML="$SCRIPT_DIR/index.tmp"
PROC_ROWS_FILE="$SCRIPT_DIR/process_rows.tmp"

# ----- ดึงข้อมูลจากระบบ -----

# CPU usage %
CPU_USAGE_RAW=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
CPU_PERCENT=$(printf "%.1f%%" "$CPU_USAGE_RAW")
CPU_BAR="$CPU_PERCENT"

# Memory usage
MEM_TEXT=$(free -m | awk 'NR==2 {printf "%s / %s MB (%.1f%%)", $3, $2, $3*100/$2}')
MEM_PERCENT=$(free -m | awk 'NR==2 {printf "%.1f", $3*100/$2}')
MEM_BAR="${MEM_PERCENT}%"

# Storage usage (หน่วย GB) สำหรับ root (/)
read -r TOTAL USED AVAIL USEPERCENT <<< "$(df -BG / | awk 'NR==2 {
  gsub("G","",$2); gsub("G","",$3); gsub("G","",$4); gsub("%","",$5);
  print $2, $3, $4, $5
}')"

STORAGE_TEXT=$(printf "%sG / %sG (%s%% used)" "$USED" "$TOTAL" "$USEPERCENT")
STORAGE_USED="$USED"
STORAGE_FREE="$AVAIL"

# Last updated time
UPDATED_AT=$(date "+%d %b %Y %H:%M:%S")

# ----- ดึง process list จาก ps aux แล้วเขียนลงไฟล์ -----
# เอา 10 แถวแรก (ข้าม header) เรียงตาม %CPU มาก→น้อย
ps aux --sort=-%cpu | awk '
NR==1 {next}          # ข้าม header
NR>11 {exit}          # เอา 10 แถว
{
  user=$1; pid=$2; pcpu=$3; pmem=$4;
  cmd=$11;
  if (NF>11) {
    cmd="";
    for (i=11; i<=NF; i++) {
      cmd = cmd $i (i<NF ? " " : "");
    }
  }
  printf "<tr class=\"hover:bg-purple-100/40 transition\"><td class=\"py-2\">%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>\n", pid, user, pcpu, pmem, cmd;
}' > "$PROC_ROWS_FILE"

# ----- ใช้ sed แทนเฉพาะตัวแปรสั้น ๆ ลงไฟล์ชั่วคราว -----
sed \
  -e "s|__CPU_PERCENT__|$CPU_PERCENT|g" \
  -e "s|__CPU_BAR__|$CPU_BAR|g" \
  -e "s|__MEM_TEXT__|$MEM_TEXT|g" \
  -e "s|__MEM_BAR__|$MEM_BAR|g" \
  -e "s|__STORAGE_TEXT__|$STORAGE_TEXT|g" \
  -e "s|__STORAGE_USED__|$STORAGE_USED|g" \
  -e "s|__STORAGE_FREE__|$STORAGE_FREE|g" \
  -e "s|__UPDATED_AT__|$UPDATED_AT|g" \
  "$TEMPLATE" > "$TMP_HTML"

# ----- แทนที่ __PROCESS_ROWS__ ด้วยเนื้อหาจากไฟล์ process_rows.tmp -----
awk -v rows_file="$PROC_ROWS_FILE" '
{
  if ($0 ~ /__PROCESS_ROWS__/) {
    while ((getline line < rows_file) > 0) {
      print line;
    }
    close(rows_file);
  } else {
    print;
  }
}
' "$TMP_HTML" > "$OUTPUT"

# ลบไฟล์ชั่วคราว
rm -f "$TMP_HTML" "$PROC_ROWS_FILE"

