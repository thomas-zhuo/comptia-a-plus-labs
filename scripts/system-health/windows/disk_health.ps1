<#
.SYNOPSIS
  Disk & Storage Health (Windows) — display only

.DESCRIPTION
  Shows volumes (free/total), physical disks (health/media/type),
  partitions, and basic SMART counters if available.
  Prints to console only (no file writes).
#>

Write-Host "Disk & Storage Health Report" -ForegroundColor Cyan
Write-Host "Host : $env:COMPUTERNAME"
Write-Host "OS   : $([System.Environment]::OSVersion.VersionString)"
Write-Host "Date : $(Get-Date)"
function Section { param($t); Write-Host "`n==== $t ====" -ForegroundColor Yellow }

# ----- Volumes -----
Section "Volumes (Free / Total)"
Get-Volume |
  Select-Object DriveLetter, FileSystem,
                @{n='Free(GB)';e={[math]::Round($_.SizeRemaining/1GB,2)}},
                @{n='Total(GB)';e={[math]::Round($_.Size/1GB,2)}},
                HealthStatus |
  Format-Table -AutoSize

# ----- Physical Disks -----
Section "Physical Disks"
try {
  Get-PhysicalDisk |
    Select-Object FriendlyName, MediaType, Size,
                  HealthStatus, OperationalStatus, SpindleSpeed |
    Format-Table -AutoSize
} catch {
  Write-Host "Get-PhysicalDisk not available (older Windows editions)"; 
}

# ----- Disks & Partitions -----
Section "Disks"
Get-Disk |
  Select-Object Number, FriendlyName, BusType, PartitionStyle, HealthStatus, OperationalStatus, Size |
  Format-Table -AutoSize

Section "Partitions"
Get-Partition |
  Select-Object DiskNumber, PartitionNumber, DriveLetter, Type, GptType, Size |
  Format-Table -AutoSize

# ----- Storage Reliability / SMART-like counters (if exposed) -----
Section "Storage Reliability Counters (if available)"
try {
  Get-CimInstance -Namespace root\microsoft\windows\storage -ClassName MSFT_PhysicalDisk |
    Select-Object FriendlyName, HealthStatus, MediaType, OperationalStatus, FailurePredictStatus, Temperature |
    Format-Table -AutoSize
} catch {
  Write-Host "MSFT_PhysicalDisk CIM class not available on this system."
}

Write-Host "`nDisk & storage health check complete." -ForegroundColor Green
