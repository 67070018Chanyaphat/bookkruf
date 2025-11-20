#!/bin/bash

# ======================================================
# CONFIGURATION (แก้ไขตรงนี้ให้ตรงกับเครื่องคุณ)
# ======================================================
# 1. ที่อยู่ของ Folder Git (ต้องใช้ Path เต็ม เผื่อ Cronjob หาไม่เจอ)
REPO_DIR="/home/it67070018/bookkruf/Paint" 
DATA_FILE="system_data.js"

# 2. ชื่อ Network Interface (ดูด้วยคำสั่ง ip link หรือ ifconfig)
IFACE="eth0" 

# ======================================================
# PART 1: เก็บข้อมูลจริงจากระบบ (Real Data Collection)
# ======================================================

# เปลี่ยน Directory ไปที่ Git Repo
cd "$REPO_DIR" || { echo "หา Folder ไม่เจอ: $REPO_DIR"; exit 1; }

# 1. เวลาปัจจุบัน
CURRENT_TIME=$(date +"%H:%M:%S")

# 2. CPU Usage (ดึงจาก top)
# -bn1 = batch mode 1 ครั้ง, grep Cpu, ตัดคำเอาเฉพาะ idle, เอา 100 - idle
CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | awk '{printf "%.0f", $1}')

# 3. Memory Usage (ดึงจาก free -m)
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
if [ "$MEM_TOTAL" -gt 0 ]; then
    MEM_PERCENT=$(awk -v used="$MEM_USED" -v total="$MEM_TOTAL" 'BEGIN {printf "%.0f", (used/total)*100}')
else
    MEM_PERCENT=0
fi
# แปลงหน่วยเป็น GB สวยๆ
MEM_USED_GB=$(awk -v val="$MEM_USED" 'BEGIN {printf "%.1f", val/1024}')
MEM_TOTAL_GB=$(awk -v val="$MEM_TOTAL" 'BEGIN {printf "%.0f", val/1024}')

# 4. Disk Usage (ดึงจาก df ที่ root /)
DISK=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

# 5. Network Speed (วัดความต่างข้อมูลใน 1 วินาที)
R1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
T1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
sleep 1
R2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
T2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

# คำนวณเป็น MB/s
RBPS=$((R2 - R1))
TBPS=$((T2 - T1))
NET_DOWN=$(awk -v val="$RBPS" 'BEGIN {printf "%.2f", val/1024/1024}')
NET_UP=$(awk -v val="$TBPS" 'BEGIN {printf "%.2f", val/1024/1024}')

# 6. Temperature (ถ้าไม่มี sensor ให้เป็น 0)
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
else
    TEMP=0
fi

# ======================================================
# PART 2: สร้างไฟล์ JS (Generate File)
# ======================================================

JS_CONTENT=$(cat <<EOF
window.updateDashboard({
  "time": "$CURRENT_TIME",
  "cpu": $CPU,
  "memPercent": $MEM_PERCENT,
  "memUsed": "$MEM_USED_GB",
  "memTotal": $MEM_TOTAL_GB,
  "disk": $DISK,
  "netDown": "$NET_DOWN",
  "netUp": "$NET_UP",
  "temp": $TEMP
});
EOF
)

echo "$JS_CONTENT" > "$DATA_FILE"
echo "Data updated: $CURRENT_TIME"

# ======================================================
# PART 3: Push ขึ้น GitHub (Git Automation)
# ======================================================

# ตรวจสอบว่ามีการเปลี่ยนแปลงไหม
if [[ -n $(git status -s "$DATA_FILE") ]]; then
    git add "$DATA_FILE"
    git commit -m "Auto-update stats: $CURRENT_TIME"
    git push origin Paint
    echo "Pushed to GitHub successfully."
else
    echo "No changes detected."
fi
