# CHANGELOG

All notable changes to this project will be documented here.  
Dates follow `YYYY-MM-DD` format.

## 2025-10-04
- Added Windows User/Permission Hardening script:
  - `scripts/security/windows/perm_hardening.ps1`
- Sample output saved as:
  - `scripts/security/windows/perm_hardening_windows_2025-10-04.txt`
- Updated README with User/Permission Hardening project details (Windows + Linux/macOS)

## 2025-09-28
- Added Linux/macOS permission hardening script:
  - `scripts/security/linux/perm_hardening.sh`
- Added Windows CVE audit script:
  - `scripts/security/windows/cve_audit.ps1`
- Added sample output files:
  - `scripts/security/linux/perm_hardening_macOS_2025-09-28.txt`
  - `scripts/security/linux/perm_hardening_Kali_Linux_2025-09-28.txt`
  - `scripts/security/windows/cve_audit_windows_2025-09-28.txt`
- Updated README with new "Permission Hardening" (Linux/macOS) and "CVE Audit" (Windows) details

## 2025-09-27
- Added Patch & Update Compliance Audit scripts:
  - `scripts/security/linux/patch_audit.sh`
  - `scripts/security/windows/patch_audit.ps1`
- Added sample output files:
  - `scripts/security/linux/patch_audit_macOS_2025-09-27.txt`
  - `scripts/security/linux/patch_audit_Kali_Linux_2025-09-27.txt`
  - `scripts/security/windows/patch_audit_windows_2025-09-27.txt`
- Updated README with Patch Audit project details and run instructions

## 2025-09-21
- **Security & Compliance**
  - Added User & Group Account Audit scripts:
    - `scripts/security/linux/account_audit.sh`
    - `scripts/security/windows/account_audit.ps1`
  - Added Antivirus / Endpoint Protection Status scripts:
    - `scripts/security/linux/av_status.sh`
    - `scripts/security/windows/av_status.ps1`
  - Added sample output files:
    - `scripts/security/linux/av_status_macOS_2025-09-21.txt`
    - `scripts/security/linux/av_status_Kali_Linux_2025-09-21.txt`
    - `scripts/security/windows/av_status_windows_2025-09-21.txt`
    - `scripts/security/linux/account_audit_macOS_2025-09-22.txt`
    - `scripts/security/linux/account_audit_Kali_Linux_2025-09-22.txt`
    - `scripts/security/windows/account_audit_windows_2025-09-22.txt`
  - Updated README with new Security & Compliance project details

## 2025-09-20
- **Security & Compliance**
- Added Firewall Audit scripts:
  - `scripts/security/linux/firewall_audit.sh`
  - `scripts/security/windows/firewall_audit.ps1`
- Added sample output files:
  - `scripts/security/linux/firewall_audit_macOS_2025-09-20.txt`
  - `scripts/security/linux/firewall_audit_Kali_Linux_2025-09-20.txt`
  - `scripts/security/windows/firewall_audit_windows_2025-09-20.txt`
- Updated README with Security & Compliance project details and run instructions

## 2025-09-13 – 2025-09-14
- **System Health**
  - Added Windows system health script (`scripts/system-health/windows/system_health_check.ps1`)
  - Added sample output: `scripts/system-health/windows/system_health_windows_2025-09-14.txt`
  - Added Linux/macOS disk health script (`scripts/system-health/linux/disk_health.sh`)
  - Added Windows disk health script (`scripts/system-health/windows/disk_health.ps1`)
  - Added sample outputs:
    - `scripts/system-health/linux/disk_health_macOS_2025-09-14.txt`
    - `scripts/system-health/linux/disk_health_Kali_Linux_2025-09-14.txt`
    - `scripts/system-health/windows/disk_health_windows_2025-09-14.txt`

- **Network Diagnostics**
  - Added Linux/macOS script (`scripts/network-diagnostics/linux/network_diagnostics.sh`)
  - Added Windows script (`scripts/network-diagnostics/windows/network_diagnostics.ps1`)
  - Added sample outputs:
    - `scripts/network-diagnostics/linux/network_diag_macOS_2025-09-13.txt`
    - `scripts/network-diagnostics/linux/network_diag_Kali_Linux_2025-09-14.txt`
    - `scripts/network-diagnostics/windows/network_diag_windows_2025-09-14.txt`

- **Log Monitoring**
  - Added Linux/macOS script (`scripts/log-monitoring/linux/event_logs.sh`)
  - Added Windows script (`scripts/log-monitoring/windows/event_logs.ps1`)
  - Added sample outputs:
    - `scripts/log-monitoring/linux/event_logs_macOS_2025-09-14.txt`
    - `scripts/log-monitoring/linux/event_logs_Kali_Linux_2025-09-14.txt`
    - `scripts/log-monitoring/windows/event_logs_windows_2025-09-14.txt`

- **Documentation**
  - Updated README with System Health, Network Diagnostics, Disk & Storage Health, and Event Log Collector details and run instructions

---

## 2025-09-07
- **System Health**
  - Fixed Linux/macOS sysinfo script for macOS compatibility (`scripts/system-health/linux/sysinfo.sh`)
  - Added sample outputs:
    - `scripts/system-health/linux/sysinfo_macOS_2025-09-07.txt`
    - `scripts/system-health/linux/sysinfo_Kali_Linux_2025-09-07.txt`

---

## 2025-08-31
- **System Health**
  - Initial commit of Linux sysinfo script (`scripts/system-health/linux/sysinfo.sh`)
  - Added basic README with project description and run instructions
