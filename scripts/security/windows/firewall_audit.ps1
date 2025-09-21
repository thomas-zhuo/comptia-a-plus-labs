<# 
Firewall Audit (Windows) — DISPLAY ONLY
Shows profile status, a concise view of enabled rules, and listening ports.
#>

# ----- Header ---------------------------------------------------------------
Write-Output ''
Write-Output 'Firewall Audit — Windows' -ForegroundColor Cyan
$os = (Get-CimInstance Win32_OperatingSystem).Caption
$dt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'
Write-Output ('Host : ' + $env:COMPUTERNAME)
Write-Output ('OS   : ' + $os)
Write-Output ('Date : ' + $dt)

# ----- Profile status -------------------------------------------------------
Write-Output ''
Write-Output '=== Profile Status (Get-NetFirewallProfile) ===' -ForegroundColor Yellow
try {
    Get-NetFirewallProfile -PolicyStore ActiveStore |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction |
        Format-Table -AutoSize
} catch {
    Write-Warning ('Get-NetFirewallProfile failed: ' + $_)
}

# ----- Enabled rule counts (direction/action) -------------------------------
Write-Output ''
Write-Output '=== Rule Counts (enabled only) ===' -ForegroundColor Yellow
try {
    $enabledRules = Get-NetFirewallRule -Enabled True
    $counts = $enabledRules |
        Group-Object -Property Direction, Action |
        Select-Object @{n='Direction';e={$_.Group[0].Direction}},
                      @{n='Action';e={$_.Group[0].Action}},
                      @{n='Count';e={$_.Count}}
    $counts | Sort-Object Direction, Action | Format-Table -AutoSize
} catch {
    Write-Warning ('Counting rules failed: ' + $_)
}

# ----- Enabled inbound rules (example subset) -------------------------------
Write-Output ''
Write-Output '=== Enabled Inbound Rules (top 40) ===' -ForegroundColor Yellow
try {
    $inbound = Get-NetFirewallRule -Direction Inbound -Enabled True |
               Sort-Object -Property DisplayName |
               Select-Object -First 40

    $inbound |
        Get-NetFirewallPortFilter -ErrorAction SilentlyContinue |
        Select-Object Name, LocalPort, Protocol |
        Format-Table -AutoSize
} catch {
    Write-Warning ('Inbound rule listing failed: ' + $_)
}

# ----- Listening ports snapshot --------------------------------------------
Write-Output ''
Write-Output '=== Listening Ports Snapshot (netstat -ano) ===' -ForegroundColor Yellow
try {
    netstat -ano | Select-String -Pattern 'LISTENING' | Select-Object -First 40
} catch {
    Write-Warning ('netstat failed: ' + $_)
}

# ----- Legacy summary (useful on older builds) ------------------------------
Write-Output ''
Write-Output '=== netsh advfirewall (summary) ===' -ForegroundColor Yellow
try {
    netsh advfirewall show allprofiles
} catch {
    Write-Warning ('netsh advfirewall failed: ' + $_)
}

# ----- Summary --------------------------------------------------------------
Write-Output ''
Write-Output 'Summary:' -ForegroundColor Cyan
Write-Output '  - Profile status shown above (Domain/Private/Public)'
Write-Output '  - Counts of enabled rules by direction/action'
Write-Output '  - Example enabled inbound rules (ports/protocols where applicable)'
Write-Output '  - Snapshot of listening ports (pair with rule review)'
Write-Output ''