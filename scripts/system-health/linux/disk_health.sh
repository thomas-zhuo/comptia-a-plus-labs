#!/usr/bin/env bash
# Disk & Storage Health (Linux/macOS) — display only
# Safe for both GNU/Linux and macOS (BSD). No file writes.

set -u  # warn on unset vars; avoid set -e so one failure won't kill the script

section() { printf "\n==== %s ====\n" "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "Disk & Storage Health Report"
echo "Host : $(hostname 2>/dev/null || echo unknown)"
echo "OS   : $(uname -srm 2>/dev/null || sw_vers 2>/dev/null || echo unknown)"
echo "Date : $(date)"

# ----- Basic usage / mounts -----
section "Filesystems (human-readable)"
if have df; then
  df -h
else
  echo "df not found"
fi

section "Mounted Filesystems"
if have mount; then
  # Linux/macOS both support 'mount' listing
  mount | sed -n '1,200p'
fi

# ----- Block devices / disks -----
case "$(uname -s)" in
  Linux)
    section "Block Devices (lsblk)"
    if have lsblk; then
      lsblk -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINT,MODEL,STATE
    else
      echo "lsblk not found (try: sudo apt install util-linux)"
    fi

    section "SMART/Health (smartctl)"
    if have smartctl; then
      # Show summary for all /dev/sd* and /dev/nvme* if present
      for d in /dev/sd? /dev/nvme?n?; do
        [ -e "$d" ] || continue
        echo "--- $d ---"
        sudo smartctl -H "$d" 2>&1 || smartctl -H "$d" 2>&1
      done
    else
      echo "smartctl not found (install smartmontools)"
    fi

    section "NVMe List (if available)"
    if have nvme; then
      sudo nvme list 2>/dev/null || nvme list
    else
      echo "nvme cli not found (optional)"
    fi
    ;;
  Darwin)
    section "Disk Layout (diskutil list)"
    if have diskutil; then
      diskutil list
    else
      echo "diskutil not found"
    fi

    section "Disk Details (diskutil info -all)"
    if have diskutil; then
      diskutil info -all | sed -n '1,200p'
      echo "...(truncated — run 'diskutil info -all' to see everything)"
    fi

    section "NVMe Details (system_profiler)"
    if have system_profiler; then
      system_profiler SPNVMeDataType | sed -n '1,200p'
    fi
    ;;
  *)
    section "Unknown platform"
    ;;
esac

echo
echo "Disk & storage health check complete."