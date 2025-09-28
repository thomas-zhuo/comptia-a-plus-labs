#!/bin/bash
# CVE Audit Script (macOS/Linux) — Compatible with Bash 3.2+

set -euo pipefail
trap 'echo "[ERROR] line $LINENO: $BASH_COMMAND (exit=$?)" >&2' ERR

bold() { echo -e "\033[1m$*\033[0m"; }
hr() { printf '%*s\n' "$(tput cols || echo 80)" '' | tr ' ' '-'; }

# ------------------------- OS Detection -------------------------
OS_NAME="$(uname -s)"
HOST="$(hostname)"
DATE="$(date)"

# ------------------------- Package Inventory -------------------------
bold "CVE Risk Audit (Local DB)"
echo "  Host: $HOST"
echo "  OS  : $OS_NAME"
echo "  Date: $DATE"
hr

bold "Package Inventory (first 20 shown)"
PKGS=""
HAS_APT=0
HAS_BREW=0

if command -v apt >/dev/null 2>&1; then
  HAS_APT=1
  PKGS="$(dpkg-query -W -f='${Package} ${Version}\n' | head -20)"
elif command -v brew >/dev/null 2>&1; then
  HAS_BREW=1
  PKGS="$(brew list --versions | head -20)"
else
  echo "No supported package manager found (apt/brew)."
fi

echo "$PKGS"
hr

# ------------------------- Local CVE DB -------------------------
# Example DB: package|fixed_version|severity|cve_ids
CVE_DB=$(cat <<'EOF'
openssl|1.1.1w-1|HIGH|CVE-2023-2650,CVE-2023-0464
bash|5.1-2|MEDIUM|CVE-2019-18276
apache2|2.4.62-1|CRITICAL|CVE-2023-25690,CVE-2023-27522
EOF
)

# ------------------------- Version Comparison -------------------------
# Simple fallback for Bash 3.2: use sort -V instead of associative arrays
ver_lt() {
  [ "$1" = "$2" ] && return 1
  local smaller
  smaller=$(printf "%s\n%s" "$1" "$2" | sort -V | head -n1)
  [ "$smaller" = "$1" ]
}

# ------------------------- Vulnerability Findings -------------------------
bold "Vulnerability Findings (local DB; installed < fixed_version ⇒ at risk)"
printf "%-22s %-14s %-14s %-10s %-9s %s\n" "PACKAGE" "INSTALLED" "FIXED" "STATUS" "SEVERITY" "CVE_IDS"
hr

set +e  # don’t exit early if no matches
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

  db_line="$(printf "%s\n" "$CVE_DB" | awk -F'|' -v p="$name" '$1==p {print; exit}')"

  if [ -n "$db_line" ]; then
    matches_found=1
    fixed="$(printf "%s" "$db_line" | cut -d'|' -f2)"
    sev="$(printf "%s" "$db_line"   | cut -d'|' -f3)"
    cves="$(printf "%s" "$db_line"  | cut -d'|' -f4)"

    status="ok"
    if ver_lt "$ver" "$fixed"; then
      status="VULNERABLE?"
      vuln_count=$((vuln_count+1))
    fi

    printf "%-22s %-14s %-14s %-10s %-9s %s\n" "$name" "$ver" "$fixed" "$status" "$sev" "$cves"
  fi
done
IFS="$OLD_IFS"

hr
if [ $matches_found -eq 0 ]; then
  echo "No matching packages from the CVE_DB were found in this inventory."
else
  echo "Checked: $total_checked   Potentially vulnerable: $vuln_count"
fi
echo "Legend: 'VULNERABLE?' means installed_version < fixed_version in local DB."
set -e
