@echo off
echo ===================================================
echo     Remote Profile Cleanup (Delprof2)
echo ===================================================
echo.
echo NOTE: Delprof2.exe must be located in the same folder or in your system path!
echo.
set /p TARGET_SERVER="Enter Target Server Name (e.g. S00204-RDSH01): "
set /p INACTIVE_DAYS="Enter number of days inactive (e.g. 30): "

echo.
echo Running cleanup on %TARGET_SERVER% for profiles older than %INACTIVE_DAYS% days...
echo (Excluding 'Admin*' profiles)
echo.

Delprof2.exe /ed:Admin* /c:%TARGET_SERVER% /d:%INACTIVE_DAYS%

echo.
echo Complete! Press any key to exit.
pause >nul
