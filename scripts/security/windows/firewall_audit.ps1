<# 
Firewall Audit (Windows) — DISPLAY ONLY
Shows profile status plus a concise view of enabled rules and listening ports.
#>

# ----- Header ---------------------------------------------------------------
Write-Host ""
Write-Host "Firewall Audit — Windows" -ForegroundColor Cyan
Write-Host ("Host : {0}" -f $env:COMPUTERNAME)
Write-Host ("OS   : {0}" -f (Get-CimInstance Win32_OperatingSystem).Caption)
Write-Host ("Date : {0}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss zzz"))

# ----- Profile status -------------------------------------------------------
Write-Host ""
Write-Host "=== Profile Status (Get-NetFirewallProfile) ===" -ForegroundColor Yellow
try {
    $profiles = Get-NetFirewallProfile -PolicyStore ActiveStore
    $profiles |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction |
        Format-Table -AutoSize
}
catch {
    Write-Warning ("Get-NetFirewallProfile failed: {0}" -f $_)
}

# ----- Enabled rule counts (direction/action) -------------------------------
Write-Host ""
Write-Host "=== Rule Counts (enabled only) ===" -ForegroundColor Yellow
try {
    $enabledRules = Get-NetFirewallRule -Enabled True
    $counts = $enabledRules |
        Group-Object -Property Direction, Action |
        Select-Object @{n='Direction';e={$_.Group[0].Direction}},
                      @{n='Action';e={$_.Group[0].Action}},
                      @{n='Count';e={$_.Count}}

    $counts | Sort-Object Direction, Action | Format-Table -AutoSize
}
catch {
    Write-Warning ("Counting rules failed: {0}" -f $_)
}

# ----- Enabled inbound rules (example subset) -------------------------------
Write-Host ""
Write-Host "=== Enabled Inbound Rules (top 40) ===" -ForegroundColor Yellow
try {
    # Pull top 40 by name, then show ports/protocol where available
    $inbound = Get-NetFirewallRule -Direction Inbound -Enabled True |
               Sort-Object -Property DisplayName |
               Select-Object -First 40

    # Join with port filter info (may be empty for program/path rules)
    $inbound |
        Get-NetFirewallPortFilter -ErrorAction SilentlyContinue |
        Select-Object Name, LocalPort, Protocol |
        Format-Table -AutoSize
}
catch {
    Write-Warning ("Inbound rule listing failed: {0}" -f $_)
}

# ----- Listening ports snapshot --------------------------------------------
Write-Host ""
Write-Host "=== Listening Ports Snapshot (netstat -ano) ===" -ForegroundColor Yellow
try {
    netstat -ano | Select-String -Pattern 'LISTENING' | Select-Object -First 40
}
catch {
    Write-Warning ("netstat failed: {0}" -f $_)
}

# ----- Legacy summary (useful on older builds) ------------------------------
Write-Host ""
Write-Host "=== netsh advfirewall (summary) ===" -ForegroundColor Yellow
try {
    netsh advfirewall show allprofiles
}
catch {
    Write-Warning ("netsh advfirewall failed: {0}" -f $_)
}

# ----- Summary --------------------------------------------------------------
Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Profile status shown above (Domain/Private/Public)"
Write-Host "  - Counts of enabled rules by direction/action"
Write-Host "  - Example enabled inbound rules (ports/protocols where applicable)"
Write-Host "  - Snapshot of listening ports (pair with rule review)"
Write-Host ""
