<# 
CVE Audit (Local DB) — Windows PowerShell 5.1 compatible
- Gathers inventory via Get-Package, winget (if present), and registry
- Compares against a small local CVE DB (edit inside script)
- Always prints findings header & summary (even with zero matches)
- Display-only; to save, pipe to Out-File or Tee-Object
#>

param(
  [switch]$VerboseMode
)
if ($VerboseMode) { $VerbosePreference='Continue'; $DebugPreference='Continue' }

$ErrorActionPreference = 'Continue'

function Write-Bold($Text) { Write-Host $Text -ForegroundColor White }
function Write-HR {
  try { $w = (Get-Host).UI.RawUI.WindowSize.Width } catch { $w = 80 }
  if (-not $w -or $w -lt 20) { $w = 80 }
  Write-Host ('-' * $w)
}

# --- Header ---
$computer = $env:COMPUTERNAME
$osObj = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$osCaption = $null
if ($osObj -and $osObj.Caption) { $osCaption = $osObj.Caption } else { $osCaption = 'Windows' }

Write-Bold "CVE Risk Audit (Local DB)"
Write-Host ("  Host: {0}" -f $computer)
Write-Host ("  OS  : {0}" -f $osCaption)
Write-Host ("  Date: {0}" -f (Get-Date))
Write-HR

# --- Inventory ---
Write-Bold "Package Inventory (first 20 shown)"
$inventory = New-Object System.Collections.Generic.List[object]

# 1) Get-Package
try {
  $gp = Get-Package -ErrorAction SilentlyContinue
  if ($gp) {
    foreach ($p in $gp) {
      $name = $p.Name
      $ver  = if ($p.Version) { $p.Version.ToString() } else { '' }
      if ($name) {
        $inventory.Add([pscustomobject]@{ Name=$name; Version=$ver; Source='Get-Package' }) | Out-Null
      }
    }
  }
} catch {}

# 2) winget (optional)
$hasWinget = Get-Command winget.exe -ErrorAction SilentlyContinue
if ($hasWinget) {
  try {
    $wingetLines = & winget list 2>$null
    if ($wingetLines) {
      # crude parse: table-ish; take last token as Version, the rest as Name (skip header separators)
      foreach ($line in $wingetLines) {
        $L = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($L)) { continue }
        if ($L -match '^-+$') { continue }
        if ($L -like '*Name*Id*Version*') { continue }
        $cols = $L -split '\s{2,}'
        if ($cols.Count -ge 2) {
          $ver = $cols[-1]
          $name = ($cols[0..($cols.Count-2)] -join ' ')
          if ($name -and -not ($inventory | Where-Object { $_.Name -eq $name })) {
            $inventory.Add([pscustomobject]@{ Name=$name; Version=$ver; Source='winget' }) | Out-Null
          }
        }
      }
    }
  } catch {}
}

# 3) Registry fallback
$regPaths = @(
  'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($path in $regPaths) {
  try {
    Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
      $dn = $_.DisplayName
      if ($dn -and -not ($inventory | Where-Object { $_.Name -eq $dn })) {
        $inventory.Add([pscustomobject]@{
          Name=$dn
          Version=($_.DisplayVersion -as [string])
          Source='Registry'
        }) | Out-Null
      }
    }
  } catch {}
}

if ($inventory.Count -eq 0) {
  Write-Host "(no packages detected or insufficient privileges)"
} else {
  $first20 = $inventory | Select-Object Name,Version,Source | Sort-Object Name | Select-Object -First 20
  # Show as a table without leading pipe continuations
  $tableText = $first20 | Format-Table -AutoSize | Out-String
  Write-Host $tableText
}
Write-HR

# --- Local CVE DB (edit/extend freely) ---
# Format: package|fixedVersion|severity|CVEIDs|notes
$cveDbLines = @(
  'OpenSSL|3.0.14|HIGH|CVE-2023-5678,CVE-2024-1111|Fixed in 3.0.14',
  'curl|8.5.0|HIGH|CVE-2023-38545|HTTP/3 heap overflow',
  'sudo|1.9.15|CRITICAL|CVE-2021-3156|Example mapping',
  'git|2.46.0|HIGH|CVE-2024-32002|Path handling',
  'apache2|2.4.62|CRITICAL|CVE-2023-25690|Apache example'
)
$cveDB = @{}
foreach ($line in $cveDbLines) {
  $parts = $line -split '\|'
  if ($parts.Count -ge 5) {
    $pkg = $parts[0].Trim()
    $cveDB[$pkg] = [pscustomobject]@{
      FixedVersion = $parts[1].Trim()
      Severity     = $parts[2].Trim()
      CVEs         = $parts[3].Trim()
      Notes        = $parts[4].Trim()
    }
  }
}

# --- Helpers ---
function Convert-ToVersion {
  param([string]$v)
  if (-not $v) { return $null }
  # keep digits and dots; collapse repeats; trim ends
  $clean = ($v -replace '[^0-9\.]','.') -replace '\.{2,}','.' 
  $clean = $clean.Trim('.')
  if (-not $clean) { return $null }
  $parts = $clean -split '\.'
  if ($parts.Count -gt 4) { $parts = $parts[0..3] }
  $norm = ($parts | Where-Object { $_ -ne '' }) -join '.'
  try { return [Version]$norm } catch { return $null }
}

# --- Findings (always print header) ---
Write-Bold "Vulnerability Findings (local DB; installed < fixed_version ⇒ at risk)"
$fmtHeader = "{0,-30} {1,-15} {2,-15} {3,-12} {4,-8} {5}"
$fmtRow    = "{0,-30} {1,-15} {2,-15} {3,-12} {4,-8} {5}"
$header    = $fmtHeader -f 'PACKAGE','INSTALLED','FIXED','STATUS','SEVERITY','CVE_IDS'
Write-Host $header
Write-HR

$matched = $false
$totalChecked = 0
$vulnCount = 0

foreach ($item in $inventory) {
  $name = $item.Name
  $installed = ($item.Version -as [string])
  if (-not $name) { continue }
  $totalChecked++

  # case-insensitive key lookup
  $entry = $null
  foreach ($k in $cveDB.Keys) {
    if ($k.Equals($name, [System.StringComparison]::InvariantCultureIgnoreCase)) {
      $entry = $cveDB[$k]; break
    }
  }
  if (-not $entry) {
    # loose contains match (best-effort)
    foreach ($k in $cveDB.Keys) {
      if ($name -like "*$k*" -or $k -like "*$name*") { $entry = $cveDB[$k]; break }
    }
  }
  if (-not $entry) { continue }

  $matched = $true
  $fixedStr = $entry.FixedVersion
  $sev = $entry.Severity
  $cves = $entry.CVEs

  $instV = Convert-ToVersion $installed
  $fixV  = Convert-ToVersion $fixedStr

  $status = 'unknown'
  if ($instV -and $fixV) {
    if ($instV -lt $fixV) { $status = 'VULNERABLE?'; $vulnCount++ } else { $status = 'ok' }
  } else {
    # fallback lexical
    if ($installed -and ($installed -lt $fixedStr)) { $status = 'VULNERABLE?'; $vulnCount++ } else { $status = 'ok' }
  }

  $line = $fmtRow -f $name, ($installed -or '-'), $fixedStr, $status, $sev, $cves
  Write-Host $line
}

Write-HR
if (-not $matched) {
  Write-Host "No matching packages from the local CVE DB were found in this inventory."
} else {
  Write-Host ("Checked: {0}  Potentially vulnerable: {1}" -f $totalChecked, $vulnCount)
}
Write-Host "Legend: 'VULNERABLE?' means installed_version < fixed_version in local DB."
