<#
Antivirus / Endpoint Protection Status (Windows)
- Queries Windows Defender (if available) using Get-MpComputerStatus
- Reports real-time protection, signature version/date, and last scan
- Display only (no changes made)
#>

Write-Host ""
Write-Host "Antivirus / Endpoint Protection Status (Windows)" -ForegroundColor Cyan
Write-Host ("Host : {0}" -f $env:COMPUTERNAME)
Write-Host ("OS   : {0}" -f (Get-CimInstance Win32_OperatingSystem).Caption)
Write-Host ("Date : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'))
Write-Host ""

# Check if Defender cmdlets are available
if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
    try {
        $status = Get-MpComputerStatus

        Write-Host "=== Windows Defender Status ===" -ForegroundColor Yellow
        Write-Host ("Real-time Protection : {0}" -f $status.RealTimeProtectionEnabled)
        Write-Host ("Behavior Monitor     : {0}" -f $status.BehaviorMonitorEnabled)
        Write-Host ("Antispyware Enabled  : {0}" -f $status.AntispywareEnabled)
        Write-Host ("Antivirus Enabled    : {0}" -f $status.AntivirusEnabled)
        Write-Host ("Quick Scan Age (hrs) : {0}" -f $status.QuickScanAge)
        Write-Host ""

        Write-Host "=== Signature / Engine Info ===" -ForegroundColor Yellow
        Write-Host ("AM Engine Version    : {0}" -f $status.AMEngineVersion)
        Write-Host ("AV Signature Version : {0}" -f $status.AntivirusSignatureVersion)
        Write-Host ("AV Signature Date    : {0}" -f $status.AntivirusSignatureLastUpdated)
        Write-Host ("AS Signature Version : {0}" -f $status.AntispywareSignatureVersion)
        Write-Host ("AS Signature Date    : {0}" -f $status.AntispywareSignatureLastUpdated)
        Write-Host ""

        Write-Host "=== Last Scans ===" -ForegroundColor Yellow
        Write-Host ("Full Scan Age (hrs)  : {0}" -f $status.FullScanAge)
        Write-Host ("Last Full Scan Src   : {0}" -f $status.FullScanEndTime)
        Write-Host ("Last Quick Scan Src  : {0}" -f $status.QuickScanEndTime)
    }
    catch {
        Write-Host "Error retrieving Defender status: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "Windows Defender cmdlets not available." -ForegroundColor Red
    Write-Host "This system may be running a third-party antivirus or an older Windows build."
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  - Defender real-time protection and behavior monitoring status"
Write-Host "  - Signature versions and last update dates"
Write-Host "  - Last quick and full scan times"
Write-Host "  - Detects if Defender is disabled or replaced by 3rd-party AV"
Write-Host ""
