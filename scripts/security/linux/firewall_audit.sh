#!/usr/bin/env bash
# Firewall Audit (Linux/macOS) — display-only
# Supports: UFW, firewalld, nftables/iptables, pf (macOS)

set -euo pipefail

bold() { printf "\n\033[1m%s\033[0m\n" "$*"; }
info() { printf "  %s\n" "$*"; }

bold "Firewall Audit — Linux/macOS"
info "Host: $(hostname)"
info "OS: $(uname -s) $(uname -r)"
info "Date: $(date '+%F %T %Z')"

# Helper to check a command exists
have() { command -v "$1" >/dev/null 2>&1; }

bold "Detected Firewall Stack"
if have ufw; then
  info "UFW detected"
elif have firewall-cmd; then
  info "firewalld detected"
elif have nft; then
  info "nftables detected"
elif have iptables; then
  info "iptables detected"
elif have pfctl; then
  info "pf (macOS) detected"
else
  info "No common host-based firewall tooling detected on PATH."
fi

# UFW
if have ufw; then
  bold "UFW Status"
  ufw status verbose || true
fi

# firewalld
if have firewall-cmd; then
  bold "firewalld Status"
  firewall-cmd --state || true

  bold "firewalld Active Zones"
  firewall-cmd --get-active-zones || true

  bold "firewalld Allowed Services (per active zone)"
  for z in $(firewall-cmd --get-active-zones | awk 'NR%2==0{print $1}'); do
    echo "Zone: $z"
    firewall-cmd --zone="$z" --list-services || true
    firewall-cmd --zone="$z" --list-ports || true
    echo
  done
fi

# nftables
if have nft; then
  bold "nftables Ruleset (read-only)"
  sudo -n true 2>/dev/null || info "(Tip: sudo may be required for full details)"
  sudo nft list ruleset 2>/dev/null || nft list ruleset || true
fi

# iptables (legacy)
if have iptables; then
  bold "iptables Policy & Rules (read-only)"
  sudo -n true 2>/dev/null || info "(Tip: sudo may be required for full details)"
  for table in filter nat mangle raw security; do
    echo "Table: $table"
    (sudo iptables -S -t "$table" 2>/dev/null || iptables -S -t "$table") || true
    echo
  done
fi

# pf (macOS)
if have pfctl; then
  bold "pf (macOS) Status"
  sudo -n true 2>/dev/null || info "(Tip: sudo may be required for full details)"
  (sudo pfctl -s info 2>/dev/null || pfctl -s info) || true

  bold "pf Rules (read-only)"
  (sudo pfctl -sr 2>/dev/null || pfctl -sr) || true

  bold "pf NAT (if any)"
  (sudo pfctl -sn 2>/dev/null || pfctl -sn) || true

  bold "pf Anchors"
  (sudo pfctl -sa 2>/dev/null || pfctl -sa) | sed -n '1,80p' || true
fi

bold "Summary"
if have ufw; then
  info "UFW present — use 'sudo ufw status verbose' for full detail."
elif have firewall-cmd; then
  info "firewalld present — see active zones/services/ports above."
elif have nft; then
  info "nftables present — ruleset listed above."
elif have iptables; then
  info "iptables present — rules listed per table."
elif have pfctl; then
  info "pf present — rules and NAT listed."
else
  info "No host firewall detected."
fi

echo
