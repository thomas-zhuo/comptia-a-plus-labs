# CompTIA A+ Labs Portfolio

This repo showcases hands-on CompTIA A+ skills. First project: a Bash script that collects system info (works on Linux and macOS).

## Projects
- **Linux sysinfo script** (`scripts/linux/sysinfo.sh`) — prints host, uptime, IP(s), disk usage, and top processes. Sample output included.
- **Windows system health script** (`scripts/windows/system_health_check.ps1`) — collects OS details, uptime, IP config, disk usage, and top processes. Sample output included.
- **Network diagnostics scripts** (`scripts/linux/network_diagnostics.sh`, `scripts/windows/network_diagnostics.ps1`) — run connectivity tests (IP config, DNS, ping, traceroute, DNS lookup). Sample outputs included.  
- **Disk & storage health scripts** (`scripts/linux/disk_health.sh`, `scripts/windows/disk_health.ps1`) — display disk usage, partitions, physical disk details, and health/SMART status. Sample outputs included.  

## How to run

### Linux/macOS

```bash
chmod +x scripts/linux/sysinfo.sh
./scripts/linux/sysinfo.sh

chmod +x scripts/linux/network_diagnostics.sh
./scripts/linux/network_diagnostics.sh

chmod +x scripts/linux/disk_health.sh
./scripts/linux/disk_health.sh
```

### Windows (PowerShell)

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\windows\system_health_check.ps1

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\windows\network_diagnostics.ps1

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\windows\disk_health.ps1
```

## How to save output to file (optional)

### Linux/macOS

```bash
./scripts/linux/sysinfo.sh | tee scripts/linux/sysinfo_$(date +%F).txt

./scripts/linux/network_diagnostics.sh | tee scripts/linux/network_diag_$(date +%F)

./scripts/linux/disk_health.sh | tee scripts/linux/disk_health_linux_$(date +%F).txt
```

### Windows (PowerShell)

```powershell
.\scripts\windows\system_health_check.ps1 | Out-File scripts\windows\system_health_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\windows\network_diagnostics.ps1 | Out-File scripts\windows\network_diag_$(Get-Date -Format 'yyyy-MM-dd').txt

.\scripts\windows\disk_health.ps1 | Out-File scripts\windows\disk_health_$(Get-Date -Format 'yyyy-MM-dd').txt
```

## Sample Output


Sample runs of the scripts are saved with date-stamped filenames that also indicate the operating system used.  

- **Linux/macOS outputs** are saved in [`scripts/linux/`](scripts/linux/), for example:  
  - `sysinfo_macos_2025-09-07.txt`  
  - `sysinfo_kali_linux_2025-09-07.txt`
  - `network_diag_macos_2025-09-13.txt`
  - `network_diag_linux_2025-09-14.txt`
  - `disk_health_linux_2025-09-14.txt`

- **Windows outputs** are saved in [`scripts/windows/`](scripts/windows/), for example:  
  - `system_health_windows_2025-09-14.txt`
  - `network_diag_windows_2025-09-14.txt`
  - `disk_health_windows_2025-09-14.txt`

These files demonstrate the expected output: system, network, and disk diagnostics.

Having Linux, macOS, and Windows runs highlights cross-platform troubleshooting.

## Why This Matters

Collecting system information is a fundamental troubleshooting step in IT support.  
This script shows the ability to:
- Automate repetitive diagnostic tasks with Bash and PowerShell
- Capture machine state into timestamped logs
- Work across both Linux, macOS, and Windows environments


## Next Steps
Future labs will be added to this portfolio, including:
- **Advanced networking labs** with DNS troubleshooting and Wireshark captures
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
│  │  ├─ network_diagnostics.sh
│  │  ├─ network_diag_macOS_2025-09-13.txt
│  │  └─ network_diag_linux_2025-09-14.txt
│  │  ├─ disk_health.sh
│  │  └─ disk_health_linux_2025-09-14.txt
└─ windows/
│     ├─ system_health_check.ps1
│     └─ system_health_windows_2025-09-14.txt
│     ├─ network_diagnostics.ps1
│     └─ network_diag_windows_2025-09-14.txt
│     ├─ disk_health.ps1
│     └─ disk_health_windows_2025-09-14.txt
└─ docs/
   └─ CHANGELOG.md