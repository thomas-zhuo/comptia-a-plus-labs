<#
./scripts/security/windows/perm_hardening.ps1
User / Group Permission Hardening Check — Windows (PowerShell 5.1 compatible)

- Display-only (use Tee-Object / Out-File to save)
- Uses net user / net localgroup and ADSI for broad compatibility
- Prints:
  - Local users and basic properties
  - Accounts with Administrator/Remote Desktop membership
  - Disabled accounts and password/expiration hints
  - Accounts with PasswordNeverExpires (best-effort)
  - PATH entries that are writable by Everyone (risk)
  - Summary & remediation hints
#>

param(
  [switch]$VerboseMode
)
if ($VerboseMode) { $VerbosePreference = 'Continue'; $DebugPreference = 'Continue' }
$ErrorActionPreference = 'Continue'

function Write-HR {
  $w = 80
  try { $w = (Get-Host).UI.RawUI.WindowSize.Width } catch {}
  Write-Output ('-' * $w)
}

function Safe-Command {
  param($ScriptBlock)
  try {
    & $ScriptBlock
  } catch {
    Write-Output "(error: $_)"
  }
}

# Header
$computer = $env:COMPUTERNAME
$osObj = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
$osCaption = if ($osObj -and $osObj.Caption) { $osObj.Caption } else { 'Windows' }
Write-Output "User & Permission Hardening Audit"
Write-Output ("  Host : {0}" -f $computer)
Write-Output ("  OS   : {0}" -f $osCaption)
Write-Output ("  Date : {0}" -f (Get-Date))
Write-HR

# Section: Local users (net user)
Write-Output "Local users (summary via 'net user')"
try {
  $usersRaw = net user 2>&1
  # net user prints a header then the user list on one or more lines; parse them
  $start = ($usersRaw | Select-String -Pattern '---' -SimpleMatch).LineNumber
  if (-not $start) { $start = 1 }
  # attempt to find the 'The command completed successfully.' line and slice between
  $lines = $usersRaw | Where-Object { $_ -and ($_ -notmatch 'The command completed successfully.') }
  # net user output varies by locale; fallback: take lines after header words "User accounts"
  $users = @()
  foreach ($line in $lines) {
    # break into names by whitespace columns
    $parts = $line -split '\s+' | Where-Object { $_ -ne '' }
    foreach ($p in $parts) { if ($p -and ($p -ne 'User' -and $p -ne 'accounts' -and $p -ne 'for' -and $p -ne $computer)) { $users += $p } }
  }
  $users = $users | Select-Object -Unique
  if (-not $users -or $users.Count -eq 0) {
    Write-Output "  (no local users found via net user)"
  } else {
    foreach ($u in $users) {
      # get net user details for each user
      $detail = net user $u 2>$null
      if ($detail) {
        # extract relevant fields (Password required, Password expires, Account active, Last set)
        $pwdReq = ($detail | Select-String -Pattern 'Password required' -SimpleMatch).ToString() -replace 'Password required\s+',''
        $pwdExpires = ($detail | Select-String -Pattern 'Password expires' -SimpleMatch).ToString() -replace 'Password expires\s+',''
        $acctActive = ($detail | Select-String -Pattern 'Account active' -SimpleMatch).ToString() -replace 'Account active\s+',''
        $lastSet = ($detail | Select-String -Pattern 'Password last set' -SimpleMatch).ToString() -replace 'Password last set\s+',''
        # fallback: if strings blank, set '-'
        $pwdReq = if ($pwdReq) { $pwdReq.Trim() } else { '-' }
        $pwdExpires = if ($pwdExpires) { $pwdExpires.Trim() } else { '-' }
        $acctActive = if ($acctActive) { $acctActive.Trim() } else { '-' }
        $lastSet = if ($lastSet) { $lastSet.Trim() } else { '-' }
        Write-Output ("  {0,-20}  Active: {1,-6}  PwdReq: {2,-6}  PwdExpires: {3,-20}  PwdLastSet: {4}" -f $u, $acctActive, $pwdReq, $pwdExpires, $lastSet)
      } else {
        Write-Output ("  {0,-20}  (no detail available)" -f $u)
      }
    }
  }
} catch {
  Write-Output "  (error enumerating users: $_)"
}
Write-HR

# Section: Disabled accounts
Write-Output "Disabled accounts (best-effort via net user / ADSI)"
try {
  $disabled = @()
  foreach ($u in ($users | Where-Object { $_ })) {
    $detail = net user $u 2>$null
    if ($detail -and ($detail -match 'Account active\s+No')) {
      $disabled += $u
    }
  }
  if ($disabled.Count -eq 0) {
    Write-Output "  (none detected)"
  } else {
    foreach ($d in $disabled) { Write-Output ("  {0}" -f $d) }
  }
} catch {
  Write-Output "  (error checking disabled accounts: $_)"
}
Write-HR

# Section: Administrator & Remote Desktop group membership
Write-Output "Admin / Privileged group membership"
$groupsToCheck = @('Administrators','Remote Desktop Users','Remote Desktop','Power Users')
foreach ($g in $groupsToCheck) {
  try {
    $members = net localgroup "$g" 2>$null
    if ($members) {
      # parse lines that look like member names (skip header/footer lines)
      $memberLines = $members | Where-Object { ($_ -and $_ -notmatch '^-|^The command completed successfully|^Alias name|^Comment|^Members') }
      $collected = @()
      foreach ($ml in $memberLines) {
        $line = $ml.Trim()
        if ($line -ne '') {
          # sometimes the output has empty lines and continuation; split by multiple spaces
          $parts = $line -split '\s{2,}' | Where-Object { $_ -ne '' }
          foreach ($p in $parts) { if ($p -and $p -notmatch '^\*') { $collected += $p.Trim() } }
        }
      }
      $collected = $collected | Select-Object -Unique
      Write-Output ("  {0,-22} -> {1}" -f $g, (if ($collected) { ($collected -join ', ') } else { '(none)'}))
    } else {
      Write-Output ("  {0,-22} -> (not present / cannot enumerate on this host)" -f $g)
    }
  } catch {
    Write-Output ("  {0,-22} -> (error: $_)" -f $g)
  }
}
Write-HR

# Section: Accounts with PasswordNeverExpires (ADSI best-effort)
Write-Output "Accounts with PasswordNeverExpires (best-effort)"
try {
  $pwNever = @()
  # use ADSI to query local users
  $comp = [ADSI]"WinNT://$env:COMPUTERNAME"
  foreach ($child in $comp.Children) {
    if ($child.SchemaClassName -eq 'User') {
      try {
        $flags = $child.Get("UserFlags")
        # PASSWD_CANT_CHANGE = 0x40, DONT_EXPIRE_PASSWORD = 0x10000 (65536)
        if ($flags -band 0x10000) { $pwNever += $child.Name }
      } catch {}
    }
  }
  if ($pwNever.Count -eq 0) {
    Write-Output "  (none detected)"
  } else {
    foreach ($n in $pwNever) { Write-Output ("  {0}" -f $n) }
  }
} catch {
  Write-Output "  (ADSI check failed: $_)"
}
Write-HR

# Section: Users with empty password? (best-effort)
Write-Output "Accounts with empty password allowed (best-effort)"
try {
  $emptyAllowed = @()
  foreach ($u in ($users | Where-Object { $_ })) {
    $detail = net user $u 2>$null
    if ($detail -and ($detail -match 'Password required\s+No')) {
      $emptyAllowed += $u
    }
  }
  if ($emptyAllowed.Count -eq 0) { Write-Output "  (none detected)" }
  else { foreach ($e in $emptyAllowed) { Write-Output ("  {0}" -f $e) } }
} catch {
  Write-Output "  (error detecting empty-password accounts: $_)"
}
Write-HR

# Section: PATH directories that are writable by Everyone (risk)
Write-Output "PATH directories writable by Everyone (risk)"
try {
  $paths = $env:Path -split ';' | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
  $risky = @()
  foreach ($p in $paths) {
    try {
      $acl = Get-Acl -Path $p -ErrorAction Stop
      foreach ($ace in $acl.Access) {
        # check if 'Everyone' or 'BUILTIN\Users' has Write or FullControl
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
  else { $risky | Select-Object Path,Identity,Rights | ForEach-Object { Write-Output ("  {0,-50} {1,-30} {2}" -f $_.Path,$_.Identity,$_.Rights) } }
} catch {
  Write-Output "  (error enumerating PATH ACLs: $_)"
}
Write-HR

# Section: Sample SDDL / key folder checks (optional quick checks)
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
    Write-Output ("  {0,-40}  WritableByUsers: {1}" -f $d, ($unsafe ? 'YES' : 'NO'))
  } catch {
    Write-Output ("  {0,-40}  (error checking ACL)" -f $d)
  }
}
Write-HR

# Summary
Write-Output "Summary"
Write-Output "  - Review Administrator / privileged group membership."
Write-Output "  - Disable unused accounts; enforce password expiry."
Write-Output "  - Remove 'Password never expires' where not required."
Write-Output "  - Fix PATH / Program Files directory ACLs that allow Users/Everyone write access."
Write-Output "  - Minimize accounts in Remote Desktop / Administrators groups."

# End