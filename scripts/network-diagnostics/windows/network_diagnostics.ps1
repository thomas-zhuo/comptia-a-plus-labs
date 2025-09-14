<#
.SYNOPSIS
  Network Diagnostics Script for Windows

.DESCRIPTION
  Runs common connectivity checks:
  - IP configuration
  - Default gateway / routing table
  - DNS configuration
  - Ping tests
  - Traceroute
  - DNS lookup
  Prints results to console only.
#>

Write-Host "Collecting Windows Network Diagnostics..." -ForegroundColor Cyan

function Section($title) {
    Write-Host "`n==== $title ====" -ForegroundColor Yellow
}

# -------- Host & OS --------
Write-Host "Host     : $env:COMPUTERNAME"
Write-Host "OS       : $([System.Environment]::OSVersion.VersionString)"
Write-Host "Date     : $(Get-Date)"

# -------- Interfaces / IP --------
Section "Interfaces & IP Addresses"
Get-NetIPConfiguration | Format-Table -AutoSize

# -------- Default Gateway / Routing --------
Section "Default Gateway / Routing"
Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Format-Table -AutoSize

# -------- DNS Configuration --------
Section "DNS Configuration"
Get-DnsClientServerAddress | Format-Table -AutoSize

# -------- Ping --------
Section "Ping 8.8.8.8 (Google DNS)"
Test-Connection -ComputerName 8.8.8.8 -Count 4

Section "Ping cloudflare.com"
Test-Connection -ComputerName cloudflare.com -Count 4

# -------- Traceroute --------
Section "Traceroute to cloudflare.com"
tracert cloudflare.com

# -------- DNS Lookup --------
Section "DNS Lookup for cloudflare.com"
try {
    Resolve-DnsName cloudflare.com -ErrorAction Stop
}
catch {
    nslookup cloudflare.com
}

Write-Host "`nNetwork diagnostics complete." -ForegroundColor Green
