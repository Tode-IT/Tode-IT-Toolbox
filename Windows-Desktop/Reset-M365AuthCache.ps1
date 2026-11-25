<#
.SYNOPSIS
    Clears cached Microsoft 365 authentication tokens, licensing cache, and Office identity keys.
.DESCRIPTION
    Resolves "Another account from your organization is already signed in on this device"
    and stubborn M365 activation loops without reinstalling Office.
.NOTES
    IMPORTANT: Must be run in a standard PowerShell window inside the AFFECTED USER's session.
    Do NOT run as SYSTEM (RMM background terminal) or under a separate local admin profile.
#>

Write-Host "Closing Microsoft 365 applications..." -ForegroundColor Cyan
$processes = @(
    'WINWORD', 'EXCEL', 'POWERPNT', 'OUTLOOK', 'olk',
    'ONENOTE', 'ms-teams', 'Teams', 'OneDrive'
)
Get-Process -Name $processes -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "Clearing OneAuth, IdentityCache, and Office licensing caches..." -ForegroundColor Cyan
$pathsToRemove = @(
    "$env:LOCALAPPDATA\Microsoft\OneAuth",
    "$env:LOCALAPPDATA\Microsoft\IdentityCache",
    "$env:LOCALAPPDATA\Microsoft\Office\16.0\Licensing",
    "$env:LOCALAPPDATA\Microsoft\Office\Licenses",
    "HKCU:\Software\Microsoft\Office\16.0\Common\Identity"
)

foreach ($path in $pathsToRemove) {
    if (Test-Path $path) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "Removed: $path" -ForegroundColor Green
    }
}

Write-Host "`nDone. Check Credential Manager and Settings > Accounts > Access work or school if issues persist, then reopen an Office app to sign in." -ForegroundColor Yellow
