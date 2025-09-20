# Cybersecurity Labs Portfolio

Cross-platform cybersecurity labs showcasing diagnostics, monitoring, and security fundamentals.  

This repo demonstrates hands-on skills across Linux, macOS, and Windows, aligned with my CompTIA (A+/Net+/Sec+/Linux+) and EC-Council (CEH/CSA) learning path.  

## 📂 Projects by Category

### 🔹 System Health & Diagnostics
Scripts:
- Linux/macOS → `scripts/system-health/linux/sysinfo.sh`, `scripts/system-health/linux/disk_health.sh`
- Windows → `scripts/system-health/windows/system_health_check.ps1`, `scripts/system-health/windows/disk_health.ps1`

**Skills demonstrated:**
- Automating system baselines (OS, uptime, processes, IPs)
- Disk usage and health monitoring
- Cross-platform troubleshooting fundamentals

### 🔹 Network Diagnostics
Scripts:
- Linux/macOS → `scripts/network-diagnostics/linux/network_diagnostics.sh`
- Windows → `scripts/network-diagnostics/windows/network_diagnostics.ps1`

**Skills demonstrated:**
- Connectivity and DNS validation
- Routing and latency checks
- Foundation for packet capture & vulnerability scanning (future labs)

### 🔹 Log & Event Monitoring
Scripts:
- Linux/macOS → `scripts/log-monitoring/linux/event_logs.sh`
- Windows → `scripts/log-monitoring/windows/event_logs.ps1`

**Skills demonstrated:**
- Collecting system/application logs
- Extracting errors & warnings for analysis
- Foundations for security log monitoring (SIEM workflows)

### 🔹 Security & Compliance *(Planned)*
- Firewall audits  
- Antivirus/Defender checks  
- User/group account audits  

### 🔹 Security & Compliance
Scripts:
- **Implemented:**
  - Linux/macOS → `scripts/security/linux/firewall_audit.sh`
  - Windows → `scripts/security/windows/firewall_audit.ps1`
- **Planned:**
  - Antivirus/Defender status checks
  - User/group account and permission audits

**Skills demonstrated:**
- Auditing firewall status (enabled/disabled profiles)
- Listing active inbound rules
- Capturing listening ports and services
- Building toward full security posture assessments across platforms

### 🔹 Hardware Playbooks *(Planned)*
- SSD upgrade and disk cloning  
- Battery and power health checks  
- Peripheral device troubleshooting  

### 🔹 Troubleshooting Case Studies *(Planned)*
Markdown-based case studies applying the **CompTIA 7-step troubleshooting method**, evolving into **incident response workflows**.  

## ⚙️ How to Run the Scripts

### Linux/macOS

```bash
# Sysinfo
chmod +x scripts/system-health/linux/sysinfo.sh
./scripts/system-health/linux/sysinfo.sh

# Network diagnostics
chmod +x scripts/network-diagnostics/linux/network_diagnostics.sh
./scripts/network-diagnostics/linux/network_diagnostics.sh

# Disk health
chmod +x scripts/system-health/linux/disk_health.sh
./scripts/system-health/linux/disk_health.sh

# Event logs
chmod +x scripts/log-monitoring/linux/event_logs.sh
./scripts/log-monitoring/linux/event_logs.sh

# Firewall audit
chmod +x scripts/security/linux/firewall_audit.sh
./scripts/security/linux/firewall_audit.sh
```

### Windows (PowerShell)

```powershell
# Allow this session to run scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# System health
.\scripts\system-health\windows\system_health_check.ps1

# Network diagnostics
.\scripts\network-diagnostics\windows\network_diagnostics.ps1

# Disk health
.\scripts\system-health\windows\disk_health.ps1

# Event logs
.\scripts\log-monitoring\windows\event_logs.ps1

# Firewall audit
.\scripts\security\windows\firewall_audit.ps1
```

## 💾 How to Save Output to File (Optional)

### Linux/macOS

```bash
OS="macOS"

./scripts/system-health/linux/sysinfo.sh | tee scripts/system-health/linux/sysinfo_${OS}_$(date +%F).txt

./scripts/network-diagnostics/linux/network_diagnostics.sh | tee scripts/network-diagnostics/linux/network_diag_${OS}_$(date +%F).txt

./scripts/system-health/linux/disk_health.sh | tee scripts/system-health/linux/disk_health_${OS}_$(date +%F).txt

./scripts/log-monitoring/linux/event_logs.sh | tee scripts/log-monitoring/linux/event_logs_${OS}_$(date +%F).txt

./scripts/security/linux/firewall_audit.sh | tee scripts/security/linux/firewall_audit_${OS}_$(date +%F).txt
```

### Windows (PowerShell)
```powershell
.\scripts\system-health\windows\system_health_check.ps1 | Out-File scripts\system-health\windows\system_health_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\network-diagnostics\windows\network_diagnostics.ps1 | Out-File scripts\network-diagnostics\windows\network_diag_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\system-health\windows\disk_health.ps1 | Out-File scripts\system-health\windows\disk_health_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\log-monitoring\windows\event_logs.ps1 | Out-File scripts\log-monitoring\windows\event_logs_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\security\windows\firewall_audit.ps1 | Out-File scripts\security\windows\firewall_audit_windows_$(Get-Date -Format 'yyyy-MM-dd').txt
```

## 📑 Sample Output

Sample runs of the scripts are saved with date-stamped filenames that also indicate the operating system used.

Each category has separate **`linux/`** and **`windows/`** subfolders for scripts and outputs.

- **System Health (`scripts/system-health/`)**
  - [Linux/macOS](scripts/system-health/linux/)  
    - `sysinfo_macOS_2025-09-07.txt`  
    - `sysinfo_Kali_Linux_2025-09-07.txt`  
    - `disk_health_macOS_2025-09-14.txt`  
    - `disk_health_Kali_Linux_2025-09-14.txt`  
  - [Windows](scripts/system-health/windows/)  
    - `system_health_windows_2025-09-14.txt`  
    - `disk_health_windows_2025-09-14.txt`

- **Network Diagnostics (`scripts/network-diagnostics/`)**
  - [Linux/macOS](scripts/network-diagnostics/linux/)  
    - `network_diag_macOS_2025-09-13.txt`  
    - `network_diag_Kali_Linux_2025-09-14.txt`  
  - [Windows](scripts/network-diagnostics/windows/)  
    - `network_diag_windows_2025-09-14.txt`

- **Log Monitoring (`scripts/log-monitoring/`)**
  - [Linux/macOS](scripts/log-monitoring/linux/)  
    - `event_logs_macOS_2025-09-14.txt`  
    - `event_logs_Kali_Linux_2025-09-14.txt`  
  - [Windows](scripts/log-monitoring/windows/)  
    - `event_logs_windows_2025-09-14.txt`

**Security & Compliance (`scripts/security/`)**
- [Linux/macOS](scripts/security/linux/):
  - `firewall_audit_macOS_2025-09-20.txt`
  - `firewall_audit_Kali_Linux_2025-09-20.txt`
- [Windows](scripts/security/windows/)  
    - `firewall_audit_windows_2025-09-20.txt`

These files demonstrate the expected outputs for **system health, network connectivity, disk monitoring, log collection, and firewall auditing**.  

Having Linux, macOS, and Windows runs highlights **cross-platform troubleshooting** and builds a strong foundation for **security monitoring and compliance auditing**.


## 🎯 Why This Matters

These labs demonstrate:
- Cross-platform scripting (Bash & PowerShell)
- System, network, disk, and log diagnostics
- Security readiness foundations (auditing & monitoring building blocks)

This portfolio supports my pivot into cybersecurity by proving I can gather, interpret, and act on host-level signals across multiple operating systems.

## 🔮 Next Steps

This portfolio will expand alongside my cybersecurity training. Planned projects include:

- **System Health & Diagnostics**
  - Extend disk health checks with encryption status (BitLocker/FileVault)
  - Automate performance monitoring (CPU/memory snapshots)

- **Network Diagnostics**
  - Add packet capture (tcpdump, Wireshark) labs
  - Implement port scanning and service enumeration scripts
  - Compare normal vs. abnormal traffic baselines

- **Log & Event Monitoring**
  - Automate filtering of security-related logs (auth failures, privilege escalation attempts)
  - Build a SIEM-style correlation script to detect anomalies across logs
  - Create case studies based on simulated incident logs

- **Security & Compliance**
  - Firewall configuration audit scripts
  - Antivirus/Defender status checks
  - User/group account and permission audits
  - Vulnerability scan integrations (planned for CEH/CSA modules)

- **Hardware Playbooks**
  - SSD upgrade and cloning procedure
  - Secure data wipe and disposal workflow
  - Battery and peripheral health checks

- **Case Studies**
  - A+ level: Endpoint troubleshooting scenarios (slow Wi-Fi, low disk, printer errors)
  - Network+ level: VLAN/DNS misconfigurations, packet loss investigations
  - Security+ / CEH level: Malware infection response, unauthorized access, firewall misconfigurations
  - CSA level: SOC analyst workflows — triage, correlation, incident reporting


## Repository Structure

```text
comptia-a-plus-labs/
├─ README.md
├─ scripts/
│  ├─ system-health/
│  │  ├─ linux/
│  │  │  ├─ sysinfo.sh
│  │  │  ├─ sysinfo_macOS_2025-09-07.txt
│  │  │  ├─ sysinfo_Kali_Linux_2025-09-07.txt
│  │  │  ├─ disk_health.sh
│  │  │  ├─ disk_health_macOS_2025-09-14.txt
│  │  │  └─ disk_health_Kali_Linux_2025-09-14.txt
│  │  └─ windows/
│  │     ├─ system_health_check.ps1
│  │     ├─ system_health_windows_2025-09-14.txt
│  │     ├─ disk_health.ps1
│  │     └─ disk_health_windows_2025-09-14.txt
│  │
│  ├─ network-diagnostics/
│  │  ├─ linux/
│  │  │  ├─ network_diagnostics.sh
│  │  │  ├─ network_diag_macOS_2025-09-13.txt
│  │  │  └─ network_diag_Kali_Linux_2025-09-14.txt
│  │  └─ windows/
│  │     ├─ network_diagnostics.ps1
│  │     └─ network_diag_windows_2025-09-14.txt
│  │
│  ├─ log-monitoring/
│  │  ├─ linux/
│  │  │  ├─ event_logs.sh
│  │  │  ├─ event_logs_macOS_2025-09-14.txt
│  │  │  └─ event_logs_Kali_Linux_2025-09-14.txt
│  │  └─ windows/
│  │     ├─ event_logs.ps1
│  │     └─ event_logs_windows_2025-09-14.txt
│  │
│  ├─ security/
│  │  ├─ linux/
│  │  │  ├─ firewall_audit.sh
│  │  │  ├─ firewall_audit_macOS_2025-09-20.txt
│  │  │  └─ firewall_audit_Kali_Linux_2025-09-20.txt
│  │  └─ windows/
│  │     ├─ firewall_audit.ps1
│  │     └─ firewall_audit_windows_2025-09-20.txt
│  │
│  ├─ hardware-playbooks/      # 🖥️ (future: battery_check.sh, ssd_upgrade.md, etc.)
│  │  ├─ linux/
│  │  └─ windows/
│  │
│  └─ case-studies/            # 📝 (future: troubleshooting writeups in markdown)
│
└─ docs/
   └─ CHANGELOG.md

```