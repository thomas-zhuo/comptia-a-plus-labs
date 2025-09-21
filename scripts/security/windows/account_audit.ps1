<#
User & Group Account Audit (Windows) — DISPLAY + PIPELINE SAFE
- Enumerates local users, key properties, and privileged group memberships
- Highlights Administrators membership and risky settings (password never expires, password not required)
- Uses Write-Output so you can pipe to Out-File or Tee-Object
#>

# ----- Helpers --------------------------------------------------------------
function Show-Table {
    param([Parameter(ValueFromPipeline=$true)] $InputObject)
    $sb = [System.Text.StringBuilder]::new()
    ($InputObject | Format-Table -AutoSize | Out-String) -split "`r?`n" | ForEach-Object {
        [void]$sb.AppendLine($_)
    }
    Write-Output ($sb.ToString().TrimEnd())
}

$os = (Get-CimInstance Win32_OperatingSystem).Caption
$dt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'

Write-Output ""
Write-Output "User & Group Account Audit (Windows)"
Write-Output ("Host : {0}" -f $env:COMPUTERNAME)
Write-Output ("OS   : {0}" -f $os)
Write-Output ("Date : {0}" -f $dt)
Write-Output ""

# ----- Local users (overview) ----------------------------------------------
Write-Output "=== Local Users (Get-LocalUser) ==="
try {
    $users = Get-LocalUser | Sort-Object Name
    if (-not $users) { Write-Output "No local users found."; }
    else {
        $users |
            Select-Object Name, Enabled, Description, PasswordRequired, PasswordExpires, AccountExpires, LastLogon |
            Show-Table
    }
} catch {
    Write-Output ("ERROR: Failed to enumerate local users: {0}" -f $_)
}
Write-Output ""

# ----- Flag: password never expires / not required -------------------------
Write-Output "=== Potential Risk Flags (Local Accounts) ==="
try {
    $neverExpires = $users | Where-Object { $_.PasswordExpires -eq $false }
    $noPassword   = $users | Where-Object { $_.PasswordRequired -eq $false }

    if ($neverExpires) {
        Write-Output "Accounts with 'Password never expires':"
        $neverExpires | Select-Object Name, Enabled, PasswordExpires | Show-Table
    } else {
        Write-Output "No accounts with 'Password never expires' found."
    }

    Write-Output ""

    if ($noPassword) {
        Write-Output "Accounts with 'Password not required':"
        $noPassword | Select-Object Name, Enabled, PasswordRequired | Show-Table
    } else {
        Write-Output "No accounts with 'Password not required' found."
    }
} catch {
    Write-Output ("ERROR: Flag analysis failed: {0}" -f $_)
}
Write-Output ""

# ----- Built-in Administrator account state --------------------------------
Write-Output "=== Built-in Administrator Account ==="
try {
    $adminBuiltIn = $users | Where-Object { $_.Name -match '^(Administrator|BUILTIN\\Administrator)$' }
    if ($adminBuiltIn) {
        $adminBuiltIn | Select-Object Name, Enabled, Description | Show-Table
    } else {
        Write-Output "Built-in Administrator account not present or localized under a different name."
    }
} catch {
    Write-Output ("ERROR: Checking built-in Administrator failed: {0}" -f $_)
}
Write-Output ""

# ----- Privileged groups & memberships -------------------------------------
function Show-GroupMembers {
    param([string]$GroupName)
    try {
        $members = Get-LocalGroupMember -Group $GroupName -ErrorAction Stop
        if ($members) {
            Write-Output ("Group: {0}" -f $GroupName)
            $members |
                Select-Object Name, ObjectClass, PrincipalSource |
                Show-Table
        } else {
            Write-Output ("Group: {0} (no members)" -f $GroupName)
        }
    } catch {
        Write-Output ("Group: {0} (not found or inaccessible)" -f $GroupName)
    }
    Write-Output ""
}

Write-Output "=== Privileged Local Groups (Members) ==="
Show-GroupMembers -GroupName 'Administrators'
Show-GroupMembers -GroupName 'Remote Desktop Users'
Show-GroupMembers -GroupName 'Users'
Show-GroupMembers -GroupName 'Guests'
Show-GroupMembers -GroupName 'Backup Operators'
Show-GroupMembers -GroupName 'Power Users'        # legacy, may not exist
Show-GroupMembers -GroupName 'Hyper-V Administrators' # if applicable

# ----- Optional: per-user password metadata (best effort) -------------------
# Uses 'net user' to fetch human-readable last set/expire data for local SAM users.
Write-Output "=== Per-User Password Metadata (best effort via 'net user') ==="
try {
    foreach ($u in $users) {
        $info = (net user $u.Name) 2>$null
        if ($LASTEXITCODE -eq 0 -and $info) {
            # Extract common fields; formatting localized per OS language.
            $pwLastSet   = ($info | Select-String -Pattern 'Password last set|Last password set' -SimpleMatch | ForEach-Object { $_.ToString().Split(':',2)[1].Trim() }) -join ', '
            $pwExpires   = ($info | Select-String -Pattern 'Password expires' -SimpleMatch | ForEach-Object { $_.ToString().Split(':',2)[1].Trim() }) -join ', '
            $pwRequired  = ($info | Select-String -Pattern 'Password required' -SimpleMatch | ForEach-Object { $_.ToString().Split(':',2)[1].Trim() }) -join ', '
            $userMayChg  = ($info | Select-String -Pattern 'User may change password' -SimpleMatch | ForEach-Object { $_.ToString().Split(':',2)[1].Trim() }) -join ', '

            Write-Output ("User: {0}" -f $u.Name)
            Write-Output ("  Password last set      : {0}" -f ($pwLastSet   -ne '' ? $pwLastSet   : 'unknown'))
            Write-Output ("  Password expires       : {0}" -f ($pwExpires   -ne '' ? $pwExpires   : 'unknown'))
            Write-Output ("  Password required      : {0}" -f ($pwRequired  -ne '' ? $pwRequired  : 'unknown'))
            Write-Output ("  User may change pwd    : {0}" -f ($userMayChg  -ne '' ? $userMayChg  : 'unknown'))
            Write-Output ""
        }
    }
} catch {
    Write-Output ("WARN: 'net user' metadata collection failed: {0}" -f $_)
}
Write-Output ""

# ----- Summary --------------------------------------------------------------
Write-Output "Summary:"
Write-Output "  - Listed local users with key properties (enabled, expires, last logon)."
Write-Output "  - Highlighted risky settings (password never expires / not required)."
Write-Output "  - Reported Built-in Administrator status."
Write-Output "  - Enumerated privileged groups (Administrators, RDP, etc.) and members."
Write-Output "  - Included best-effort per-user password metadata using 'net user'."
Write-Output ""