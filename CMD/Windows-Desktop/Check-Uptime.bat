@echo off
echo ===================================================
echo             Checking Desktop Boot Time             
echo ===================================================
echo.
systeminfo | find "System Boot Time"
echo.
echo Complete! Press any key to exit.
pause >nul
