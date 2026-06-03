<#
.SYNOPSIS
    Universal EXE Installer Script.
.DESCRIPTION
    Finds and installs an .exe package. Adjust the $SilentArgs variable based on the vendor.
#>

$InstallerFolder = "C:\Installers"

# COMMON VENDOR SWITCHES FOR YOUR REFERENCE:
# Nullsoft (VLC): "/S" (Capital S)
# Inno Setup: "/VERYSILENT /SUPPRESSMSGBOXES /NORESTART"
# InstallShield: "/s /v`"/qn`"

$SilentArgs = "/S" 

# Find any .exe file in the folder
$ExeFile = Get-ChildItem -Path $InstallerFolder -Filter "*.exe" | Select-Object -First 1

if ($ExeFile) {
    Write-Host "Found EXE installer: $($ExeFile.Name)."
    Write-Host "Running installation with switches: $SilentArgs"
    
    $Process = Start-Process -FilePath $($ExeFile.FullName) -ArgumentList $SilentArgs -Wait -NoNewWindow -PassThru
    Write-Host "Execution finished with Exit Code: $($Process.ExitCode)"
} else {
    Write-Error "No .exe file found in $InstallerFolder."
}
