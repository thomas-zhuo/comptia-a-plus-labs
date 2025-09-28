#!/bin/bash
# CVE Audit Script (macOS/Linux) — Compatible with Bash 3.2+
# Fixed: avoid SIGPIPE (exit 141) when printing first N lines.

set -euo pipefail
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND (exit=$?)" >&2' ERR

bold() { echo -e "\033[1m$*\033[0m"; }
hr() { printf '%*s\n' "$(tput cols 2>/dev/null || echo 80)" '' | tr ' ' '-'; }

# ------------------------- OS Detection -------------------------
OS_NAME="$(uname -s)"
HOST="$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo Unknown-Host)"
DATE="$(date)"

bold "CVE Risk Audit (Local DB)"
echo "  Host: $HOST"
echo "  OS  : $OS_NAME"
echo "  Date: $DATE"
hr

# ------------------------- Package Inventory (no SIGPIPE) ---------------------
bold "Package Inventory (first 20 shown)"
PKGS=""      # full inventory
HAS_APT=0
HAS_BREW=0

# Make Homebrew discoverable on macOS (best-effort)
if [ "$OS_NAME" = "Darwin" ]; then
  if [ -x /opt/homebrew/bin/brew ] && ! command -v brew >/dev/null 2>&1; then
    PATH="/opt/homebrew/bin:$PATH"
  fi
  if [ -x /usr/local/bin/brew ] && ! command -v brew >/dev/null 2>&1; then
    PATH="/usr/local/bin:$PATH"
  fi
fi

# Collect full package inventory (do not pipe the producer into head)
if command -v dpkg-query >/dev/null 2>&1; then
  HAS_APT=1
  PKGS="$(dpkg-query -W -f='${Package} ${Version}\n' 2>/dev/null || true)"
elif command -v brew >/dev/null 2>&1; then
  HAS_BREW=1
  PKGS_RAW="$(brew list --versions 2>/dev/null || true)"
  PKGS="$(printf '%s\n' "$PKGS_RAW" | awk '{print $1, $NF}')"
  PKGS="$(printf '%s\n' "$PKGS" | sed -E 's/^openssl@3 /openssl /')"
else
  echo "No supported package manager found (apt/brew)."
fi

# Print only first 20 lines safely (disable -e temporarily to avoid SIGPIPE killing us)
if [ -n "$PKGS" ]; then
  set +e
  printf '%s\n' "$PKGS" | head -20
  # restore -e for the rest of the script
  set -e
else
  echo "(no packages detected)"
fi
hr

# ------------------------- Local CVE DB -------------------------
# Example DB lines: package|fixed_version|severity|cve_ids
CVE_DB=$(cat <<'EOF'
openssl|1.1.1w-1|HIGH|CVE-2023-2650,CVE-2023-0464
bash|5.1-2|MEDIUM|CVE-2019-18276
apache2|2.4.62-1|CRITICAL|CVE-2023-25690,CVE-2023-27522
curl|8.5.0|HIGH|CVE-2023-38545
EOF
)

# ------------------------- Version Comparison -------------------------
# Uses sort -V when available, fallback to lexical compare.
have_sort_v=0
if sort -V </dev/null >/dev/null 2>&1; then have_sort_v=1; fi

ver_lt() {
  a="$1"; b="$2"
  [ "$a" = "$b" ] && return 1
  if [ $have_sort_v -eq 1 ]; then
    local smallest
    smallest=$(printf "%s\n%s\n" "$a" "$b" | sort -V | head -n1)
    [ "$smallest" = "$a" ]
  else
    [ "$a" \< "$b" ]
  fi
}

# ------------------------- Vulnerability Findings -----------------------------
bold "Vulnerability Findings (local DB; installed < fixed_version ⇒ at risk)"
printf "%-22s %-14s %-14s %-10s %-9s %s\n" "PACKAGE" "INSTALLED" "FIXED" "STATUS" "SEVERITY" "CVE_IDS"
hr

# Allow harmless non-zero exit codes during scan (so the report prints)
set +e
vuln_count=0
matches_found=0
total_checked=0

OLD_IFS="$IFS"
IFS=$'\n'
for line in $PKGS; do
  name="${line%% *}"
  ver="${line#* }"
  [ -z "$name" ] && continue
  [ -z "$ver" ] && continue
  total_checked=$((total_checked+1))

  db_line="$(printf '%s\n' "$CVE_DB" | awk -F'|' -v p="$name" '$1==p {print; exit}')"
  if [ -n "$db_line" ]; then
    matches_found=1
    fixed="$(printf '%s' "$db_line" | cut -d'|' -f2)"
    sev="$(printf   '%s' "$db_line" | cut -d'|' -f3)"
    cves="$(printf  '%s' "$db_line" | cut -d'|' -f4)"

    status="ok"
    if ver_lt "$ver" "$fixed"; then
      status="VULNERABLE?"
      vuln_count=$((vuln_count+1))
    fi

    printf "%-22s %-14s %-14s %-10s %-9s %s\n" "$name" "$ver" "$fixed" "$status" "$sev" "$cves"
  fi
done
IFS="$OLD_IFS"
set -e

hr
if [ $matches_found -eq 0 ]; then
  echo "No matching packages from the CVE_DB were found in this inventory."
else
  echo "Checked: $total_checked   Potentially vulnerable: $vuln_count"
fi
echo "Legend: 'VULNERABLE?' means installed_version < fixed_version in local DB."
