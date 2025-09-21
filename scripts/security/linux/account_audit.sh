#!/usr/bin/env bash
# User & Group Account Audit (Linux + macOS) — DISPLAY ONLY
# Reports local users, privileged accounts, sudo/admin memberships, and login shells.
# - Linux: uses getent/passwd, groups, passwd -S/chage (best effort)
# - macOS: uses dscl, admin/wheel groups (best effort)
set -euo pipefail

bold() { printf "\n\033[1m%s\033[0m\n" "$*"; }
info() { printf "  %s\n" "$*"; }
warn() { printf "\033[33m! %s\033[0m\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

OS_NAME="$(uname -s)"
HOST="$(hostname)"
NOW="$(date '+%F %T %Z')"

bold "User & Group Account Audit"
info "Host: $HOST"
info "OS  : $OS_NAME ($(uname -r))"
info "Date: $NOW"

# ---------- Linux helpers ----------
linux_list_users() {
  bold "Local Users (/etc/passwd)"
  # username:uid:gid:home:shell  (mark disabled shells)
  getent passwd | awk -F: '
    {
      shell=$7
      disabled=(shell ~ /(nologin|false)$/) ? " (disabled shell)" : ""
      printf "  %s: uid=%s gid=%s home=%s shell=%s%s\n", $1,$3,$4,$6,$7,disabled
    }'
}

linux_uid0() {
  bold "UID 0 Accounts (root-equivalent)"
  awk -F: '$3==0{printf("  %s (shell=%s)\n",$1,$7)}' /etc/passwd
}

linux_privileged_groups() {
  bold "Sudo-Capable Groups & Members"
  for g in sudo wheel admin; do
    if getent group "$g" >/dev/null; then
      members=$(getent group "$g" | awk -F: '{print $4}')
      info "Group: $g -> ${members:-(no explicit members)}"
    fi
  done
}

linux_human_users_status() {
  bold "Human User Password/Lock Status (best effort)"
  # Heuristic: UID >= 1000 are human users on most modern distros (100 on some)
  getent passwd | awk -F: '$3>=1000 {print $1}' | while read -r u; do
    if have passwd; then
      # passwd -S not on all distros; try then fallback to chage -l
      if passwd -S "$u" >/dev/null 2>&1; then
        s=$(passwd -S "$u" 2>/dev/null)
        info "$u -> $s"
      elif have chage; then
        exp=$(chage -l "$u" 2>/dev/null | awk -F": " '/Password expires/{print $2}')
        must=$(chage -l "$u" 2>/dev/null | awk -F": " '/Password must be changed/{print $2}')
        info "$u -> chage: expires=${exp:-unknown}, must_change=${must:-unknown}"
      else
        info "$u -> (no passwd -S/chage available)"
      fi
    else
      info "$u -> (passwd tool not available)"
    fi
  done
}

linux_groups_overview() {
  bold "Groups with Members"
  getent group | awk -F: 'length($4)>0 {printf "  %s: %s\n",$1,$4}' | sort
}

# ---------- macOS helpers ----------
macos_list_users() {
  bold "Local Users (dscl)"
  # List users with UniqueID >= 501 (avoid system accounts); print id,gid,home,shell
  if ! have dscl; then warn "dscl not found"; return; fi
  while IFS= read -r u; do
    uid=$(dscl . -read "/Users/$u" UniqueID 2>/dev/null | awk '{print $2}')
    gid=$(dscl . -read "/Users/$u" PrimaryGroupID 2>/dev/null | awk '{print $2}')
    home=$(dscl . -read "/Users/$u" NFSHomeDirectory 2>/dev/null | awk '{print $2}')
    shell=$(dscl . -read "/Users/$u" UserShell 2>/dev/null | awk '{print $2}')
    disabled=""
    [[ "$shell" =~ (nologin|false)$ ]] && disabled=" (disabled shell)"
    printf "  %s: uid=%s gid=%s home=%s shell=%s%s\n" "$u" "${uid:-?}" "${gid:-?}" "${home:-?}" "${shell:-?}" "$disabled"
  done < <(dscl . -list /Users UniqueID 2>/dev/null | awk '$2>=501 {print $1}' | sort)
}

macos_uid0() {
  bold "UID 0 Accounts (root-equivalent)"
  # root exists by default; show its shell
  if have dscl; then
    shell=$(dscl . -read /Users/root UserShell 2>/dev/null | awk '{print $2}')
    info "root (shell=${shell:-?})"
  fi
}

macos_admin_groups() {
  bold "Admin & Wheel Group Members"
  if have dscl; then
    admins=$(dscl . -read /Groups/admin GroupMembership 2>/dev/null | cut -d: -f2- | xargs)
    wheel=$(dscl . -read /Groups/wheel GroupMembership 2>/dev/null | cut -d: -f2- | xargs)
    info "admin -> ${admins:-none}"
    info "wheel -> ${wheel:-none}"
  fi
}

macos_sudoers_hint() {
  bold "Sudoers (hint)"
  if [ -r /etc/sudoers ]; then
    grep -E '^(%admin|%wheel)' /etc/sudoers | sed 's/^/  /' || true
  else
    info "/etc/sudoers not readable (try: sudo cat /etc/sudoers)"
  fi
}

# ---------- Dispatch ----------
case "$OS_NAME" in
  Linux)
    linux_list_users
    linux_uid0
    linux_privileged_groups
    linux_human_users_status
    linux_groups_overview
    ;;
  Darwin)
    macos_list_users
    macos_uid0
    macos_admin_groups
    macos_sudoers_hint
    ;;
  *)
    warn "Unsupported OS: $OS_NAME (script covers Linux and macOS only)"
    ;;
esac

bold "Summary"
if [ "$OS_NAME" = "Linux" ]; then
  info "Listed local users, UID 0 accounts, sudo-capable groups, password/lock status (where available), and groups with members."
elif [ "$OS_NAME" = "Darwin" ]; then
  info "Listed local users (UID>=501), UID 0 account, admin/wheel membership, and sudoers hints."
fi
echo
