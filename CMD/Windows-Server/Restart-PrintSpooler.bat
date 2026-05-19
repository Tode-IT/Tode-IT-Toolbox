@echo off
echo Restarting Print Spooler Service...
net stop spooler
net start spooler
echo Spooler service successfully recycled.
