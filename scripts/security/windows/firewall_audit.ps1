<# 
Firewall Audit (Windows) — display-only
Shows profile status and a concise view of enabled rules.
#>

Write-Host "`nFirewall Audit — Windows" -ForegroundColor Cyan
Write-Host ("Host: {0}" -f $env:COMPUTERNAME)
Write-Host ("OS  : {0}" -f (Get-CimInstance Win32_OperatingSystem).Caption)
Write-Host ("Date: {0}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz"))

# Profiles (Domain, Private, Public)
Write-Host "`n=== Profile Status (Get-NetFirewallProfile) ===" -ForegroundColor Yellow
try {
    $profiles = Get-NetFirewallProfile -PolicyStore ActiveStore
    $profiles | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction |
        Format-Table -AutoSize
} catch {
    Write-Warning "Get-NetFirewallProfile failed: $_"
}

# Quick counts by direction/action
Write-Host "`n=== Rule Counts (enabled only) ===" -ForegroundColor Yellow
try {
    $enabled = Get-NetFirewallRule -Enabled True
    $counts = $enabled | Group-Object -Property Direction, Action | 
        Select-Object @{n='Direction';e={$_.Group[0].Direction}},
                      @{n='Action';e={$_.Group[0].Action}},
                      @{n='Count';e={$_.Count}}
    $counts | Sort-Object Direction, Action | Format-Table -AutoSize
} catch {
    Write-Warning "Counting rules failed: $_"
}

# Top 40 enabled inbound rules (name/ports/program)
Write-Host "`n=== Enabled Inbound Rules (top 40) ===" -ForegroundColor Yellow
try {
    Get-NetFirewallRule -Direction Inbound -Enabled True |
        Sort-Object -Property DisplayName |
        Select-Object -First 40 |
        Get-NetFirewallPortFilter -ErrorAction SilentlyContinue |
        Select-Object Name, LocalPort, Protocol |
        Format-Table -AutoSize
} catch {
    Write-Warning "Inbound rule listing failed: $_"
}

# Listening ports (netstat)
Write-Host "`n=== Listening Ports Snapshot (netstat -ano) ===" -ForegroundColor Yellow
try {
    netstat -ano | Select-String -Pattern 'LISTENING' | Select-Object -First 40
} catch {
    Write-Warning "netstat failed: $_"
}

# Fallback (legacy) summary
Write-Host "`n=== netsh advfirewall (summary) ===" -ForegroundColor Yellow
try {
    netsh advfirewall show allprofiles
} catch {
    Write-Warning "netsh advfirewall failed: $_"
}

Write-Host "`nSummary:`" -ForegroundColor Cyan
Write-Host "  - Profiles shown above (Domain/Private/Public)"
Write-Host "  - Enabled rule counts by direction/action"
Write-Host "  - Example inbound rules and listening ports"
Write-Host ""
