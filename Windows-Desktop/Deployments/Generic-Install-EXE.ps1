<#
.SYNOPSIS
    Universal EXE Installer Script.
.DESCRIPTION
    Silently installs any .exe package located in the target directory.
#>

$InstallerFolder = "C:\Installers"

# Change this switch depending on what the software vendor requires for silent mode
$SilentArgs = "/S" 

# Find the first .exe file in the folder
$ExeFile = Get-ChildItem -Path $InstallerFolder -Filter "*.exe" | Select-Object -First 1

if ($ExeFile) {
    Write-Host "Target Directory: $InstallerFolder"
    Write-Host "Found EXE installer: $($ExeFile.Name)"
    Write-Host "Running installation with switches: $SilentArgs"
    
    $Process = Start-Process -FilePath $($ExeFile.FullName) -ArgumentList $SilentArgs -Wait -NoNewWindow -PassThru
    Write-Host "Execution finished with Exit Code: $($Process.ExitCode)"
} else {
    Write-Error "No .exe file found in target directory: $InstallerFolder"
}
