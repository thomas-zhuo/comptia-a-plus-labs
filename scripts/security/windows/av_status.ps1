<#
Antivirus / Endpoint Protection Status (Windows) — DISPLAY + PIPELINE SAFE
- Matches the style of your existing scripts (Header → Sections → Summary)
- Uses Write-Output so it shows on screen and can be piped to Out-File
- Queries Windows Defender via Get-MpComputerStatus when available
#>

$os = (Get-CimInstance Win32_OperatingSystem).Caption
$dt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'

Write-Output ""
Write-Output "Antivirus / Endpoint Protection Status (Windows)"
Write-Output ("Host : {0}" -f $env:COMPUTERNAME)
Write-Output ("OS   : {0}" -f $os)
Write-Output ("Date : {0}" -f $dt)
Write-Output ""

# Defender available?
if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
    try {
        $s = Get-MpComputerStatus

        Write-Output "=== Windows Defender Status ==="
        Write-Output ("Real-time Protection : {0}" -f $s.RealTimeProtectionEnabled)
        Write-Output ("Behavior Monitor     : {0}" -f $s.BehaviorMonitorEnabled)
        Write-Output ("Antispyware Enabled  : {0}" -f $s.AntispywareEnabled)
        Write-Output ("Antivirus Enabled    : {0}" -f $s.AntivirusEnabled)
        Write-Output ("Quick Scan Age (hrs) : {0}" -f $s.QuickScanAge)
        Write-Output ""

        Write-Output "=== Signature / Engine Info ==="
        Write-Output ("AM Engine Version    : {0}" -f $s.AMEngineVersion)
        Write-Output ("AV Signature Version : {0}" -f $s.AntivirusSignatureVersion)
        Write-Output ("AV Signature Date    : {0}" -f $s.AntivirusSignatureLastUpdated)
        Write-Output ("AS Signature Version : {0}" -f $s.AntispywareSignatureVersion)
        Write-Output ("AS Signature Date    : {0}" -f $s.AntispywareSignatureLastUpdated)
        Write-Output ""

        Write-Output "=== Last Scans ==="
        Write-Output ("Full Scan Age (hrs)  : {0}" -f $s.FullScanAge)
        Write-Output ("Last Full Scan End   : {0}" -f $s.FullScanEndTime)
        Write-Output ("Last Quick Scan End  : {0}" -f $s.QuickScanEndTime)
    }
    catch {
        Write-Output ("ERROR: Failed to retrieve Defender status: {0}" -f $_)
    }
}
else {
    Write-Output "Windows Defender cmdlets not available."
    Write-Output "This system may use a third-party antivirus or an older Windows build."
}

Write-Output ""
Write-Output "Summary:"
Write-Output "  - Real-time protection / behavior monitor status"
Write-Output "  - AV/AS signature versions and last update dates"
Write-Output "  - Last quick/full scan times"
Write-Output "  - Notes if Defender cmdlets are unavailable (third-party AV likely)"
Write-Output ""
