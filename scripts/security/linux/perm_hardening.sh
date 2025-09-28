#!/bin/bash
# User/Group Permission Hardening Check — Linux/macOS (Bash 3.2 compatible)
# Display-only; pipe to tee to save. Tries to continue even without sudo/root.

set -euo pipefail

bold(){ printf "\033[1m%s\033[0m\n" "$*"; }
hr(){ printf '%*s\n' "$(tput cols 2>/dev/null || echo 80)" '' | tr ' ' '-'; }

OS="$(uname -s)"
HOST="$(hostname -s 2>/dev/null || hostname || echo unknown)"

bold "User & Permission Hardening Audit"
echo "  Host : $HOST"
echo "  OS   : $OS"
echo "  Date : $(date)"
hr

# ---------- helpers ----------
have(){ command -v "$1" >/dev/null 2>&1; }
is_macos(){ [ "$OS" = "Darwin" ]; }
is_linux(){ [ "$OS" = "Linux" ]; }

# readable shell whitelist (interactive)
is_interactive_shell(){
  case "$1" in
    */bash|*/zsh|*/fish|*/sh|/bin/bash|/bin/zsh|/bin/sh) return 0 ;;
    *) return 1 ;;
  esac
}

# stat perms
permstr(){
  if is_macos; then stat -f '%Sp' "$1" 2>/dev/null || echo "?"; else stat -c '%A' "$1" 2>/dev/null || echo "?"; fi
}
owner(){
  if is_macos; then stat -f '%Su' "$1" 2>/dev/null || echo "?"; else stat -c '%U' "$1" 2>/dev/null || echo "?"; fi
}
group(){
  if is_macos; then stat -f '%Sg' "$1" 2>/dev/null || echo "?"; else stat -c '%G' "$1" 2>/dev/null || echo "?"; fi
}

# ---------- users with interactive shells ----------
bold "Local users with interactive shells"
if is_linux; then
  awk -F: '($7 !~ /(nologin|false)$/){printf "  %-20s uid=%-6s gid=%-6s shell=%s\n",$1,$3,$4,$7}' /etc/passwd | sed 's/^/ /'
else
  dscl . list /Users 2>/dev/null | while read u; do
    shell=$(dscl . -read "/Users/$u" UserShell 2>/dev/null | awk '{print $2}')
    uid=$(dscl . -read "/Users/$u" UniqueID 2>/dev/null | awk '{print $2}')
    gid=$(dscl . -read "/Users/$u" PrimaryGroupID 2>/dev/null | awk '{print $2}')
    [ -n "$shell" ] && is_interactive_shell "$shell" && printf "  %-20s uid=%-6s gid=%-6s shell=%s\n" "$u" "${uid:-?}" "${gid:-?}" "$shell"
  done
fi
hr

# ---------- UID 0 accounts ----------
bold "UID 0 (root-equivalent) accounts"
if is_linux; then
  awk -F: '($3==0){printf "  %-20s shell=%s\n",$1,$7}' /etc/passwd | sed 's/^/ /'
else
  awk -F: '($3==0){printf "  %-20s shell=%s\n",$1,$7}' /etc/passwd | sed 's/^/ /'
fi
hr

# ---------- admin / sudo groups ----------
bold "Admin/sudo group membership"
if is_linux; then
  for g in sudo wheel adm admin; do
    if getent group "$g" >/dev/null 2>&1; then
      getent group "$g" | awk -F: -v G="$g" 'NF{printf "  %-8s -> %s\n", G, $4}'
    fi
  done
else
  for g in admin wheel; do
    dscl . -read "/Groups/$g" GroupMembership 2>/dev/null | sed "s/^/  $g -> /"
  done
fi
hr


# ---------- passwordless accounts (best-effort) ----------
bold "Passwordless / locked accounts (best-effort)"
if is_linux; then
  if [ -r /etc/shadow ]; then
    awk -F: '
      $2 == "" {printf "  %-20s (empty password field)\n",$1}
      $2 ~ /^[!*]/ {printf "  %-20s (locked/disabled)\n",$1}
    ' /etc/shadow
  else
    echo "  (/etc/shadow not readable; run with sudo for full check)"
  fi
else
  echo "  (macOS hides password hashes; showing shells as proxy)"
  awk -F: '($7 ~ /(nologin|false)$/){printf "  %-20s (non-login shell: %s)\n",$1,$7}' /etc/passwd
fi
hr

# ---------- sudoers validation & rules ----------
bold "Sudoers validation & non-commented rules"
if have sudo && sudo -n true 2>/dev/null; then
  if have visudo; then
    if sudo -n visudo -c >/dev/null 2>&1; then
      echo "  visudo syntax: OK"
    else
      echo "  visudo syntax: ERROR (check manually)"
    fi
  fi
  echo "  /etc/sudoers (non-comment):"
  sudo -n awk '!/^[[:space:]]*($|#)/{print "    "$0}' /etc/sudoers 2>/dev/null || true
  if [ -d /etc/sudoers.d ]; then
    echo "  /etc/sudoers.d/* (non-comment):"
    sudo -n sh -c 'for f in /etc/sudoers.d/*; do [ -f "$f" ] && awk "!/^[[:space:]]*($|#)/{print \"    \"FILENAME\": \"$0}" "$f"; done' 2>/dev/null || true
  fi
else
  echo "  (sudo not available or no cached credentials; skipping validation)"
fi
hr

# ---------- PATH safety: world-writable dirs ----------
bold "\$PATH directories that are world-writable (risk)"
IFS=':'; for d in $PATH; do
  [ -z "$d" ] && continue
  [ -d "$d" ] || continue
  if [ -w "$d" ] && ( find "$d" -maxdepth 0 -perm -0002 >/dev/null 2>&1 ); then
    printf "  %s  perms=%s owner=%s group=%s\n" "$d" "$(permstr "$d")" "$(owner "$d")" "$(group "$d")"
  fi
done
unset IFS
hr

# ---------- World-writable & SUID/SGID samples (bounded) ----------
bold "Sample world-writable files in system paths (bounded)"
find /usr /bin /sbin /usr/local -type f -perm -0002 -maxdepth 4 2>/dev/null | head -n 10 | sed 's/^/  /' || true
bold "Sample SUID/SGID files (bounded)"
if is_macos; then
  find /usr /bin /sbin /usr/local -type f \( -perm -4000 -o -perm -2000 \) -maxdepth 3 2>/dev/null | head -n 15 | sed 's/^/  /' || true
else
  find /usr /bin /sbin /usr/local -type f \( -perm -4000 -o -perm -2000 \) -maxdepth 3 2>/dev/null | head -n 15 | sed 's/^/  /' || true
fi
hr

bold "Summary"
echo "  - Review UID 0 accounts and admin/wheel/sudo membership."
echo "  - Fix world-writable PATH dirs (chown root:root; chmod 755)."
echo "  - Validate sudoers with visudo; remove broad ALL=(ALL) NOPASSWD unless needed."
echo "  - Audit SUID/SGID and world-writable files; restrict or remove."
