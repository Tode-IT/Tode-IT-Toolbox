@echo off
set "InstallerFolder=C:\Installers"

echo Target Directory: %InstallerFolder%
echo Checking for MSI installer...

if exist "%InstallerFolder%\*.msi" (
    for %%f in ("%InstallerFolder%\*.msi") do (
        echo Found MSI installer: %%~nxf
        echo Running silent installation...
        
        start /wait msiexec.exe /i "%%f" /qn /norestart
        
        goto end
    )
) else (
    echo Error: No .msi file found in %InstallerFolder%.
)

:end
echo Process completed.
