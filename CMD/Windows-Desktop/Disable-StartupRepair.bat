@echo off
echo ===================================================
echo       Disabling Windows Start-Up Repair
echo ===================================================
echo.
echo NOTE: Must be run as Administrator!
echo.
bcdedit /set {default} recoveryenabled No
bcdedit /set {default} bootstatuspolicy ignoreallfailures
bcdedit /timeout 10
echo.
echo Complete! Press any key to exit.
pause >nul
