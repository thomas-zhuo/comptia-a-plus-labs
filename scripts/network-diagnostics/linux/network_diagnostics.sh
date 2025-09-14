#!/usr/bin/env bash
# Network Diagnostics (Linux/macOS)
# Runs core connectivity checks and prints a readable report.
# Safe for both macOS (BSD utils) and Linux (GNU utils).

set -u  # warn on unset vars; do NOT set -e so one failure won't kill the script

# -------- Helpers --------
section () { printf "\n==== %s ====\n" "$1"; }
have () { command -v "$1" >/dev/null 2>&1; }

echo "Network Diagnostics Report"
echo "Host     : $(hostname 2>/dev/null || echo unknown)"
echo "OS       : $(uname -srm 2>/dev/null || sw_vers 2>/dev/null || echo unknown)"
echo "Date     : $(date)"

# -------- Interfaces / IP addresses --------
section "Interfaces & IP Addresses"
if have ip; then
  ip -brief addr || ip addr
elif have ifconfig; then
  ifconfig
else
  echo "No 'ip' or 'ifconfig' command found."
fi

# -------- Default gateway / routing --------
section "Default Gateway / Routing"
if have ip; then
  ip route show default || ip route
elif have route; then
  route -n get default 2>/dev/null || route -n 2>/dev/null || netstat -rn 2>/dev/null
else
  echo "No 'ip' or 'route' command found."
fi

# -------- DNS configuration --------
section "DNS Configuration"
if [ -f /etc/resolv.conf ]; then
  echo "From /etc/resolv.conf:"
  grep -E '^(nameserver|search|domain)' /etc/resolv.conf || echo "(no nameserver lines)"
else
  if have scutil; then
    scutil --dns 2>/dev/null | sed -n '1,200p'
  else
    echo "Could not read DNS configuration."
  fi
fi

# -------- Ping basic connectivity --------
section "Ping (ICMP) to 8.8.8.8"
if have ping; then
  ping -c 4 8.8.8.8 2>&1
else
  echo "'ping' not available."
fi

section "Ping (ICMP) to cloudflare.com"
if have ping; then
  ping -c 4 cloudflare.com 2>&1
else
  echo "'ping' not available."
fi

# -------- Traceroute / Tracepath --------
section "Traceroute to cloudflare.com"
if have traceroute; then
  traceroute -n cloudflare.com 2>&1
elif have tracepath; then
  tracepath -n cloudflare.com 2>&1
else
  echo "No 'traceroute' or 'tracepath' found. (macOS: 'brew install traceroute', Debian/Kali: 'sudo apt install traceroute')"
fi

# -------- DNS Lookup (dig/nslookup/getent) --------
section "DNS Lookup for cloudflare.com"
if have dig; then
  dig +short A cloudflare.com 2>&1
elif have nslookup; then
  nslookup cloudflare.com 2>&1
elif have getent; then
  getent hosts cloudflare.com 2>&1
else
  echo "No 'dig'/'nslookup'/'getent' found."
fi

echo
echo "Network diagnostics complete."
