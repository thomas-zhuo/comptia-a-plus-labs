#!/usr/bin/env bash
# Antivirus / Endpoint Protection Status (Linux + macOS) — DISPLAY ONLY
# - Linux: ClamAV (clamd/freshclam), signature DB freshness
# - macOS: Gatekeeper, XProtect (version), SIP, plus ClamAV if installed (Homebrew)

set -euo pipefail

bold() { printf "\n\033[1m%s\033[0m\n" "$*"; }
info() { printf "  %s\n" "$*"; }
warn() { printf "\033[33m! %s\033[0m\n" "$*"; }

OS_NAME="$(uname -s)"
HOST="$(hostname)"
NOW="$(date '+%F %T %Z')"

bold "Antivirus / Endpoint Protection Status"
info "Host: $HOST"
info "OS  : $OS_NAME ($(uname -r))"
info "Date: $NOW"

have() { command -v "$1" >/dev/null 2>&1; }

# ---------- Common: ClamAV (both Linux and macOS via Homebrew) ----------
check_clamav() {
  bold "ClamAV (if installed)"
  if have clamscan; then
    info "clamscan version: $(clamscan --version 2>/dev/null || echo 'unknown')"
  else
    info "clamscan not found on PATH"
  fi

  if have freshclam; then
    info "freshclam version: $(freshclam --version 2>/dev/null | head -n1 || echo 'unknown')"
  else
    info "freshclam not found on PATH (signatures may not auto-update)"
  fi

  # Try to locate signature DB folder and show file mtimes
  # Common paths (extend as needed)
  db_paths=(
    "/var/lib/clamav"
    "/usr/local/var/lib/clamav"
    "/opt/homebrew/var/lib/clamav"
  )
  found=0
  for p in "${db_paths[@]}"; do
    if [ -d "$p" ]; then
      found=1
      bold "ClamAV Signature DB (latest timestamps) — $p"
      ls -lh --time-style=+'%F %T' "$p"/{daily,main,bytecode}.c*l* 2>/dev/null | awk '{print "  " $6 " " $7 "  " $5 "  " $9}'
    fi
  done
  if [ $found -eq 0 ]; then
    info "Signature DB directory not found in common paths"
  fi

  # Service status (Linux systemd units)
  if [ "$OS_NAME" = "Linux" ] && have systemctl; then
    bold "ClamAV Service Status (systemd)"
    # Try common unit names without failing the script
    for svc in clamav-daemon clamd clamd@scan; do
      if systemctl list-unit-files | grep -q "^${svc}\."; then
        state="$(systemctl is-active "$svc" 2>/dev/null || true)"
        enabled="$(systemctl is-enabled "$svc" 2>/dev/null || true)"
        info "$svc: active=$state, enabled=$enabled"
      fi
    done
  fi
}

# ---------- Linux-only checks (room to extend later) ----------
linux_checks() {
  bold "Linux Endpoint Checks"
  # Placeholder: distro-specific AVs could be added here if needed (e.g., Sophos/CrowdStrike presence checks)
  check_clamav
}

# ---------- macOS checks: Gatekeeper, XProtect, SIP ----------
macos_checks() {
  bold "macOS Endpoint Protection"

  # Gatekeeper
  if have spctl; then
    bold "Gatekeeper"
    spctl --status || warn "spctl status command failed"
  else
    info "spctl not found"
  fi

  # XProtect (version info from bundle Info.plist)
  bold "XProtect"
  XP_BUNDLE="/System/Library/CoreServices/XProtect.bundle/Contents/Info.plist"
  if [ -f "$XP_BUNDLE" ] && have /usr/libexec/PlistBuddy; then
    ver="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$XP_BUNDLE" 2>/dev/null || true)"
    info "XProtect bundle version: ${ver:-unknown}"
  else
    info "XProtect bundle info not available (or PlistBuddy missing)"
  fi

  # XProtect Remediator (macOS 13+; path can vary across versions)
  bold "XProtect Remediator"
  XPR_CANDIDATES=(
    "/Library/Apple/System/Library/CoreServices/XProtectRemediator.bundle/Contents/Info.plist"
    "/System/Library/CoreServices/XProtectRemediator.bundle/Contents/Info.plist"
  )
  xpr_shown=0
  for plist in "${XPR_CANDIDATES[@]}"; do
    if [ -f "$plist" ] && have /usr/libexec/PlistBuddy; then
      ver="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$plist" 2>/dev/null || true)"
      info "XProtect Remediator version: ${ver:-unknown} ($plist)"
      xpr_shown=1
      break
    fi
  done
  if [ $xpr_shown -eq 0 ]; then
    info "XProtect Remediator bundle not found (system may be older or path differs)"
  fi

  # System Integrity Protection
  bold "System Integrity Protection (SIP)"
  if have csrutil; then
    csrutil status || warn "csrutil status command failed"
  else
    info "csrutil not found"
  fi

  # Also check ClamAV if installed via Homebrew
  check_clamav
}

# ---------- Dispatch by OS ----------
case "$OS_NAME" in
  Linux)   linux_checks ;;
  Darwin)  macos_checks ;;
  *)       warn "Unsupported OS: $OS_NAME (script covers Linux and macOS only)";;
esac

bold "Summary"
if [ "$OS_NAME" = "Linux" ]; then
  info "Reported ClamAV presence, versions, signature DB freshness, and service status (if systemd)."
  info "Extend with distro-specific EDR/AV detections as needed."
elif [ "$OS_NAME" = "Darwin" ]; then
  info "Reported Gatekeeper, XProtect/XProtect Remediator versions, SIP status, and ClamAV if installed (Homebrew)."
fi

echo