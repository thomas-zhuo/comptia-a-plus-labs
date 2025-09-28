<#
.SYNOPSIS
  Local CVE audit (PowerShell). Scans installed packages and compares against a small local CVE DB.

.DESCRIPTION
  - Gathers installed package versions via Get-Package, winget (if present), and a registry uninstall fallback.
  - Maintains an embedded, editable CVE DB (package|fixedVersion|severity|CVEIDs|notes).
  - Flags packages where installedVersion < fixedVersion (based on [Version] comparison when possible).
  - Prints results (display-only). Pipe to Out-File / Tee-Object to save.

USAGE
  # run
  pwsh ./scripts/security/windows/cve_audit.ps1

  # run & save
  pwsh ./scripts/security/windows/cve_audit.ps1 | Tee-Object -FilePath .\scripts\security\windows\cve_audit_windows_$(Get-Date -Format yyyy-MM-dd).txt

NOTES
  - No network calls. Expand $CveDb inside the script as you like.
  - Designed to be tolerant on different Windows versions and on PowerShell Core / Desktop.
#>

# Defensive: don't stop on non-terminating errors
$ErrorActionPreference = 'Continue'

function BoldWrite([string]$text) {
    Write-Host $text -ForegroundColor White -BackgroundColor Black -NoNewline
    Write-Host ""
}

function Hr {
    $width = (Get-Host).UI.RawUI.WindowSize.Width
    if (-not $width -or $width -lt 20) { $width = 80 }
    Write-Host ('-' * $width)
}

# Header
BoldWrite "CVE Risk Audit (Local DB)"
Write-Host ("  Host: {0}" -f ( $env:COMPUTERNAME ))
Write-Host ("  OS  : {0}" -f ( (Get-CimInstance Win32_OperatingSystem).Caption ))
Write-Host ("  Date: {0}" -f (Get-Date))
Hr

# ---------------------
# Collect package inventory
# ---------------------
BoldWrite "Package Inventory (first 20 shown)"

$inventory = @()

# 1) Try Get-Package (PowerShellGet / PackageManagement)
try {
    $gp = Get-Package -ErrorAction SilentlyContinue
    if ($gp) {
        foreach ($p in $gp) {
            # Some providers include entries without Version — skip those
            $name = $p.Name
            $ver  = if ($p.Version) { $p.Version.ToString() } else { '' }
            if ($name) {
                $inventory += [PSCustomObject]@{ Name = $name; Version = $ver; Source = 'Get-Package' }
            }
        }
    }
} catch { }

# 2) Try winget (if available)
if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
    try {
        # winget outputs to stdout; use --silent to cut extraneous messages on newer builds
        $wingetRaw = & winget list 2>$null
        if ($wingetRaw) {
            # winget lines are table-like: Name <tab> Id <tab> Version ...
            # We'll parse lines that look like "Name   Version"
            $parsed = $wingetRaw | Select-Object -Skip 1 | ForEach-Object {
                $line = $_.Trim()
                if ($line -eq '') { continue }
                # Split on two-or-more spaces
                $cols = -split $line -ne ''
                # Simple heuristic: first token(s) name, last token version
                $version = $cols[-1]
                $name = ($cols[0..($cols.Length-2)] -join ' ')
                if ($name) { [PSCustomObject]@{ Name = $name; Version = $version; Source = 'winget' } }
            }
            if ($parsed) {
                # merge, preferring existing records (avoid duplicates)
                foreach ($p in $parsed) {
                    if (-not ($inventory.Name -contains $p.Name)) {
                        $inventory += $p
                    }
                }
            }
        }
    } catch { }
}

# 3) Registry fallback - read Uninstall keys (both 32/64-bit)
try {
    $regPaths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($path in $regPaths) {
        try {
            Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
                $displayName = $_.DisplayName
                $displayVersion = $_.DisplayVersion
                if ($displayName -and -not ($inventory.Name -contains $displayName)) {
                    $inventory += [PSCustomObject]@{ Name = $displayName; Version = ($displayVersion -as [string]); Source = 'Registry' }
                }
            }
        } catch { }
    }
} catch { }

if (-not $inventory) {
    Write-Host "(no packages detected or insufficient privileges)"
} else {
    $inventory | Select-Object Name, Version, Source | Sort-Object Name | Select-Object -First 20 | Format-Table -AutoSize
}
Hr

# ---------------------
# Local CVE DB (edit / expand)
# Format: package|fixedVersion|severity|CVEIDs|notes
# Interpretation: installedVersion < fixedVersion => flagged
# ---------------------
$cveDbLines = @(
"OpenSSL|3.0.14|HIGH|CVE-2023-5678,CVE-2024-1111|Fixed in 3.0.14",
"curl|8.5.0|HIGH|CVE-2023-38545|HTTP/3 heap overflow",
"sudo|1.9.15|CRITICAL|CVE-2021-3156|Example mapping",
"git|2.46.0|HIGH|CVE-2024-32002|Path handling",
"apache2|2.4.62|CRITICAL|CVE-2023-25690|Apache example"
)

# Build DB objects
$cveDB = @{}
foreach ($line in $cveDbLines) {
    $parts = $line -split '\|'
    if ($parts.Length -ge 5) {
        $pkg = $parts[0].Trim()
        $cveDB[$pkg] = [PSCustomObject]@{
            FixedVersion = $parts[1].Trim()
            Severity     = $parts[2].Trim()
            CVEs         = $parts[3].Trim()
            Notes        = $parts[4].Trim()
        }
    }
}

# ---------------------
# Helper: try-parse version to System.Version safely
# ---------------------
function Parse-VersionObject {
    param([string]$vstr)
    if (-not $vstr) { return $null }
    # remove common non-numeric suffixes (like +dfsg-1, -1ubuntu2)
    $clean = $vstr -replace '[^0-9\.]','.' -replace '\.{2,}', '.' -replace '^\.+|\.+$',''
    # try small truncation to 4 parts
    $parts = $clean -split '\.' | Where-Object { $_ -ne '' } 
    if ($parts.Count -gt 4) { $parts = $parts[0..3] }
    $norm = $parts -join '.'
    try {
        return [Version]$norm
    } catch {
        return $null
    }
}

# ---------------------
# Findings header (always printed)
# ---------------------
BoldWrite "Vulnerability Findings (local DB; installed < fixed_version ⇒ at risk)"
"{0,-30} {1,-15} {2,-15} {3,-12} {4,-8} {5}" -f "PACKAGE","INSTALLED","FIXED","STATUS","SEVERITY","CVE_IDS"
Hr

# ---------------------
# Scan inventory against DB
# ---------------------
$matched = $false
$totalChecked = 0
$vulnCount = 0

foreach ($item in $inventory) {
    $name = $item.Name
    $installedVer = ($item.Version -as [string]) -replace ',',''
    if (-not $name) { continue }
    $totalChecked++

    # Try direct DB exact match (case-insensitive)
    $dbEntry = $null
    foreach ($k in $cveDB.Keys) {
        if ($k.Equals($name, 'InvariantCultureIgnoreCase')) {
            $dbEntry = $cveDB[$k]
            break
        }
    }

    # If exact not found, also attempt short-name matching (e.g., apache2 -> Apache)
    if (-not $dbEntry) {
        foreach ($k in $cveDB.Keys) {
            if ($name -match [Regex]::Escape($k) -or $k -match [Regex]::Escape($name)) {
                $dbEntry = $cveDB[$k]; break
            }
        }
    }

    if ($dbEntry) {
        $matched = $true
        $fixedStr = $dbEntry.FixedVersion
        $status = "unknown"
        $sev = $dbEntry.Severity
        $cves = $dbEntry.CVEs

        $instObj = Parse-VersionObject -vstr $installedVer
        $fixedObj = Parse-VersionObject -vstr $fixedStr

        if ($instObj -and $fixedObj) {
            if ($instObj -lt $fixedObj) {
                $status = "VULNERABLE?"
                $vulnCount++
            } else {
                $status = "ok"
            }
        } else {
            # fallback: lexical compare
            if ($installedVer -and ($installedVer -lt $fixedStr)) {
                $status = "VULNERABLE?"
                $vulnCount++
            } else {
                $status = "ok"
            }
        }

        "{0,-30} {1,-15} {2,-15} {3,-12} {4,-8} {5}" -f $name,($installedVer -or '-'),$fixedStr,$status,$sev,$cves
    }
}

Hr
if (-not $matched) {
    Write-Host "No matching packages from the local CVE DB were found in this inventory."
} else {
    Write-Host ("Checked: {0}  Potentially vulnerable: {1}" -f $totalChecked, $vulnCount)
}
Write-Host "Legend: 'VULNERABLE?' means installed_version < fixed_version in local DB."

# End
