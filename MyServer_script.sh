#!/bin/bash

HTML_FILE="MyServer.html"

# ดึงข้อมูลระบบ
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | xargs printf "%.1f")
MEM=$(free -h | awk '/Mem/ {print $3 "/" $2}')
DISK=$(df -h / | awk 'NR==2 {print $3 "/" $2}')
DATE=$(date '+%Y-%m-%d %H:%M:%S')
USERS=$(who | wc -l)
UPTIME=$(uptime -p)

# สร้าง HTML ใหม่ทั้งหมด
cat << EOF > "$HTML_FILE"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>MyServer Status</title>
<style>
body { font-family: Arial, sans-serif; background-color: #f5f5f5; padding:20px; }
.card { background:#fff; padding:20px; border-radius:10px; box-shadow:0 0 10px #ccc; }
h1 { color:#2c3e50; }
ul { list-style:none; padding:0; }
li { padding:6px 0; }
</style>
</head>
<body>
<div class="card">
<h1>MyServer - System Information</h1>
<ul>
<li><b>CPU Usage:</b> $CPU%</li>
<li><b>Memory Usage:</b> $MEM</li>
<li><b>Disk Usage:</b> $DISK</li>
<li><b>Logged-in Users:</b> $USERS</li>
<li><b>Uptime:</b> $UPTIME</li>
<li><b>Last Updated:</b> $DATE</li>
</ul>
</div>
</body>
</html>
EOF

echo "Updated $HTML_FILE"

