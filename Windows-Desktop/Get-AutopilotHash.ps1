# ==============================================================================
# Script: Get-AutopilotHash.ps1
# Description: Extracts the hardware hash for Windows Autopilot enrollment.
# Run on: Client device as Administrator.
# ==============================================================================

# 1. Ensure TLS 1.2 is enabled (often required to reach the PowerShell Gallery)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 2. Set execution policy to allow the script to run
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force

# 3. Install the official Microsoft Autopilot extraction script
Install-Script -Name Get-WindowsAutopilotInfo -Force

# 4. Run the script and output the hash to a CSV on the C: drive
Get-WindowsAutopilotInfo -OutputFile C:\AutopilotHash.csv
