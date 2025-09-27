#!/usr/bin/env bash
# Patch & Update Compliance Audit (Linux + macOS) — DISPLAY ONLY
# - Shows OS/version, kernel, and pending updates
# - Uses best-effort security update listing where supported (dnf/yum/apt/zypper)
# - Makes NO changes to the system

set -euo pipefail

bold() { printf "\n\033[1m%s\033[0m\n" "$*"; }
info() { printf "  %s\n" "$*"; }
warn() { printf "\033[33m! %s\033[0m\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
HOST="$(hostname)"
NOW="$(date '+%F %T %Z')"

bold "Patch & Update Compliance Audit"
info "Host: $HOST"
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_PRETTY="${PRETTY_NAME:-$NAME}"
else
  OS_PRETTY="$(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null || true)"
fi
info "OS  : ${OS_PRETTY:-$OS}"
info "Kernel: $(uname -r)"
info "Date: $NOW"

# ---------------- Linux distros ----------------
audit_debian_like() {
  bold "Debian/Ubuntu (APT) — Pending Updates"
  # Refresh cache (read-only). Some distros require sudo; try without first.
  if have apt; then
    if ! apt -qq update 2>/dev/null; then
      warn "apt update requires privileges or network; showing cached upgradeable list if available."
    fi
    if apt list --upgradeable 2>/dev/null | grep -q '/'; then
      apt list --upgradeable 2>/dev/null | sed '1d' | awk '{print "  " $0}'
      # Security packages (best effort: those coming from security pockets)
      bold "Security Updates (best effort)"
      apt list --upgradeable 2>/dev/null | grep -E '(security|ESM|ubuntu-esm)' | sed 's/^/  /' || info "None detected in upgradeable list."
    else
      info "No upgradeable packages reported (or index not available)."
    fi
  else
    warn "apt not found"
  fi
}

audit_rhel_like_dnf() {
  bold "RHEL/CentOS/Fedora (DNF) — Pending Updates"
  if have dnf; then
    dnf -q check-update || true
    # General updates
    dnf -q check-update | awk 'NF && $1 !~ /Obsoleting|Last/ {print "  "$0}' || info "No updates found or metadata access blocked."
    bold "Security Updates"
    if dnf -q updateinfo list security 2>/dev/null | grep -qE 'Important|Moderate|Critical|Low|SECURITY'; then
      dnf -q updateinfo list security 2>/dev/null | sed 's/^/  /'
    else
      info "No security advisories listed (or plugin/metadata not available)."
    fi
  else
    warn "dnf not found"
  fi
}

audit_rhel_like_yum() {
  bold "RHEL/CentOS (YUM) — Pending Updates"
  if have yum; then
    yum -q check-update || true
    yum -q check-update | awk 'NF && $1 !~ /Obsoleting|Last/ {print "  "$0}' || info "No updates found or metadata access blocked."
    bold "Security Updates"
    if yum -q updateinfo list security 2>/dev/null | grep -qE 'Important|Moderate|Critical|Low|SECURITY'; then
      yum -q updateinfo list security 2>/dev/null | sed 's/^/  /'
    else
      info "No security advisories listed (or yum-plugin-security not available)."
    fi
  else
    warn "yum not found"
  fi
}

audit_arch_like() {
  bold "Arch/Manjaro (pacman) — Pending Updates"
  if have checkupdates; then
    # checkupdates comes from pacman-contrib; safe (no changes)
    if checkupdates 2>/dev/null | grep -q .; then
      checkupdates 2>/dev/null | sed 's/^/  /'
    else
      info "No updates found."
    fi
  elif have pacman; then
    if pacman -Qu 2>/dev/null | grep -q .; then
      pacman -Qu 2>/dev/null | sed 's/^/  /'
    else
      info "No updates found."
    fi
  else
    warn "pacman not found"
  fi
}

audit_suse_like() {
  bold "openSUSE/SLES (zypper) — Pending Updates"
  if have zypper; then
    zypper -q lu 2>/dev/null | sed 's/^/  /' || info "No updates listed."
    bold "Patches"
    zypper -q list-patches 2>/dev/null | sed 's/^/  /' || info "No patches listed (or permissions required)."
  else
    warn "zypper not found"
  fi
}

audit_alpine() {
  bold "Alpine (apk) — Pending Updates"
  if have apk; then
    apk version -l '<' 2>/dev/null | sed 's/^/  /' || info "No updates listed."
  else
    warn "apk not found"
  fi
}

# ---------------- macOS ----------------
audit_macos() {
  bold "macOS — Pending Updates"
  if have softwareupdate; then
    softwareupdate -l 2>/dev/null | sed 's/^/  /' || info "No software updates found (or permissions required)."
  else
    warn "softwareupdate not found"
  fi

  bold "Homebrew — Outdated Formulae (if installed)"
  if have brew; then
    brew --version >/dev/null 2>&1 || true
    if brew outdated 2>/dev/null | grep -q .; then
      brew outdated 2>/dev/null | sed 's/^/  /'
    else
      info "No outdated Homebrew packages."
    fi
  else
    info "Homebrew not installed."
  fi
}

# Dispatcher
case "$OS" in
  Linux)
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      case "${ID_LIKE:-$ID}" in
        *debian*|debian|ubuntu) audit_debian_like ;;
        *rhel*|*fedora*|fedora) 
          if have dnf; then audit_rhel_like_dnf; else audit_rhel_like_yum; fi ;;
        *suse*|sles|opensuse*) audit_suse_like ;;
        *arch*|arch) audit_arch_like ;;
        *alpine*|alpine) audit_alpine ;;
        *)
          warn "Unknown Linux family: ${ID_LIKE:-$ID}. Trying common managers..."
          if have apt; then audit_debian_like
          elif have dnf; then audit_rhel_like_dnf
          elif have yum; then audit_rhel_like_yum
          elif have zypper; then audit_suse_like
          elif have pacman; then audit_arch_like
          elif have apk; then audit_alpine
          else warn "No known package manager found."; fi
          ;;
      esac
    else
      warn "/etc/os-release not found; cannot determine distro family."
    fi
    ;;
  Darwin) audit_macos ;;
  *) warn "Unsupported OS: $OS (script covers Linux and macOS only)";;
esac

bold "Summary"
info "Reported OS/kernel and pending updates per package manager."
info "Security advisories shown where supported (dnf/yum/zypper, best-effort on apt)."
info "Run with network access (and sudo where required) for freshest results."
echo