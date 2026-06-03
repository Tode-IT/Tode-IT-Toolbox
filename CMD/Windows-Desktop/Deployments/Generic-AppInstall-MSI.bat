@echo off
set "InstallerFolder=C:\Installers"
echo Checking for MSI installer...

if exist "%InstallerFolder%\*.msi" (
    for %%f in ("%InstallerFolder%\*.msi") do (
        echo Installing %%~nxf silently...
        start /wait msiexec.exe /i "%%f" /qn /norestart
        goto end
    )
) else (
    echo Error: No .msi file found in %InstallerFolder%.
)

:end
echo Process completed.
