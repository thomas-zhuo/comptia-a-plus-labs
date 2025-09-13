# CompTIA A+ Labs Portfolio

This repo showcases hands-on CompTIA A+ skills. First project: a Bash script that collects system info (works on Linux and macOS).

## Projects
- **Linux sysinfo script** (`scripts/linux/sysinfo.sh`) — prints host, uptime, IP(s), disk usage, and top processes. Sample output included.
- **Windows system health script** (`scripts/windows/system_health_check.ps1`) — collects OS details, uptime, IP config, disk usage, and top processes. Sample output included.

## How to run

### Linux / macOC

```bash
chmod +x scripts/linux/sysinfo.sh
./scripts/linux/sysinfo.sh
```

### Windows (PowerShell)

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\windows\system_health_check.ps1
```

## How to save output to file

### Linux / macOS

```bash
./scripts/linux/sysinfo.sh | tee scripts/linux/sysinfo_$(date +%F).txt
```

### Windows (PowerShell)

```powershell
.\scripts\windows\system_health_check.ps1 | Out-File scripts\windows\system_health_$(Get-Date -Format 'yyyy-MM-dd').txt
```

## Sample Output


Sample runs of the scripts are saved with date-stamped filenames that also indicate the operating system used.  

- **Linux/ macOS outputs** are saved in [`scripts/linux/`](scripts/linux/), for example:  
  - `sysinfo_macos_2025-09-07.txt`  
  - `sysinfo_kali_linux_2025-09-07.txt`

- **Windows outputs** are saved in [`scripts/windows/`](scripts/windows/), for example:  
  - `system_health_windows_2025-09-07.txt`

These files demonstrate the expected output: hostname, uptime, IP addresses, disk usage, and top processes.  

Having Linux, macOS, and Windows runs highlights cross-platform troubleshooting.

## Why This Matters

Collecting system information is a fundamental troubleshooting step in IT support.  
This script shows the ability to:
- Automate repetitive diagnostic tasks with Bash
- Capture machine state into timestamped logs
- Work across both Linux and macOS environments


## Next Steps
Future labs will be added to this portfolio, including:
- **Windows PowerShell script** to gather system health
- **Networking labs** with DNS troubleshooting and Wireshark captures
- **Hardware playbooks** (e.g., SSD upgrades)
- **Troubleshooting case studies** following the CompTIA A+ 7-step method


## Repository Structure

```text
comptia-a-plus-labs/
├─ README.md
├─ scripts/
│  └─ linux/
│     ├─ sysinfo.sh
│     ├─ sysinfo_macos_2025-09-07.txt
│     └─ sysinfo_linux_2025-09-07.txt
└─ windows/
│     ├─ system_health_check.ps1
│     └─ system_health_windows_2025-09-13.txt
└─ docs/
   └─ CHANGELOG.md