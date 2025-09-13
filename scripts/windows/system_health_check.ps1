<#
.SYNOPSIS
  Collects key system diagnostics for Windows.

.DESCRIPTION
  Gathers hostname, OS version, uptime, IP configuration,
  disk usage, and top 10 processes by CPU usage.
  Prints results to the console and saves them as JSON.

.NOTES
  Author: Thomas Zhuo
  Date: 2025-09-13
#>

Write-Host "Collecting Windows system health..." -ForegroundColor Cyan

# Hostname
$Hostname = $env:COMPUTERNAME

# OS version
$OS = (Get-CimInstance Win32_OperatingSystem).Caption

# Uptime (in hours)
$LastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
$UptimeHours = [math]::Round(((Get-Date) - $LastBoot).TotalHours, 2)

# IP configuration (IPv4 + DNS)
$IPConfig = Get-NetIPConfiguration |
  Select-Object InterfaceAlias, IPv4Address, DNSServer

# Disk usage
$Disks = Get-Volume |
  Select-Object DriveLetter, FileSystem, @{Name="Free(GB)";Expression={[math]::Round($_.SizeRemaining/1GB,2)}}, @{Name="Total(GB)";Expression={[math]::Round($_.Size/1GB,2)}}

# Top 10 processes by CPU
$Processes = Get-Process |
  Sort-Object CPU -Descending |
  Select-Object -First 10 Name, CPU

# Collect into object
$SystemHealth = [PSCustomObject]@{
  Hostname     = $Hostname
  OS           = $OS
  UptimeHours  = $UptimeHours
  IPConfig     = $IPConfig
  Disks        = $Disks
  TopProcesses = $Processes
}

# Print to console
$SystemHealth | Format-List

# Save as JSON file with timestamp
$Date = Get-Date -Format "yyyy-MM-dd"
$OutFile = "scripts/windows/system_health_windows_$Date.json"
$SystemHealth | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 $OutFile

Write-Host "System health report saved to $OutFile" -ForegroundColor Green
