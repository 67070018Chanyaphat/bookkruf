#!/bin/bash

# ======================================================
# CONFIGURATION
# ======================================================
REPO_DIR="/home/it67070018/bookkruf/Paint" 
DATA_FILE="system_data.js"
IFACE="ens33" 

# ======================================================
# PART 1: เก็บข้อมูล (และจำลองข้อมูลถ้าค่าเป็น 0)
# ======================================================

cd "$REPO_DIR" || { echo "หา Folder ไม่เจอ: $REPO_DIR"; exit 1; }

# 1. เวลา
CURRENT_TIME=$(TZ="Asia/Bangkok" date +"%H:%M:%S")

# 2. CPU (Real)
CPU=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | awk '{printf "%.0f", $1}')

# 3. Memory (Real)
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
if [ "$MEM_TOTAL" -gt 0 ]; then
    MEM_PERCENT=$(awk -v used="$MEM_USED" -v total="$MEM_TOTAL" 'BEGIN {printf "%.0f", (used/total)*100}')
else
    MEM_PERCENT=0
fi
MEM_USED_GB=$(awk -v val="$MEM_USED" 'BEGIN {printf "%.1f", val/1024}')
MEM_TOTAL_GB=$(awk -v val="$MEM_TOTAL" 'BEGIN {printf "%.0f", val/1024}')

# 4. Disk (Real)
DISK=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')

# 5. Network Speed (Hybrid: Real + Mock if Idle)
# อ่านค่าจริง
R1=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
T1=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)
sleep 1
R2=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
T2=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

RBPS=$((R2 - R1))
TBPS=$((T2 - T1))

# แปลงเป็น MB/s
NET_DOWN=$(awk -v val="$RBPS" 'BEGIN {printf "%.2f", val/1024/1024}')
NET_UP=$(awk -v val="$TBPS" 'BEGIN {printf "%.2f", val/1024/1024}')

# --- [ส่วนแก้ไขพิเศษ] ถ้าเน็ตเป็น 0.00 ให้สุ่มเลขหลอกๆ เพื่อความสวยงาม ---
if [ "$NET_DOWN" == "0.00" ]; then
    # สุ่มเลขระหว่าง 0.1 ถึง 5.0 MB/s
    NET_DOWN=$(awk 'BEGIN{srand(); printf "%.2f", 0.1+rand()*4.9}')
fi

if [ "$NET_UP" == "0.00" ]; then
    # สุ่มเลขระหว่าง 0.1 ถึง 2.0 MB/s
    NET_UP=$(awk 'BEGIN{srand(); printf "%.2f", 0.1+rand()*1.9}')
fi
# -----------------------------------------------------------------


# 6. Temperature (Hybrid: Real + Mock if Missing)
if [ -f /sys/class/thermal/thermal_zone0/temp ]; then
    TEMP=$(( $(cat /sys/class/thermal/thermal_zone0/temp) / 1000 ))
else
    # --- [ส่วนแก้ไขพิเศษ] ถ้าไม่มีเซ็นเซอร์ ให้สุ่มค่า 40-60 องศา ---
    TEMP=$(( 40 + RANDOM % 21 ))
fi

# ======================================================
# PART 2: สร้างไฟล์ JS
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
echo "Data updated: $CURRENT_TIME (With Mock Data if needed)"

# ======================================================
# PART 3: Push ขึ้น GitHub
# ======================================================

if [[ -n $(git status -s "$DATA_FILE") ]]; then
    git add "$DATA_FILE"
    git commit -m "Auto-update stats: $CURRENT_TIME"
    git push origin Paint
    echo "Pushed to GitHub successfully."
else
    echo "No changes detected."
fi
