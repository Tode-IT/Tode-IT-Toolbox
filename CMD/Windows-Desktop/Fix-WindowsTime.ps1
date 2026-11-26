<#
.SYNOPSIS
    Fixes Windows Time service (w32time) sync issues silently as SYSTEM.
.DESCRIPTION
    Sets w32time to Automatic, restarts the service, forces an NTP resync,
    and outputs before/after time and sync status for ticket verification.
.EXAMPLE
    Quick one-liner for NinjaOne PowerShell terminal (most fixes):

    Set-Service -Name w32time -StartupType Automatic; Restart-Service -Name w32time; w32tm /resync /force; w32tm /query /status; Get-Date
#>

Write-Host "=== BEFORE ===" -ForegroundColor Cyan
Get-Date
(Get-TimeZone).Id
w32tm /query /status

# Uncomment to enforce UK timezone (handles GMT/BST automatically)
# Set-TimeZone -Id "GMT Standard Time"

Write-Host "`n=== REPAIRING W32TIME ===" -ForegroundColor Cyan
Set-Service -Name w32time -StartupType Automatic
Restart-Service -Name w32time

# Attempt standard resync first
$resync = w32tm /resync /force 2>&1
Write-Output $resync

# Fallback: if resync fails or source is stuck on Local CMOS Clock, switch to Microsoft NTP
$source = (w32tm /query /source 2>&1) -join ""
if ($LASTEXITCODE -ne 0 -or $source -match "Local CMOS Clock|Free-running") {
    Write-Host "`nSwitching to public NTP (time.windows.com)..." -ForegroundColor Yellow
    w32tm /config /manualpeerlist:"time.windows.com,0x8" /syncfromflags:manual /reliable:YES /update
    Restart-Service -Name w32time
    w32tm /resync /force
}

Write-Host "`n=== AFTER ===" -ForegroundColor Green
Get-Date
w32tm /query /status
