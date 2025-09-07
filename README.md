# CompTIA A+ Labs Portfolio

This repo showcases hands-on CompTIA A+ skills. First project: a Bash script that collects system info (works on Linux and macOS).

## Projects
- **Linux sysinfo script** (`scripts/linux/sysinfo.sh`) — prints host, uptime, IP(s), disk usage, and top processes. Sample output included.

## How to run
```bash
chmod +x scripts/linux/sysinfo.sh
./scripts/linux/sysinfo.sh
```


## How to save output to file

```bash
./scripts/linux/sysinfo.sh | tee scripts/linux/sysinfo_$(date +%F).txt
```

## Sample Output

Sample runs of the script are saved in [`scripts/linux/`](scripts/linux/) with date-stamped filenames that also indicate the operating system used, for example:

- `sysinfo_MacOS_2025-09-07.txt`
- `sysinfo_Kali_Linux_2025-09-07.txt`

These files demonstrate the expected output: hostname, uptime, IP addresses, disk usage, and top processes.  

Having both macOS and Linux runs highlights cross-platform troubleshooting.

---

## Why This Matters

Collecting system information is a fundamental troubleshooting step in IT support.  
This script shows the ability to:
- Automate repetitive diagnostic tasks with Bash
- Capture machine state into timestamped logs
- Work across both Linux and macOS environments

---

## Next Steps
Future labs will be added to this portfolio, including:
- **Windows PowerShell script** to gather system health
- **Networking labs** with DNS troubleshooting and Wireshark captures
- **Hardware playbooks** (e.g., SSD upgrades)
- **Troubleshooting case studies** following the CompTIA A+ 7-step method

---

## Repository Structure

```text
comptia-a-plus-labs/
├─ README.md
├─ scripts/
│  └─ linux/
│     ├─ sysinfo.sh
│     ├─ sysinfo_macos_2025-09-03.txt
│     └─ sysinfo_linux_2025-09-03.txt
└─ docs/
   └─ CHANGELOG.md