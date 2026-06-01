@echo off
echo ===================================================
echo             Checking Server Boot Time             
echo ===================================================
echo.
net statistics server | find "Statistics since"
echo.
echo Complete! Press any key to exit.
pause >nul
