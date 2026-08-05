<#
.SYNOPSIS
    Diagnostics script to investigate unexpected screen locking and timeouts.
    
.DESCRIPTION
    Checks all known locations that can enforce a screen lock or display timeout:
    1. Intune / MDM Configuration Profiles
    2. Intune Compliance Policies (Hidden Exchange ActiveSync / EAS keys)
    3. Local Security Policy / Machine GPOs
    4. Active Power Plan settings (Translates Hex to Minutes)
    5. Machine-level and User-level Screensaver overrides
    
.NOTES
    Designed to be run silently via RMM (NinjaOne, ScreenConnect) as SYSTEM.
#>

Write-Host "======================================================"
Write-Host " SCREEN LOCK & INACTIVITY DIAGNOSTIC TRACE "
Write-Host "======================================================"

# ---------------------------------------------------------
# 1. INTUNE / MDM / EAS POLICIES
# ---------------------------------------------------------
Write-Host "`n[1] CHECKING INTUNE & COMPLIANCE POLICIES (HKLM)..."

# MDM Device Lock
$mdmPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\DeviceLock"
if (Test-Path $mdmPath) {
    $mdmVal = Get-ItemProperty -Path $mdmPath -ErrorAction SilentlyContinue
    Write-Host "  - Intune MDM MaxInactivityTimeDeviceLock : $($mdmVal.MaxInactivityTimeDeviceLock) minutes"
} else {
    Write-Host "  - Intune MDM DeviceLock                  : Not Configured"
}

# EAS / Compliance Policy Lock (The hidden one)
$easPath = "HKLM:\SYSTEM\CurrentControlSet\Control\EAS\Policies"
if (Test-Path $easPath) {
    $easVal = Get-ItemProperty -Path $easPath -ErrorAction SilentlyContinue
    if ($easVal."7") {
        $easMins = [math]::Round($easVal."7" / 60, 2)
        Write-Host "  - Intune EAS/Compliance Inactivity Timer : $($easVal."7") seconds ($easMins minutes)"
    } else {
        Write-Host "  - Intune EAS/Compliance Inactivity Timer : Not Configured"
    }
} else {
    Write-Host "  - Intune EAS/Compliance Inactivity Timer : Not Configured"
}

# Local Security Policy
$secPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
if (Test-Path $secPath) {
    $secVal = Get-ItemProperty -Path $secPath -ErrorAction SilentlyContinue
    if ($secVal.InactivityTimeoutSecs) {
        $secMins = [math]::Round($secVal.InactivityTimeoutSecs / 60, 2)
        Write-Host "  - Local Security InactivityTimeoutSecs   : $($secVal.InactivityTimeoutSecs) seconds ($secMins minutes)"
    } else {
         Write-Host "  - Local Security InactivityTimeoutSecs   : Not Configured"
    }
}

# ---------------------------------------------------------
# 2. POWER & SLEEP TIMEOUTS
# ---------------------------------------------------------
Write-Host "`n[2] CHECKING ACTIVE POWER PLAN TIMEOUTS..."

function Get-PowerSetting ($SubGroup, $Setting, $ACDC) {
    $output = powercfg /q SCHEME_CURRENT $SubGroup $Setting | Select-String "Current $ACDC Power Setting Index"
    if ($output -match "0x([0-9a-fA-F]+)") {
        $seconds = [convert]::ToInt32($matches[1], 16)
        if ($seconds -eq 0) { return "0 (Never)" }
        $minutes = [math]::Round($seconds / 60, 2)
        return "$seconds seconds ($minutes minutes)"
    }
    return "Unknown"
}

Write-Host "  DISPLAY OFF:"
Write-Host "  - On AC (Plugged In) : $(Get-PowerSetting SUB_VIDEO VIDEOIDLE AC)"
Write-Host "  - On DC (Battery)    : $(Get-PowerSetting SUB_VIDEO VIDEOIDLE DC)"

Write-Host "  SLEEP:"
Write-Host "  - On AC (Plugged In) : $(Get-PowerSetting SUB_SLEEP STANDBYIDLE AC)"
Write-Host "  - On DC (Battery)    : $(Get-PowerSetting SUB_SLEEP STANDBYIDLE DC)"

# ---------------------------------------------------------
# 3. SCREENSAVER POLICIES
# ---------------------------------------------------------
Write-Host "`n[3] CHECKING SCREENSAVER SETTINGS..."

# Machine Level GPO
$machineGpoPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop"
if (Test-Path $machineGpoPath) {
    $mGpo = Get-ItemProperty -Path $machineGpoPath -ErrorAction SilentlyContinue
    Write-Host "  - Machine GPO ScreenSaveActive  : $($mGpo.ScreenSaveActive)"
    Write-Host "  - Machine GPO ScreenSaveTimeOut : $($mGpo.ScreenSaveTimeOut)"
} else {
    Write-Host "  - Machine GPO Overrides         : Not Configured"
}

# Logged-on User Level
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$loggedOnUser = $computerSystem.UserName

if ([string]::IsNullOrWhiteSpace($loggedOnUser)) {
    Write-Host "  - User Settings                 : No user currently logged in to check."
} else {
    Write-Host "  - User Logged In                : $loggedOnUser"
    
    # Translate User to SID to check HKU
    $ntAccount = New-Object System.Security.Principal.NTAccount($loggedOnUser)
    $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
    
    $userGPOPath = "Registry::HKEY_USERS\$sid\Software\Policies\Microsoft\Windows\Control Panel\Desktop"
    if (Test-Path $userGPOPath) {
        $uGpo = Get-ItemProperty -Path $userGPOPath -ErrorAction SilentlyContinue
        Write-Host "  - User GPO ScreenSaveTimeOut    : $($uGpo.ScreenSaveTimeOut)"
        Write-Host "  - User GPO ScreenSaverIsSecure  : $($uGpo.ScreenSaverIsSecure)"
    } else {
        Write-Host "  - User GPO Overrides            : Not Configured"
    }

    $userLocalPath = "Registry::HKEY_USERS\$sid\Control Panel\Desktop"
    if (Test-Path $userLocalPath) {
        $uLoc = Get-ItemProperty -Path $userLocalPath -ErrorAction SilentlyContinue
        Write-Host "  - User Local ScreenSaveTimeOut  : $($uLoc.ScreenSaveTimeOut)"
        Write-Host "  - User Local ScreenSaverIsSecure: $($uLoc.ScreenSaverIsSecure)"
    }
}

Write-Host "`n======================================================"
Write-Host " TRACE COMPLETE "
Write-Host "======================================================"
