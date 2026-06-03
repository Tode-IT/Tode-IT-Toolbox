<#
.SYNOPSIS
    Universal MSI Installer Script.
.DESCRIPTION
    Silently installs any .msi package located in the target directory.
#>

$InstallerFolder = "C:\Installers"

# Find the first .msi file in the folder
$MsiFile = Get-ChildItem -Path $InstallerFolder -Filter "*.msi" | Select-Object -First 1

if ($MsiFile) {
    Write-Host "Target Directory: $InstallerFolder"
    Write-Host "Found MSI installer: $($MsiFile.Name)"
    
    # Standard Microsoft silent parameters
    $Arguments = @('/i', "`"$($MsiFile.FullName)`"", '/qn', '/norestart')
    
    $Process = Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -NoNewWindow -PassThru
    Write-Host "Execution finished with Exit Code: $($Process.ExitCode)"
} else {
    Write-Error "No .msi file found in target directory: $InstallerFolder"
}
