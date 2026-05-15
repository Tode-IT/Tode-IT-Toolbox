<#
.SYNOPSIS
Restarts the Print Spooler service on a local machine. Useful for clearing stuck print jobs.
#>

Restart-Service -Name Spooler -Force -Verbose
