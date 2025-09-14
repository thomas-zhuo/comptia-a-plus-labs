<#
.SYNOPSIS
  Event Log Collector (Windows) — display only

.DESCRIPTION
  Retrieves recent Application and System logs.
  Displays Errors and Warnings for troubleshooting.
#>

Write-Host "Event Log Collector Report" -ForegroundColor Cyan
Write-Host "Host : $env:COMPUTERNAME"
Write-Host "OS   : $([System.Environment]::OSVersion.VersionString)"
Write-Host "Date : $(Get-Date)"
function Section { param($t); Write-Host "`n==== $t ====" -ForegroundColor Yellow }

# ----- Application Log -----
Section "Application Log (last 20)"
Get-EventLog -LogName Application -Newest 20 |
  Select-Object TimeGenerated, EntryType, Source, EventID, Message

# ----- System Log -----
Section "System Log (last 20)"
Get-EventLog -LogName System -Newest 20 |
  Select-Object TimeGenerated, EntryType, Source, EventID, Message

# ----- Filtered Errors/Warnings -----
Section "Errors and Warnings (Application & System)"
Get-EventLog -LogName Application -Newest 50 -EntryType Error,Warning |
  Select-Object TimeGenerated, EntryType, Source, EventID, Message
Get-EventLog -LogName System -Newest 50 -EntryType Error,Warning |
  Select-Object TimeGenerated, EntryType, Source, EventID, Message

Write-Host "`nEvent log collection complete." -ForegroundColor Green
