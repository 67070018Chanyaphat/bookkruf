#!/bin/bash
TEMPLATE="MyServer_template.html"
OUTPUT="MyServer.html"

# --- CPU ---
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2+$4}' | xargs printf "%.0f")
CPU_CORES=$(nproc)
CPU_THREADS=$((CPU_CORES*2))
if [ $CPU -lt 50 ]; then CPU_BADGE="good"; elif [ $CPU -lt 75 ]; then CPU_BADGE="warning"; else CPU_BADGE="danger"; fi

# --- Memory ---
MEM_USED=$(free -m | awk '/Mem/ {print $3}')
MEM_TOTAL=$(free -m | awk '/Mem/ {print $2}')
MEM_PERCENT=$(( MEM_USED*100/MEM_TOTAL ))
if [ $MEM_PERCENT -lt 50 ]; then MEM_BADGE="good"; elif [ $MEM_PERCENT -lt 75 ]; then MEM_BADGE="warning"; else MEM_BADGE="danger"; fi

# --- Disk ---
DISK_USED=$(df -BG / | awk 'NR==2 {gsub("G","",$3); print $3}')
DISK_TOTAL=$(df -BG / | awk 'NR==2 {gsub("G","",$2); print $2}')
DISK_PERCENT=$(df / | awk 'NR==2 {print int($5)}')
if [ $DISK_PERCENT -lt 50 ]; then DISK_BADGE="good"; elif [ $DISK_PERCENT -lt 75 ]; then DISK_BADGE="warning"; else DISK_BADGE="danger"; fi

# --- Uptime ---
UPTIME_INFO=$(uptime -p | sed 's/up //')
UPTIME_HOURS=$(awk '{print int($1)}' <<< "$(uptime -p | sed 's/[^0-9]*//g')")
UPTIME_PERCENT=$(( UPTIME_HOURS > 24 ? 100 : UPTIME_HOURS*100/24 ))
if [ $UPTIME_PERCENT -lt 50 ]; then UPTIME_BADGE="good"; elif [ $UPTIME_PERCENT -lt 75 ]; then UPTIME_BADGE="warning"; else UPTIME_BADGE="danger"; fi

# --- Network ---
ping -c 1 -W 1 8.8.8.8 &>/dev/null && NETWORK_STATUS="Online" || NETWORK_STATUS="Offline"

# --- Current Time (ไทย) ---
CURRENT_TIME=$(TZ="Asia/Bangkok" date '+%Y-%m-%d %H:%M:%S')

# --- Latest Processes ---
PROCESS_TABLE=$(ps -eo pid,user,pcpu,pmem,comm --sort=-pcpu | head -n 6 | awk 'NR>1{printf "<tr><td>%s</td><td>%s</td><td>%.1f</td><td>%.1f</td><td>%s</td></tr>\n",$1,$2,$3,$4,$5}')

# --- แทนค่าใน template ---
sed -e "s/{{CPU}}/${CPU}/g" \
    -e "s/{{CPU_CORES}}/${CPU_CORES}/g" \
    -e "s/{{CPU_THREADS}}/${CPU_THREADS}/g" \
    -e "s/{{CPU_BADGE}}/${CPU_BADGE}/g" \
    -e "s/{{MEM_PERCENT}}/${MEM_PERCENT}/g" \
    -e "s/{{MEM_USED}}/${MEM_USED}/g" \
    -e "s/{{MEM_TOTAL}}/${MEM_TOTAL}/g" \
    -e "s/{{MEM_BADGE}}/${MEM_BADGE}/g" \
    -e "s/{{DISK_PERCENT}}/${DISK_PERCENT}/g" \
    -e "s/{{DISK_USED}}/${DISK_USED}/g" \
    -e "s/{{DISK_TOTAL}}/${DISK_TOTAL}/g" \
    -e "s/{{DISK_BADGE}}/${DISK_BADGE}/g" \
    -e "s/{{UPTIME_INFO}}/${UPTIME_INFO}/g" \
    -e "s/{{UPTIME_PERCENT}}/${UPTIME_PERCENT}/g" \
    -e "s/{{UPTIME_BADGE}}/${UPTIME_BADGE}/g" \
    -e "s/{{NETWORK_STATUS}}/${NETWORK_STATUS}/g" \
    -e "s/{{CURRENT_TIME}}/${CURRENT_TIME}/g" \
    -e "/{{PROCESS_TABLE}}/{
        r /dev/stdin
        d
    }" "$TEMPLATE" > "$OUTPUT" <<< "$PROCESS_TABLE"

echo "Updated $OUTPUT"
xdg-open "$OUTPUT" 2>/dev/null

