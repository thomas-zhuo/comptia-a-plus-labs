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

### 🔹 Security & Compliance
Scripts:
- **Implemented:**
  - Linux/macOS → 
    - `scripts/security/linux/firewall_audit.sh`
    - `scripts/security/linux/av_status.sh`
    - `scripts/security/linux/account_audit.sh`
    - `scripts/security/linux/patch_audit.sh`
  - Windows → 
    - `scripts/security/windows/firewall_audit.ps1`
    - `scripts/security/windows/av_status.ps1`
    - `scripts/security/windows/account_audit.ps1`
    - `scripts/security/windows/patch_audit.ps1`

- **Planned:**
  - Extended compliance checks (encryption, advanced configuration hardening)

**Skills demonstrated:**
- Auditing firewall status (enabled/disabled profiles, inbound rules, listening ports)
- Validating antivirus/endpoint protection status (real-time protection, signatures, scan history)
- Enumerating local users and groups, flagging privileged accounts and risky settings
- Checking patch/update compliance (installed hotfixes, pending updates, reboot state)
- Building toward full host-based security posture assessments across platforms

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

# Anti-virus status
chmod +x scripts/security/linux/av_status.sh
./scripts/security/linux/av_status.sh

# Account audit
chmod +x scripts/security/linux/account_audit.sh
./scripts/security/linux/account_audit.sh

# Patch audit
chmod +x scripts/security/linux/patch_audit.sh
./scripts/security/linux/patch_audit.sh
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

# Anti-virus status
.\scripts\security\windows\av_status.ps1

# Account audit
.\scripts\security\windows\account_audit.ps1

# Patch audit
.\scripts\security\windows\patch_audit.ps1
```

## 💾 How to Save Output to File (Optional)

### Linux/macOS

```bash
OS="macOS"    # or Kali_Linux, Ubuntu, etc.

./scripts/system-health/linux/sysinfo.sh | tee scripts/system-health/linux/sysinfo_${OS}_$(date +%F).txt

./scripts/network-diagnostics/linux/network_diagnostics.sh | tee scripts/network-diagnostics/linux/network_diag_${OS}_$(date +%F).txt

./scripts/system-health/linux/disk_health.sh | tee scripts/system-health/linux/disk_health_${OS}_$(date +%F).txt

./scripts/log-monitoring/linux/event_logs.sh | tee scripts/log-monitoring/linux/event_logs_${OS}_$(date +%F).txt

./scripts/security/linux/firewall_audit.sh | tee scripts/security/linux/firewall_audit_${OS}_$(date +%F).txt

./scripts/security/linux/av_status.sh | tee scripts/security/linux/av_status${OS}_$(date +%F).txt

./scripts/security/linux/account_audit.sh | tee scripts/security/linux/account_audit${OS}_$(date +%F).txt

./scripts/security/linux/patch_audit.sh | tee scripts/security/linux/patch_audit${OS}_$(date +%F).txt
```

### Windows (PowerShell)
```powershell
.\scripts\system-health\windows\system_health_check.ps1 | Out-File scripts\system-health\windows\system_health_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\network-diagnostics\windows\network_diagnostics.ps1 | Out-File scripts\network-diagnostics\windows\network_diag_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\system-health\windows\disk_health.ps1 | Out-File scripts\system-health\windows\disk_health_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\log-monitoring\windows\event_logs.ps1 | Out-File scripts\log-monitoring\windows\event_logs_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\security\windows\firewall_audit.ps1 | Out-File scripts\security\windows\firewall_audit_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\security\windows\av_status.ps1 | Out-File scripts\security\windows\av_status_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\security\windows\account_audit.ps1 | Out-File scripts\security\windows\account_audit_windows_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\security\windows\patch_audit.ps1 | Out-File scripts\security\windows\patch_audit_windows_$(Get-Date -Format 'yyyy-MM-dd').txt
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

- **Security & Compliance (`scripts/security/`)**
  - [Linux/macOS](scripts/security/linux/)  
    - `firewall_audit_macOS_2025-09-20.txt`  
    - `firewall_audit_Kali_Linux_2025-09-20.txt`  
    - `av_status_macOS_2025-09-21.txt`  
    - `av_status_Kali_Linux_2025-09-21.txt`  
    - `account_audit_macOS_2025-09-22.txt`  
    - `account_audit_Kali_Linux_2025-09-22.txt`  
    - `patch_audit_macOS_2025-09-27.txt`  
    - `patch_audit_Kali_Linux_2025-09-27.txt`  
  - [Windows](scripts/security/windows/)  
    - `firewall_audit_windows_2025-09-20.txt`  
    - `av_status_windows_2025-09-21.txt`  
    - `account_audit_windows_2025-09-22.txt`  
    - `patch_audit_windows_2025-09-27.txt`

These files demonstrate the expected outputs for **system health, network connectivity, disk monitoring, log collection, firewall auditing, antivirus/endpoint protection status, account audits, and patch/update compliance**.  

Having Linux, macOS, and Windows runs highlights **cross-platform troubleshooting** and builds a strong foundation for **security monitoring, compliance auditing, and vulnerability management**.

## 🎯 Why This Matters

These labs demonstrate:
- Cross-platform scripting (Bash & PowerShell) for Linux, macOS, and Windows
- Automated system, network, disk, and log diagnostics
- Security readiness checks: firewall, antivirus/endpoint protection, user/group audits, and patch compliance
- Building blocks for **vulnerability management** and compliance verification
- Foundations for SOC analyst workflows: collecting, analyzing, and reporting host-level security signals

This portfolio supports my pivot into cybersecurity by proving I can gather, interpret, and act on system and security data across multiple environments. It highlights not just troubleshooting ability, but also the **security mindset** required for monitoring, auditing, and hardening endpoints in real-world environments.

## 🔮 Next Steps

This portfolio will continue to expand alongside my cybersecurity training, progressing from **foundational diagnostics** into **security operations and incident response**.

### 🔹 System Health & Diagnostics
- Extend disk health checks with **encryption status** (BitLocker/FileVault/LUKS).
- Automate **performance monitoring** (CPU/memory snapshots over time).
- Add **patch audit with vulnerability scoring** (CVE lookups).

### 🔹 Network Diagnostics
- Add **packet capture and analysis labs** (tcpdump, Wireshark).
- Implement **port scanning and service enumeration** (nmap, PowerShell equivalents).
- Compare **normal vs abnormal traffic baselines** to simulate threat detection.

### 🔹 Log & Event Monitoring
- Automate **filtering of security-related logs** (auth failures, privilege escalation attempts).
- Build a lightweight **SIEM-style correlation script** to detect anomalies across logs.
- Create **case studies from simulated incident logs** to mimic SOC workflows.

### 🔹 Security & Compliance
- Expand **patch audits** with vulnerability scoring integrations.
- Add **user/group permission hardening checks**.
- Integrate **antivirus/Defender results with alerting scripts**.
- Simulate **endpoint hardening playbooks** (firewall + AV + patch + accounts).

### 🔹 Hardware Playbooks
- Document **SSD upgrade and cloning procedure**.
- Add **secure data wipe and disposal workflow**.
- Develop **battery and peripheral health diagnostics**.

### 🔹 Troubleshooting Case Studies
- **A+ level:** Endpoint troubleshooting scenarios (slow Wi-Fi, low disk, printer errors).  
- **Network+ level:** VLAN/DNS misconfigurations, packet loss investigations.  
- **Security+ / CEH level:** Malware infection response, unauthorized access detection, firewall misconfigurations.  
- **CSA level:** SOC analyst workflows — alert triage, log correlation, escalation, and incident reporting.  

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
│  │  │  ├─ firewall_audit_Kali_Linux_2025-09-20.txt
│  │  │  ├─ av_status.sh
│  │  │  ├─ av_status_macOS_2025-09-21.txt
│  │  │  ├─ av_status_Kali_Linux_2025-09-21.txt
│  │  │  ├─ account_audit.sh
│  │  │  ├─ account_audit_macOS_2025-09-21.txt
│  │  │  ├─ account_audit_Kali_Linux_2025-09-21.txt
│  │  │  ├─ patch_audit.sh
│  │  │  ├─ patch_audit_macOS_2025-09-27.txt
│  │  │  └─ patch_audit_Kali_Linux_2025-09-27.txt
│  │  └─ windows/
│  │     ├─ firewall_audit.ps1
│  │     ├─ firewall_audit_windows_2025-09-20.txt
│  │     ├─ av_status.ps1
│  │     ├─ av_status_windows_2025-09-21.txt
│  │     ├─ account_audit.ps1
│  │     ├─ account_audit_windows_2025-09-21.txt
│  │     ├─ patch_audit.ps1
│  │     └─ patch_audit_windows_2025-09-27.txt
│  │
│  ├─ advanced-networking/          # 🌐 (future labs: Wireshark/tcpdump captures, nmap scans)
│  │  ├─ linux/
│  │  └─ windows/
│  │
│  ├─ siem-labs/                    # 📊 (future: log correlation, anomaly detection, mini-SIEM scripts)
│  │  ├─ linux/
│  │  └─ windows/
│  │
│  ├─ hardware-playbooks/           # 🖥️ (future: SSD upgrade, secure wipe, battery diagnostics)
│  │  ├─ linux/
│  │  └─ windows/
│  │
│  └─ case-studies/                 # 📝 (markdown writeups: troubleshooting & incident response)
│
└─ docs/
   └─ CHANGELOG.md

```