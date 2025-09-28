#!/usr/bin/env bash
# cve_audit.sh — Bash 3.2–compatible CVE risk audit (Linux/macOS)
# Displays results; to save, pipe to tee:
#   OS="macOS"; ./scripts/security/linux/cve_audit.sh | tee scripts/security/linux/cve_audit_${OS}_$(date +%F).txt

set -euo pipefail

bold() { printf "\033[1m%s\033[0m\n" "$*"; }
hr()   { printf "%s\n" "------------------------------------------------------------"; }

OS_NAME="$(uname -s)"

echo
bold "CVE Risk Audit (Local DB)"
printf "  Host: %s\n" "$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo Unknown-Host)"
printf "  OS  : %s\n"  "$OS_NAME"
printf "  Date: %s\n"   "$(date)"
hr

# --- Make Homebrew discoverable on macOS (Bash 3.2 safe) ---
if [ "$OS_NAME" = "Darwin" ]; then
  if [ -x /opt/homebrew/bin/brew ] && ! command -v brew >/dev/null 2>&1; then
    PATH="/opt/homebrew/bin:$PATH"
  fi
  if [ -x /usr/local/bin/brew ] && ! command -v brew >/dev/null 2>&1; then
    PATH="/usr/local/bin:$PATH"
  fi
fi

HAS_APT=0
HAS_BREW=0
command -v apt  >/dev/null 2>&1 && HAS_APT=1
command -v brew >/dev/null 2>&1 && HAS_BREW=1

if [ $HAS_APT -eq 0 ] && [ $HAS_BREW -eq 0 ]; then
  echo "No supported package manager detected (apt or brew)."
  echo "Tip (macOS): install Homebrew from https://brew.sh and re-run."
  exit 0
fi

# ------------------------- Mini CVE DB (edit/extend freely) -------------------
# Format per line: package|fixed_version|severity|CVE_IDs(comma-separated)|notes
CVE_DB="$(
cat <<'EOF'
openssl|3.0.14|HIGH|CVE-2023-5678,CVE-2024-1111|Fixed in 3.0.14
curl|8.5.0|HIGH|CVE-2023-38545|HTTP/3 heap overflow
sudo|1.9.15|CRITICAL|CVE-2021-3156|Baron Samedit (example mapping)
vim|9.1.0000|MEDIUM|CVE-2024-12345|Modeline issue
git|2.46.0|HIGH|CVE-2024-32002|Path handling
python@3.11|3.11.8|MEDIUM|CVE-2023-40217|ssl fixes (example)
node|22.6.0|HIGH|CVE-2024-12346|HTTP smuggling (example)
nginx|1.26.1|HIGH|CVE-2024-12347|HTTP/2 rapid reset (example)
EOF
)"

# ------------------------- Version comparison (Bash 3.2 safe) -----------------
# Compares dotted numeric versions: "1.2.3" < "1.3", etc.
ver_lt() {
  a="$1"; b="$2"
  a="${a#*:}"; a="${a%%-*}"  # drop epoch/revision if present
  b="${b#*:}"; b="${b%%-*}"

  IFS='.' read -r a1 a2 a3 a4 a5 a6 a7 a8 <<EOF
$a
EOF
  IFS='.' read -r b1 b2 b3 b4 b5 b6 b7 b8 <<EOF
$b
EOF

  for i in 1 2 3 4 5 6 7 8; do
    eval "va=\${a$i:-0}"; eval "vb=\${b$i:-0}"
    case "$va" in ''|*[!0-9]*) [ "$a" \< "$b" ] && return 0 || { [ "$a" = "$b" ] && return 1 || return 1; } ;; esac
    case "$vb" in ''|*[!0-9]*) [ "$a" \< "$b" ] && return 0 || { [ "$a" = "$b" ] && return 1 || return 1; } ;; esac
    if [ "$va" -lt "$vb" ]; then return 0; fi
    if [ "$va" -gt "$vb" ]; then return 1; fi
  done
  return 1  # equal
}

# ------------------------- Package inventory ----------------------------------
bold "Package Inventory (first 20 shown)"
PKGS=""
if [ $HAS_APT -eq 1 ]; then
  PKGS="$(dpkg-query -W -f='${binary:Package} ${Version}\n' 2>/dev/null || true)"
fi
if [ -z "$PKGS" ] && [ $HAS_BREW -eq 1 ]; then
  # brew list --versions prints "name v1 v2 ... vN" -> take last
  PKGS="$(brew list --versions 2>/dev/null | awk '{print $1, $NF}' || true)"
  # normalize openssl@3 -> openssl (so it matches DB key)
  PKGS="$(printf "%s\n" "$PKGS" | sed -E 's/^openssl@3 /openssl /')"
fi

if [ -z "$PKGS" ]; then
  echo "No packages detected (permission or tool issue?)."
  exit 0
fi

printf "%s\n" "$PKGS" | head -20
echo

# ------------------------- Scan against CVE DB (robust) -----------------------
bold "Vulnerability Findings (local DB; installed < fixed_version ⇒ at risk)"
printf "%-22s %-14s %-14s %-10s %-9s %s\n" "PACKAGE" "INSTALLED" "FIXED" "STATUS" "SEVERITY" "CVE_IDS"
hr

vuln_count=0
matches_found=0
total_checked=0

# Avoid subshells: iterate using a for-loop over lines
OLD_IFS="$IFS"
IFS=$'\n'
for line in $PKGS; do
  name="${line%% *}"
  ver="${line#* }"
  [ -z "$name" ] && continue
  [ -z "$ver" ] && continue
  total_checked=$((total_checked+1))

  # find matching DB line (exact package name)
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
