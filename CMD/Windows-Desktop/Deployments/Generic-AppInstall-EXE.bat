@echo off
set "InstallerFolder=C:\Installers"

# Change this switch depending on what the software vendor requires for silent mode
set "SilentArgs=/S"

echo Target Directory: %InstallerFolder%
echo Checking for EXE installer...

if exist "%InstallerFolder%\*.exe" (
    for %%f in ("%InstallerFolder%\*.exe") do (
        echo Found EXE installer: %%~nxf
        echo Running installation with switches: %SilentArgs%
        
        start /wait "" "%%f" %SilentArgs%
        
        goto end
    )
) else (
    echo Error: No .exe file found in %InstallerFolder%.
)

:end
echo Process completed.
