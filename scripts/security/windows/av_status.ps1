<#
Antivirus / Endpoint Protection Status (Windows)
- Queries Windows Defender (if available) using Get-MpComputerStatus
- Reports real-time protection, signature version/date, and last scan
- Display only (no changes made)
#>

Write-Output ""
Write-Output "Antivirus / Endpoint Protection Status (Windows)" -ForegroundColor Cyan
Write-Output ("Host : {0}" -f $env:COMPUTERNAME)
Write-Output ("OS   : {0}" -f (Get-CimInstance Win32_OperatingSystem).Caption)
Write-Output ("Date : {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'))
Write-Output ""

# Check if Defender cmdlets are available
if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
    try {
        $status = Get-MpComputerStatus

        Write-Output "=== Windows Defender Status ===" -ForegroundColor Yellow
        Write-Output ("Real-time Protection : {0}" -f $status.RealTimeProtectionEnabled)
        Write-Output ("Behavior Monitor     : {0}" -f $status.BehaviorMonitorEnabled)
        Write-Output ("Antispyware Enabled  : {0}" -f $status.AntispywareEnabled)
        Write-Output ("Antivirus Enabled    : {0}" -f $status.AntivirusEnabled)
        Write-Output ("Quick Scan Age (hrs) : {0}" -f $status.QuickScanAge)
        Write-Output ""

        Write-Output "=== Signature / Engine Info ===" -ForegroundColor Yellow
        Write-Output ("AM Engine Version    : {0}" -f $status.AMEngineVersion)
        Write-Output ("AV Signature Version : {0}" -f $status.AntivirusSignatureVersion)
        Write-Output ("AV Signature Date    : {0}" -f $status.AntivirusSignatureLastUpdated)
        Write-Output ("AS Signature Version : {0}" -f $status.AntispywareSignatureVersion)
        Write-Output ("AS Signature Date    : {0}" -f $status.AntispywareSignatureLastUpdated)
        Write-Output ""

        Write-Output "=== Last Scans ===" -ForegroundColor Yellow
        Write-Output ("Full Scan Age (hrs)  : {0}" -f $status.FullScanAge)
        Write-Output ("Last Full Scan Src   : {0}" -f $status.FullScanEndTime)
        Write-Output ("Last Quick Scan Src  : {0}" -f $status.QuickScanEndTime)
    }
    catch {
        Write-Output "Error retrieving Defender status: $_" -ForegroundColor Red
    }
}
else {
    Write-Output "Windows Defender cmdlets not available." -ForegroundColor Red
    Write-Output "This system may be running a third-party antivirus or an older Windows build."
}

Write-Output ""
Write-Output "Summary:" -ForegroundColor Cyan
Write-Output "  - Defender real-time protection and behavior monitoring status"
Write-Output "  - Signature versions and last update dates"
Write-Output "  - Last quick and full scan times"
Write-Output "  - Detects if Defender is disabled or replaced by 3rd-party AV"
Write-Output ""
