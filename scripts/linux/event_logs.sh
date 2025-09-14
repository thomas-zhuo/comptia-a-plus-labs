#!/usr/bin/env bash
# Event Log Collector (Linux/macOS) — display only
# Prints recent system and error logs for troubleshooting.

set -u
section() { printf "\n==== %s ====\n" "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "Event Log Collector Report"
echo "Host : $(hostname 2>/dev/null || echo unknown)"
echo "OS   : $(uname -srm 2>/dev/null || sw_vers 2>/dev/null || echo unknown)"
echo "Date : $(date)"

# ----- Linux (systemd-based) -----
if have journalctl; then
  section "Recent Journal Entries (last 50)"
  journalctl -n 50 --no-pager

  section "Recent Errors/Warnings (last 50)"
  journalctl -p 3 -n 50 --no-pager
fi

# ----- Linux (non-systemd, classic syslog) -----
if [ -f /var/log/syslog ]; then
  section "/var/log/syslog (last 50)"
  tail -n 50 /var/log/syslog
elif [ -f /var/log/messages ]; then
  section "/var/log/messages (last 50)"
  tail -n 50 /var/log/messages
fi

# ----- macOS (Unified logging system) -----
if have log; then
  section "macOS System Log (last 50 lines)"
  log show --style syslog --last 1h | tail -n 50
fi

echo
echo "Event log collection complete."
