<# 
CVE Audit (Local DB) — Windows PowerShell 5.1 compatible, non-blocking inventory
- Fast: Registry first; Get-Package / winget each run in a background job with a timeout
- Always prints findings header & summary (even with zero matches)
- Display-only; pipe to Out-File / Tee-Object to save output
#>

param([switch]$VerboseMode)
if ($VerboseMode) { $VerbosePreference='Continue'; $DebugPreference='Continue' }
$ErrorActionPreference = 'Continue'

function Write-Bold($Text){ Write-Local $Text -ForegroundColor White }
function Write-HR{
  try { $w = (Get-Host).UI.RawUI.WindowSize.Width } catch { $w = 80 }
  if (-not $w -or $w -lt 20){ $w = 80 }
  Write-Local ('-' * $w)
}

# ---------- Header ----------
$computer = $env:COMPUTERNAME
$osObj = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$osCaption = if ($osObj -and $osObj.Caption) { $osObj.Caption } else { 'Windows' }

Write-Bold "CVE Risk Audit (Local DB)"
Write-Local ("  Host: {0}" -f $computer)
Write-Local ("  OS  : {0}" -f $osCaption)
Write-Local ("  Date: {0}" -f (Get-Date))
Write-HR

# ---------- Inventory (non-blocking) ----------
Write-Bold "Package Inventory (first 20 shown)"
$inventory = New-Object System.Collections.Generic.List[object]

# 0) Registry (fast and reliable)
$regPaths = @(
  'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
  'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach ($path in $regPaths){
  try{
    Get-ItemProperty -Path $path -ErrorAction SilentlyContinue | ForEach-Object {
      $dn = $_.DisplayName; $dv = $_.DisplayVersion -as [string]
      if ($dn -and -not ($inventory | Where-Object { $_.Name -eq $dn })){
        $inventory.Add([pscustomobject]@{ Name=$dn; Version=$dv; Source='Registry' }) | Out-Null
      }
    }
  }catch{}
}

# helper: run a scriptblock as a job with timeout and return output or $null
function Invoke-WithTimeout {
  param([scriptblock]$ScriptBlock,[int]$Seconds=8)
  $job = Start-Job -ScriptBlock $ScriptBlock
  if (Wait-Job -Job $job -Timeout $Seconds){
    try { $out = Receive-Job -Job $job -ErrorAction SilentlyContinue } finally { Remove-Job $job -Force | Out-Null }
    return $out
  }else{
    Stop-Job $job -Force | Out-Null
    Remove-Job $job -Force | Out-Null
    Write-Verbose "Timed out after $Seconds s: $($ScriptBlock.ToString())"
    return $null
  }
}

# 1) Get-Package (limit to Programs provider; can be slow otherwise) — run with timeout
$gpOut = Invoke-WithTimeout -Seconds 8 -ScriptBlock {
  try { Get-Package -ProviderName Programs -ErrorAction SilentlyContinue } catch {}
}
if ($gpOut){
  foreach ($p in $gpOut){
    $name = $p.Name
    $ver  = if ($p.Version){ $p.Version.ToString() } else { '' }
    if ($name -and -not ($inventory | Where-Object { $_.Name -eq $name })){
      $inventory.Add([pscustomobject]@{ Name=$name; Version=$ver; Source='Get-Package' }) | Out-Null
    }
  }
}

# 2) winget (non-interactive; may not exist) — run with timeout
if (Get-Command winget.exe -ErrorAction SilentlyContinue){
  $wgOut = Invoke-WithTimeout -Seconds 8 -ScriptBlock {
    try { & winget list --accept-source-agreements --disable-interactivity 2>$null } catch {}
  }
  if ($wgOut){
    foreach ($line in $wgOut){
      $L = ($line -as [string]).Trim()
      if ([string]::IsNullOrWhiteSpace($L)) { continue }
      if ($L -like '*Name*Id*Version*' -or $L -match '^-+$') { continue }
      $cols = $L -split '\s{2,}'
      if ($cols.Count -ge 2){
        $ver = $cols[-1]; $name = ($cols[0..($cols.Count-2)] -join ' ')
        if ($name -and -not ($inventory | Where-Object { $_.Name -eq $name })){
          $inventory.Add([pscustomobject]@{ Name=$name; Version=$ver; Source='winget' }) | Out-Null
        }
      }
    }
  }
}

# Print inventory (never blocks)
if ($inventory.Count -eq 0){
  Write-Local "(no packages detected or insufficient privileges)"
}else{
  $first20 = $inventory | Select-Object Name,Version,Source | Sort-Object Name | Select-Object -First 20
  $tableText = $first20 | Format-Table -AutoSize | Out-String
  Write-Local $tableText
}
Write-HR

# ---------- Local CVE DB (edit freely) ----------
# Format: package|fixedVersion|severity|CVEIDs|notes
$cveDbLines = @(
  'OpenSSL|3.0.14|HIGH|CVE-2023-5678,CVE-2024-1111|Fixed in 3.0.14',
  'curl|8.5.0|HIGH|CVE-2023-38545|HTTP/3 heap overflow',
  'git|2.46.0|HIGH|CVE-2024-32002|Path handling',
  'apache|2.4.62|CRITICAL|CVE-2023-25690|Apache example',
  'Microsoft Edge|129.0.0|HIGH|CVE-2024-XXXX|Example mapping'
)
$cveDB = @{}
foreach ($line in $cveDbLines){
  $parts = $line -split '\|'
  if ($parts.Count -ge 5){
    $pkg = $parts[0].Trim()
    $cveDB[$pkg] = [pscustomobject]@{
      FixedVersion = $parts[1].Trim()
      Severity     = $parts[2].Trim()
      CVEs         = $parts[3].Trim()
      Notes        = $parts[4].Trim()
    }
  }
}

# ---------- Helpers ----------
function Convert-ToVersion {
  param([string]$v)
  if (-not $v){ return $null }
  $clean = ($v -replace '[^0-9\.]','.') -replace '\.{2,}','.' 
  $clean = $clean.Trim('.')
  if (-not $clean){ return $null }
  $parts = $clean -split '\.'
  if ($parts.Count -gt 4){ $parts = $parts[0..3] }
  $norm = ($parts | Where-Object { $_ -ne '' }) -join '.'
  try { return [Version]$norm } catch { return $null }
}

# ---------- Findings ----------
Write-Bold "Vulnerability Findings (local DB; installed < fixed_version ⇒ at risk)"
$fmt = "{0,-30} {1,-15} {2,-15} {3,-12} {4,-8} {5}"
Write-Local ($fmt -f 'PACKAGE','INSTALLED','FIXED','STATUS','SEVERITY','CVE_IDS')
Write-HR

$matched = $false; $totalChecked = 0; $vulnCount = 0

foreach ($item in $inventory){
  $name = $item.Name
  $installed = ($item.Version -as [string])
  if (-not $name){ continue }
  $totalChecked++

  # exact (case-insensitive) or loose contains matching
  $entry = $null
  foreach ($k in $cveDB.Keys){
    if ($k.Equals($name, [System.StringComparison]::InvariantCultureIgnoreCase)) { $entry = $cveDB[$k]; break }
  }
  if (-not $entry){
    foreach ($k in $cveDB.Keys){
      if ($name -like "*$k*" -or $k -like "*$name*"){ $entry = $cveDB[$k]; break }
    }
  }
  if (-not $entry){ continue }

  $matched = $true
  $fixedStr = $entry.FixedVersion; $sev = $entry.Severity; $cves = $entry.CVEs
  $instV = Convert-ToVersion $installed; $fixV = Convert-ToVersion $fixedStr

  $status = 'unknown'
  if ($instV -and $fixV){
    if ($instV -lt $fixV){ $status='VULNERABLE?'; $vulnCount++ } else { $status='ok' }
  } else {
    if ($installed -and ($installed -lt $fixedStr)){ $status='VULNERABLE?'; $vulnCount++ } else { $status='ok' }
  }

  Write-Local ($fmt -f $name, ($installed -or '-'), $fixedStr, $status, $sev, $cves)
}

Write-HR
if (-not $matched){
  Write-Local "No matching packages from the local CVE DB were found in this inventory."
}else{
  Write-Local ("Checked: {0}  Potentially vulnerable: {1}" -f $totalChecked, $vulnCount)
}
Write-Local "Legend: 'VULNERABLE?' means installed_version < fixed_version in local DB."
