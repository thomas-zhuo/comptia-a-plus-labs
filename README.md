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
