#!/usr/bin/env bash
set -euo pipefail

echo "Collecting Linux/macOS sysinfo…"
HOST=$(hostname)
UPTIME=$(uptime -p || true)
IP=$(hostname -I 2>/dev/null || ipconfig getifaddr en0 2>/dev/null || true)
DF=$(df -h)
TOP=$(ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -10)

printf "Host: %s\n" "$HOST"
echo "Uptime: $UPTIME"
echo "IP(s): $IP"
echo "Disk usage:"
echo "$DF"
echo "Top processes:"
echo "$TOP"
