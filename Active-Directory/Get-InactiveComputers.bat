@echo off
echo ===================================================
echo     Checking for Inactive Computers in Domain      
echo ===================================================
echo.
set /p WEEKS="Enter number of weeks inactive (e.g. 4): "

dsquery computer forestroot -inactive %WEEKS%

echo.
pause
