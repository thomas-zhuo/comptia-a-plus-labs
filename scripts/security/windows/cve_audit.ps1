<#
.SYNOPSIS
  Local CVE audit (PowerShell). Compares installed packages to a small embedded CVE DB.

.DESCRIPTION
  - Collects inventory from Get-Package, winget list (if available), then registry uninstall keys.
  - Uses a local, editable CVE DB (package|fixedVersion|severity|CVEIDs|notes).
  - Flags when installedVersion < fixedVersion (with [Version] compare where possible).
  - Display-only. Pipe to Tee-Object / Out-File if you want to save.

USAGE
  # run
  pwsh .\scripts\security\windows\cve_audit.ps1

  # run & save
  pwsh .\scripts\security\windows\cve_audit.ps1 |
    Tee-Object -FilePath .\scripts\security\windows\cve_audit_windows_$(Get-Date -Format 'yyyy-MM-dd').txt
#>

# Make non-terminating errors visible but don’t crash the script
$ErrorActionPreference = 'Continue'
$VerbosePreference = 'SilentlyContinue'
$DebugPreference   = 'SilentlyContinue'

function Hr {
    $w = (Get-Host).UI.RawUI.WindowSize.Width
    if (-not $w -or $w -lt 40) { $w = 110 }
    Write-Host ('-' * $w)
}

function Section($title) {
    Write-Host $title -ForegroundColor White
}

function Parse-VersionObject {
    param([string]$vstr)
    if (-not $vstr) { return $null }
    # Normalize: strip non-numeric/separator chars, collapse dots, trim edges
    $clean = $vstr -replace '[^0-9\.]','.' -replace '\.{2,}', '.' -replace '^\.+|\.+$',''
    $parts = $clean -split '\.' | Where-Object { $_ -ne '' }
    if ($parts.Count -gt 4) { $parts = $parts[0..3] }
    $norm = ($parts -join '.')
    try { return [Version]$norm } catch { return $null }
}

# --------------------------------- Header ---------------------------------
Section "CVE Risk Audit (Local DB)"
Write-Host ("  Host: {0}" -f $env:COMPUTERNAME)
$osCaption = (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).Caption
Write-Host ("  OS  : {0}" -f ($osCaption ?? 'Windows'))
Write-Host ("  Date: {0}" -f (Get-Date))
Hr

# --------------------------- Package Inventory ----------------------------
Section "Package Inventory (first 20 shown)"

$inventory = New-Object System.Collections.Generic.List[object]

# 1) Get-Package
try {
    $gp = Get-Package -ErrorAction SilentlyContinue
    if ($gp) {
        foreach ($p in $gp) {
            $name = $p.Name
            $ver  = if ($p.Version) { $p.Version.ToString() } else { '' }
            if ($name) {
                $inventory.Add([PSCustomObject]@{
                    Name = $name; Version = $ver; Source = 'Get-Package'
                })
            }
        }
    }
} catch { }

# 2) winget list (if available)
if (Get-Command winget.exe -ErrorAction SilentlyContinue) {
    try {
        # Avoid UI paging; parse simply: last token is version, rest is name
        $wingetOut = & winget list --accept-source-agreements 2>$null
        if ($wingetOut) {
            $lines = $wingetOut | Select-Object -Skip 1
            foreach ($ln in $lines) {
                $s = $ln.Trim()
                if (-not $s) { continue }
                # Split on 2+ spaces to approximate columns
                $cols = ($s -split '\s{2,}').Trim() | Where-Object { $_ -ne '' }
                if ($cols.Count -ge 2) {
                    $version = $cols[-1]
                    $name    = ($cols[0..($cols.Count-2)] -join ' ')
                    if ($name -and -not ($inventory.Name -contains $name)) {
                        $inventory.Add([PSCustomObject]@{
                            Name = $name; Version = $version; Source = 'winget'
                        })
                    }
                }
            }
        }
    } catch { }
}

# 3) Registry uninstall keys (fill gaps)
try {
    $regPaths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($p in $regPaths) {
        try {
            Get-ItemProperty -Path $p -ErrorAction SilentlyContinue | ForEach-Object {
                $dn = $_.DisplayName
                $dv = $_.DisplayVersion
                if ($dn -and -not ($inventory.Name -contains $dn)) {
                    $inventory.Add([PSCustomObject]@{
                        Name = $dn; Version = ($dv -as [string]); Source = 'Registry'
                    })
                }
            }
        } catch { }
    }
} catch { }

# Print first 20 safely (force enumeration & string conversion so it never “hangs”)
if ($inventory.Count -eq 0) {
    Write-Host "(no packages detected or insufficient privileges)"
} else {
    $inventory
      | Sort-Object Name
      | Select-Object Name, Version, Source -First 20
      | Format-Table -AutoSize
      | Out-String
      | Write-Output
}
Hr

# ------------------------------ Local CVE DB -------------------------------
# Format per line: package|fixedVersion|severity|CVEIDs|notes
# NOTE: match names exactly as they appear in your inventory where possible.
$cveDbLines = @(
"OpenSSL|3.0.14|HIGH|CVE-2023-5678,CVE-2024-1111|Fixed in 3.0.14",
"curl|8.5.0|HIGH|CVE-2023-38545|HTTP/3 heap overflow",
"sudo|1.9.15|CRITICAL|CVE-2021-3156|Example mapping",
"git|2.46.0|HIGH|CVE-2024-32002|Path handling",
"apache2|2.4.62|CRITICAL|CVE-2023-25690|Apache example"
)

# Build DB (case-insensitive lookup)
$cveDB = @{}
foreach ($line in $cveDbLines) {
    $parts = $line -split '\|'
    if ($parts.Length -ge 5) {
        $key = $parts[0].Trim()
        $cveDB[$key.ToLowerInvariant()] = [PSCustomObject]@{
            FixedVersion = $parts[1].Trim()
            Severity     = $parts[2].Trim()
            CVEs         = $parts[3].Trim()
            Notes        = $parts[4].Trim()
        }
    }
}

# --------------------------- Findings (always prints) -----------------------
Section "Vulnerability Findings (local DB; installed < fixed_version ⇒ at risk)"
"{0,-30} {1,-15} {2,-15} {3,-12} {4,-9} {5}" -f "PACKAGE","INSTALLED","FIXED","STATUS","SEVERITY","CVE_IDS"
Hr

$matched      = $false
$totalChecked = 0
$vulnCount    = 0

foreach ($item in $inventory) {
    $name = $item.Name
    $inst = ($item.Version -as [string]) -replace ',',''
    if (-not $name) { continue }
    $totalChecked++

    # Try exact (case-insensitive) match
    $dbEntry = $null
    $key = $name.ToLowerInvariant()
    if ($cveDB.ContainsKey($key)) {
        $dbEntry = $cveDB[$key]
    } else {
        # Simple fallback: substring match in either direction
        foreach ($k in $cveDB.Keys) {
            if ($key.Contains($k) -or $k.Contains($key)) { $dbEntry = $cveDB[$k]; break }
        }
    }

    if ($dbEntry) {
        $matched = $true
        $fixedStr = $dbEntry.FixedVersion
        $sev      = $dbEntry.Severity
        $cves     = $dbEntry.CVEs
        $status   = "ok"

        $instObj  = Parse-VersionObject $inst
        $fixedObj = Parse-VersionObject $fixedStr

        if ($instObj -and $fixedObj) {
            if ($instObj -lt $fixedObj) { $status = "VULNERABLE?"; $vulnCount++ }
        } else {
            # lexical fallback if version parsing fails
            if ($inst -and ($inst -lt $fixedStr)) { $status = "VULNERABLE?"; $vulnCount++ }
        }

        "{0,-30} {1,-15} {2,-15} {3,-12} {4,-9} {5}" -f $name, ($inst -or '-'), $fixedStr, $status, $sev, $cves
    }
}

Hr
if (-not $matched) {
    Write-Host "No matching packages from the local CVE DB were found in this inventory."
} else {
    Write-Host ("Checked: {0}   Potentially vulnerable: {1}" -f $totalChecked, $vulnCount)
}
Write-Host "Legend: 'VULNERABLE?' means installed_version < fixed_version in local DB."
