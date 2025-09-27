<#
Patch & Update Compliance Audit (Windows) — DISPLAY + PIPELINE SAFE
- Shows OS build, installed hotfix summary, pending updates (via Windows Update API),
  last install time (best effort), and reboot-pending state.
- Uses Write-Output so results display and can be piped to Out-File/Tee-Object.
#>

# -------- Helpers -----------------------------------------------------------
function Show-Table {
    param([Parameter(ValueFromPipeline=$true)] $InputObject)
    $sb = [System.Text.StringBuilder]::new()
    ($InputObject | Format-Table -AutoSize | Out-String) -split "`r?`n" | ForEach-Object {
        [void]$sb.AppendLine($_)
    }
    Write-Output ($sb.ToString().TrimEnd())
}

function Test-RebootPending {
    # Checks common locations used by Windows to signal a pending reboot.
    $pending = $false
    try {
        $paths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending',
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'
        )
        foreach ($p in $paths) {
            if (Test-Path $p) { $pending = $true }
        }
        # Pending file rename operations
        $pfro = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -Name 'PendingFileRenameOperations' -ErrorAction SilentlyContinue)
        if ($pfro) { $pending = $true }
    } catch { }
    return $pending
}

# -------- Header ------------------------------------------------------------
$os = (Get-CimInstance Win32_OperatingSystem)
$dt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'

Write-Output ""
Write-Output "Patch & Update Compliance Audit (Windows)"
Write-Output ("Host : {0}" -f $env:COMPUTERNAME)
Write-Output ("OS   : {0} (Build {1})" -f $os.Caption, $os.BuildNumber)
Write-Output ("Date : {0}" -f $dt)
Write-Output ""

# -------- Installed hotfixes (summary) -------------------------------------
Write-Output "=== Recently Installed Hotfixes (Get-HotFix) ==="
try {
    $hotfixes = Get-HotFix | Sort-Object -Property InstalledOn -Descending
    if ($hotfixes) {
        # Show top 15 for brevity
        $hotfixes | Select-Object -First 15 HotFixID, Description, InstalledOn | Show-Table
        $latest = $hotfixes | Select-Object -First 1
        if ($latest) {
            Write-Output ("Most recent hotfix : {0} on {1}" -f $latest.HotFixID, $latest.InstalledOn)
        }
    } else {
        Write-Output "No hotfixes returned."
    }
} catch {
    Write-Output ("ERROR: Get-HotFix failed: {0}" -f $_)
}
Write-Output ""

# -------- Pending updates (Windows Update API) ------------------------------
Write-Output "=== Pending Updates (Windows Update API) ==="
try {
    # COM API works on stock PowerShell without extra modules
    $session   = New-Object -ComObject Microsoft.Update.Session
    $searcher  = $session.CreateUpdateSearcher()
    # Search criteria: updates that are not installed and not hidden
    $result    = $searcher.Search("IsInstalled=0 and IsHidden=0")

    if ($result.Updates.Count -gt 0) {
        $list = @()
        for ($i = 0; $i -lt $result.Updates.Count; $i++) {
            $u = $result.Updates.Item($i)
            # Some fields can be null on older entries; guard with fallback text
            $title = if ($u.Title) { $u.Title } else { "Update" }
            $kb    = ($u.KBArticleIDs -join ',')
            if (-not $kb -or $kb -eq '') { $kb = '-' }
            $sev   = if ($u.MsrcSeverity) { $u.MsrcSeverity } else { '-' }
            $cat   = ($u.Categories | Select-Object -ExpandProperty Name) -join ', '
            if (-not $cat -or $cat -eq '') { $cat = '-' }

            $list += [pscustomobject]@{
                KB        = $kb
                Title     = $title
                Severity  = $sev
                Category  = $cat
            }
        }
        $list | Select-Object KB, Severity, Category, Title | Show-Table
        Write-Output ("Pending update count : {0}" -f $result.Updates.Count)
    } else {
        Write-Output "No pending updates found."
    }
} catch {
    Write-Output ("WARN: Could not query pending updates via Windows Update API: {0}" -f $_)
}
Write-Output ""

# -------- Last update time (best effort) ------------------------------------
Write-Output "=== Last Update Installation Time (best effort) ==="
try {
    # From the most recent hotfix above (if available)
    if ($hotfixes -and $hotfixes.Count -gt 0) {
        $lastInstall = ($hotfixes | Select-Object -First 1).InstalledOn
        Write-Output ("Latest hotfix install date : {0}" -f $lastInstall)
    } else {
        Write-Output "No hotfix data to infer last install date."
    }
} catch {
    Write-Output ("WARN: Could not determine last install date: {0}" -f $_)
}
Write-Output ""

# -------- Reboot pending? ---------------------------------------------------
Write-Output "=== Reboot Pending State ==="
try {
    $needsReboot = Test-RebootPending
    Write-Output ("Reboot pending : {0}" -f $needsReboot)
} catch {
    Write-Output ("WARN: Reboot pending check failed: {0}" -f $_)
}
Write-Output ""

# -------- Summary -----------------------------------------------------------
Write-Output "Summary:"
Write-Output "  - OS build and recent hotfixes listed (top 15)."
Write-Output "  - Pending updates queried via Windows Update API (title/KB/severity/category)."
Write-Output "  - Last install date inferred from latest hotfix."
Write-Output "  - Reboot pending flag reported from standard registry locations."
Write-Output ""
