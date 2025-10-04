<#
User / Group Permission Hardening Check — Windows (PowerShell 5.1 compatible)
Display-only; send output to pipeline so you can:  ... | Tee-Object -FilePath out.txt
#>

param([switch]$VerboseMode)
if ($VerboseMode) { $VerbosePreference='Continue'; $DebugPreference='Continue' }
$ErrorActionPreference = 'Continue'

function Write-HR {
  $w = 80; try { $w = (Get-Host).UI.RawUI.WindowSize.Width } catch {}
  Write-Output ('-' * $w)
}

# ---------- Header ----------
$computer = $env:COMPUTERNAME
$osObj = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$osCaption = if ($osObj -and $osObj.Caption) { $osObj.Caption } else { 'Windows' }

Write-Output "User & Permission Hardening Audit"
Write-Output ("  Host : {0}" -f $computer)
Write-Output ("  OS   : {0}" -f $osCaption)
Write-Output ("  Date : {0}" -f (Get-Date))
Write-HR

# ---------- Local users via `net user` ----------
Write-Output "Local users (summary via 'net user')"

$users = @()
try {
  $usersRaw = net user 2>&1
  foreach ($line in $usersRaw) {
    if ($line -match 'The command completed successfully') { break }
    if ($line -match 'User accounts') { continue }
    if ($line -match '---+') { continue }
    $parts = $line -split '\s{2,}' | Where-Object { $_ -and $_ -ne $computer }
    foreach ($p in $parts) {
      $name = $p.Trim()
      if ($name -and $name -notmatch '^User$|^accounts$|^for$') {
        $users += $name
      }
    }
  }
  $users = $users | Select-Object -Unique
} catch {
  Write-Output "  (error running 'net user': $_)"
}

if (-not $users -or $users.Count -eq 0) {
  Write-Output "  (no local users found via net user)"
} else {
  foreach ($u in $users) {
    $detail = net user $u 2>$null
    if ($detail) {
      $pwdReq     = (($detail | Select-String 'Password required').ToString() -replace 'Password required\s+','').Trim()
      $pwdExpires = (($detail | Select-String 'Password expires').ToString() -replace 'Password expires\s+','').Trim()
      $acctActive = (($detail | Select-String 'Account active').ToString()  -replace 'Account active\s+','').Trim()
      $lastSet    = (($detail | Select-String 'Password last set').ToString() -replace 'Password last set\s+','').Trim()
      if (-not $pwdReq)     { $pwdReq = '-' }
      if (-not $pwdExpires) { $pwdExpires = '-' }
      if (-not $acctActive) { $acctActive = '-' }
      if (-not $lastSet)    { $lastSet = '-' }
      Write-Output ("  {0,-20}  Active: {1,-6}  PwdReq: {2,-6}  PwdExpires: {3,-20}  PwdLastSet: {4}" -f $u,$acctActive,$pwdReq,$pwdExpires,$lastSet)
    } else {
      Write-Output ("  {0,-20}  (no detail available)" -f $u)
    }
  }
}
Write-HR

# ---------- Disabled accounts ----------
Write-Output "Disabled accounts (best-effort)"
try {
  $disabled = @()
  foreach ($u in ($users | Where-Object { $_ })) {
    $detail = net user $u 2>$null
    if ($detail -and ($detail -match 'Account active\s+No')) { $disabled += $u }
  }
  if ($disabled.Count -eq 0) { Write-Output "  (none detected)" }
  else { $disabled | ForEach-Object { Write-Output ("  {0}" -f $_) } }
} catch { Write-Output "  (error: $_)" }
Write-HR

# ---------- Admin / privileged groups ----------
Write-Output "Admin / Privileged group membership"
$groupsToCheck = @('Administrators','Remote Desktop Users','Remote Desktop','Power Users')
foreach ($g in $groupsToCheck) {
  try {
    $members = net localgroup "$g" 2>$null
    if (-not $members) {
      Write-Output ("  {0,-22} -> (not present / cannot enumerate)" -f $g)
      continue
    }
    $memberLines = $members | Where-Object {
      $_ -and $_ -notmatch '^-|^The command completed successfully|^Alias name|^Comment|^Members'
    }
    $collected = @()
    foreach ($ml in $memberLines) {
      $line = $ml.Trim()
      if ($line -eq '') { continue }
      $parts = $line -split '\s{2,}' | Where-Object { $_ -ne '' }
      foreach ($p in $parts) {
        if ($p -and $p -notmatch '^\*') { $collected += $p.Trim() }
      }
    }
    $collected = $collected | Select-Object -Unique
    if ($collected -and $collected.Count -gt 0) {
      Write-Output ("  {0,-22} -> {1}" -f $g, ($collected -join ', '))
    } else {
      Write-Output ("  {0,-22} -> (none)" -f $g)
    }
  } catch {
    Write-Output ("  {0,-22} -> (error: $_)" -f $g)
  }
}
Write-HR

# ---------- PasswordNeverExpires (ADSI) ----------
Write-Output "Accounts with PasswordNeverExpires (best-effort)"
try {
  $pwNever = @()
  $comp = [ADSI]"WinNT://$env:COMPUTERNAME"
  foreach ($child in $comp.Children) {
    if ($child.SchemaClassName -eq 'User') {
      try {
        $flags = $child.Get("UserFlags")
        if ($flags -band 0x10000) { $pwNever += $child.Name }
      } catch {}
    }
  }
  if ($pwNever.Count -eq 0) { Write-Output "  (none detected)" }
  else { $pwNever | ForEach-Object { Write-Output ("  {0}" -f $_) } }
} catch { Write-Output "  (ADSI check failed: $_)" }
Write-HR

# ---------- Empty password allowed (best-effort) ----------
Write-Output "Accounts with empty password allowed (best-effort)"
try {
  $emptyAllowed = @()
  foreach ($u in ($users | Where-Object { $_ })) {
    $detail = net user $u 2>$null
    if ($detail -and ($detail -match 'Password required\s+No')) { $emptyAllowed += $u }
  }
  if ($emptyAllowed.Count -eq 0) { Write-Output "  (none detected)" }
  else { $emptyAllowed | ForEach-Object { Write-Output ("  {0}" -f $_) } }
} catch { Write-Output "  (error: $_)" }
Write-HR

# ---------- PATH directories writable by Users/Everyone ----------
Write-Output "PATH directories writable by Everyone (risk)"
try {
  $paths = $env:Path -split ';' | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
  $risky = @()
  foreach ($p in $paths) {
    try {
      $acl = Get-Acl -Path $p -ErrorAction Stop
      foreach ($ace in $acl.Access) {
        $id = $ace.IdentityReference.Value
        $perm = $ace.FileSystemRights
        if ($id -match 'Everyone' -or $id -match 'BUILTIN\\Users') {
          if ($perm.ToString() -match 'Write|Modify|FullControl') {
            $risky += [pscustomobject]@{ Path=$p; Identity=$id; Rights=$perm }
          }
        }
      }
    } catch {}
  }
  if ($risky.Count -eq 0) { Write-Output "  (none detected)" }
  else {
    foreach ($r in $risky) {
      Write-Output ("  {0,-50} {1,-30} {2}" -f $r.Path, $r.Identity, $r.Rights)
    }
  }
} catch { Write-Output "  (error enumerating PATH ACLs: $_)" }
Write-HR

# ---------- Key folder writable checks ----------
Write-Output "Sample key folder writable checks (Program Files, Windows, Users public)"
$checkDirs = @(
  "$env:ProgramFiles",
  "$env:ProgramFiles(x86)",
  "$env:windir",
  "$env:windir\System32",
  "$env:PUBLIC"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique

foreach ($d in $checkDirs) {
  try {
    $acl = Get-Acl -Path $d -ErrorAction Stop
    $unsafe = $false
    foreach ($ace in $acl.Access) {
      $id = $ace.IdentityReference.Value
      $perm = $ace.FileSystemRights
      if ($id -match 'Everyone' -or $id -match 'BUILTIN\\Users') {
        if ($perm.ToString() -match 'Write|Modify|FullControl') { $unsafe = $true; break }
      }
    }
    $flag = if ($unsafe) { 'YES' } else { 'NO' }
    Write-Output ("  {0,-40}  WritableByUsers: {1}" -f $d, $flag)
  } catch {
    Write-Output ("  {0,-40}  (error checking ACL)" -f $d)
  }
}
Write-HR

# ---------- Summary ----------
Write-Output "Summary"
Write-Output "  - Review Administrator / privileged group membership."
Write-Output "  - Disable unused accounts; enforce password expiry."
Write-Output "  - Remove 'Password never expires' where not required."
Write-Output "  - Fix PATH / Program Files directory ACLs that allow Users/Everyone write access."
Write-Output "  - Minimize accounts in Remote Desktop / Administrators groups."