<#
User & Group Account Audit (Windows) — DISPLAY + PIPELINE SAFE
- Enumerates local users and key properties
- Flags risky settings (password never expires / not required)
- Reports on privileged groups
#>

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

# --- Local users overview ---
Write-Output "=== Local Users (Get-LocalUser) ==="
try {
    $users = Get-LocalUser | Sort-Object Name
    if ($users) {
        $users |
          Select-Object Name, Enabled, Description, PasswordRequired, PasswordExpires, AccountExpires, LastLogon |
          Show-Table
    } else {
        Write-Output "No local users found."
    }
} catch {
    Write-Output ("ERROR: {0}" -f $_)
}
Write-Output ""

# --- Risky settings ---
Write-Output "=== Potential Risk Flags ==="
try {
    $neverExpires = $users | Where-Object { $_.PasswordExpires -eq $false }
    $noPassword   = $users | Where-Object { $_.PasswordRequired -eq $false }

    if ($neverExpires) {
        Write-Output "Accounts with 'Password never expires':"
        $neverExpires | Select-Object Name, Enabled, PasswordExpires | Show-Table
    } else {
        Write-Output "No accounts with 'Password never expires'."
    }

    if ($noPassword) {
        Write-Output "`nAccounts with 'Password not required':"
        $noPassword | Select-Object Name, Enabled, PasswordRequired | Show-Table
    } else {
        Write-Output "No accounts with 'Password not required'."
    }
} catch {
    Write-Output ("ERROR: {0}" -f $_)
}
Write-Output ""

# --- Built-in Administrator ---
Write-Output "=== Built-in Administrator Account ==="
try {
    $adminAccount = $users | Where-Object { $_.Name -eq "Administrator" }
    if ($adminAccount) {
        $adminAccount | Select-Object Name, Enabled, Description | Show-Table
    } else {
        Write-Output "Built-in Administrator not found (may be renamed or localized)."
    }
} catch {
    Write-Output ("ERROR: {0}" -f $_)
}
Write-Output ""

# --- Privileged groups ---
function Show-GroupMembers {
    param([string]$GroupName)
    try {
        $members = Get-LocalGroupMember -Group $GroupName -ErrorAction Stop
        Write-Output "Group: $GroupName"
        if ($members) {
            $members | Select-Object Name, ObjectClass, PrincipalSource | Show-Table
        } else {
            Write-Output "  (no members)"
        }
    } catch {
        Write-Output "  Group not found or inaccessible: $GroupName"
    }
    Write-Output ""
}

Write-Output "=== Privileged Groups ==="
Show-GroupMembers "Administrators"
Show-GroupMembers "Remote Desktop Users"
Show-GroupMembers "Guests"
Show-GroupMembers "Users"
Show-GroupMembers "Backup Operators"
Show-GroupMembers "Power Users"
Show-GroupMembers "Hyper-V Administrators"

# --- Per-user password metadata ---
Write-Output "=== Per-User Password Metadata (via 'net user') ==="
foreach ($u in $users) {
    try {
        $info = net user $u.Name 2>$null
        if ($LASTEXITCODE -eq 0 -and $info) {
            Write-Output "User: $($u.Name)"
            ($info | Select-String "Password last set") -replace ".*:","" | ForEach-Object { Write-Output "  Password last set : $($_.Trim())" }
            ($info | Select-String "Password expires") -replace ".*:","" | ForEach-Object { Write-Output "  Password expires  : $($_.Trim())" }
            ($info | Select-String "Password required") -replace ".*:","" | ForEach-Object { Write-Output "  Password required : $($_.Trim())" }
            ($info | Select-String "User may change password") -replace ".*:","" | ForEach-Object { Write-Output "  User may change  : $($_.Trim())" }
            Write-Output ""
        }
    } catch {
        Write-Output "WARN: Could not parse 'net user' for $($u.Name)"
    }
}

Write-Output "Summary:"
Write-Output "  - Enumerated local users & key properties"
Write-Output "  - Flagged risky password settings"
Write-Output "  - Reported built-in Administrator state"
Write-Output "  - Listed privileged groups and memberships"
Write-Output "  - Collected password metadata via 'net user'"
Write-Output ""