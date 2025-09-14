#!/usr/bin/env bash
# Portable sysinfo for macOS (works on most Linux too)
# Intentionally NOT using `set -e` so one failing command doesn't kill the script.
set -u

echo "Collecting Linux/macOS sysinfo…"

# Hostname / Computer Name
HOST="$(scutil --get ComputerName 2>/dev/null || hostname 2>/dev/null || echo unknown)"

# Uptime (no -p on macOS)
UPTIME="$(uptime 2>/dev/null || echo 'uptime unavailable')"

# IP addresses:
# - Try common Wi-Fi (en0) and wired (en1); fall back to parsing ifconfig; exclude loopback.
IPS="$(
  ipconfig getifaddr en0 2>/dev/null
  ipconfig getifaddr en1 2>/dev/null
  ifconfig 2>/dev/null | awk '/inet /{print $2}' | grep -v '^127\.' | sort -u
)"

# Disk usage
DF="$(df -h 2>/dev/null || echo 'df unavailable')"

# Top processes (BSD ps on macOS)
TOP="$(
  ps -axo pid,comm,%cpu,%mem 2>/dev/null | head -10
)"

printf "Host: %s\n" "$HOST"
echo "Uptime: $UPTIME"
echo "IP(s):"
echo "$IPS"
echo
echo "Disk usage:"
echo "$DF"
echo
echo "Top processes (top 10 by listing order):"
echo "$TOP"

exit 0
cler